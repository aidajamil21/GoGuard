import 'package:flutter_bloc/flutter_bloc.dart';
import 'transfer_event.dart';
import 'transfer_state.dart';
import '../../services/alibaba_api_service.dart';
import '../../services/risk_engine.dart';
import '../../models/risk_label.dart';

class TransferBloc extends Bloc<TransferEvent, TransferState> {
  final AlibabaApiService _api;
  String _userId = 'unknown';

  // Velocity tracking: timestamps of completed transfers in the last hour
  final List<DateTime> _recentTransferTimes = [];

  int get _currentVelocity {
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    _recentTransferTimes.removeWhere((t) => t.isBefore(cutoff));
    return _recentTransferTimes.length;
  }

  TransferBloc({AlibabaApiService? apiService})
      : _api = apiService ?? AlibabaApiService(),
        super(const TransferIdle()) {
    on<RecipientSubmitted>(_onRecipientSubmitted);
    on<RecipientCheckCancelled>(_onRecipientCheckCancelled);
    on<RecipientCheckConfirmed>(_onRecipientCheckConfirmed);
    on<AmountSubmitted>(_onAmountSubmitted);
    on<BehaviouralAnalysisStarted>(_onBehaviouralAnalysisStarted);
    on<WarningAcknowledged>(_onWarningAcknowledged);
    on<TransferConfirmed>(_onTransferConfirmed);
    on<TransferCancelled>(_onTransferCancelled);
    on<TransferRetried>(_onTransferRetried);
  }

  void setUserId(String userId) => _userId = userId;

  // ── Step 1: Recipient submitted ──────────────────────
  Future<void> _onRecipientSubmitted(
    RecipientSubmitted event,
    Emitter<TransferState> emit,
  ) async {
    final data = state.data.copyWith(
      recipientPhone: event.phone,
      recipientNickname: event.nickname,
    );

    // ── WHITELIST BYPASS: skip GNN check ─────────────
    if (event.isWhitelisted) {
      _userId = await _api.getCurrentUserId();
      emit(WhitelistedRecipientState(data.copyWith(
        isWhitelisted: true,
        gnnRiskScore: 0.0,
        riskLabel: RiskLabel.low,
        scamCheckId: 'whitelist_bypass',
        graphFeatures: {},
      )));
      return;
    }

    // ── Regular: call GNN ────────────────────────────
    emit(RecipientCheckingState(data));
    try {
      _userId = await _api.getCurrentUserId();
      final result = await _api.checkRecipient(
        phone: event.phone,
        userId: _userId,
      );

      final gnnScore = (result['gnn_risk_score'] as num).toDouble();
      final graphFeatures = Map<String, dynamic>.from(result['graph_features'] ?? {});
      final scamCheckId = result['scam_check_id'] as String? ?? 'chk_fallback';
      // XGBoost not run yet — use GNN score alone (pass it for both weights)
      final riskResult = RiskEngine.compute(gnnScore, gnnScore);

      emit(RecipientCheckedState(data.copyWith(
        gnnRiskScore: gnnScore,
        graphFeatures: graphFeatures,
        scamCheckId: scamCheckId,
        riskLabel: riskResult.riskLabel,
      )));
    } catch (e) {
      emit(TransferErrorState(data, errorType: ErrorType.networkTimeout, retryEvent: event));
    }
  }

  void _onRecipientCheckCancelled(
    RecipientCheckCancelled event,
    Emitter<TransferState> emit,
  ) {
    emit(const TransferIdle());
  }

  void _onRecipientCheckConfirmed(
    RecipientCheckConfirmed event,
    Emitter<TransferState> emit,
  ) {
    emit(AmountEntryState(state.data));
  }

  // ── Step 4: Amount submitted ─────────────────────────
  void _onAmountSubmitted(
    AmountSubmitted event,
    Emitter<TransferState> emit,
  ) {
    if (event.amount <= 0 || event.amount > event.balance) {
      emit(TransferErrorState(state.data, errorType: ErrorType.insufficientFunds));
      return;
    }
    final vel = _currentVelocity;
    emit(BehaviouralAnalysingState(state.data.copyWith(
      amount: event.amount,
      velocity: vel,
    )));
    add(BehaviouralAnalysisStarted());
  }

  // ── Step 5: XGBoost + LLM ────────────────────────────
  Future<void> _onBehaviouralAnalysisStarted(
    BehaviouralAnalysisStarted event,
    Emitter<TransferState> emit,
  ) async {
    final data = state.data;

    // Give AnalysingScreen time to mount and subscribe its BlocListener
    // before RiskFusedState is emitted (prevents race on web with instant mock).
    await Future.delayed(const Duration(milliseconds: 400));

    try {
      final result = await _api.getRiskScore(
        userId: _userId,
        phone: data.recipientPhone ?? '',
        amount: data.amount ?? 0,
        hourOfDay: DateTime.now().hour,
        isNewRecipient: !data.isWhitelisted,
        velocity: data.velocity,
      );

      final xgbScore = (result['xgb_risk_score'] as num).toDouble();
      final shapValues = Map<String, dynamic>.from(result['shap_values'] ?? {});

      // Whitelisted contacts: cap XGBoost contribution (GNN already 0)
      final effectiveXgb = data.isWhitelisted ? (xgbScore * 0.5) : xgbScore;
      final riskResult = RiskEngine.compute(data.gnnRiskScore ?? 0.0, effectiveXgb);

      final bullets = await _api.getLLMBullets(
        riskLabel: riskResult.riskLabel,
        graphFeatures: data.graphFeatures ?? {},
        shapValues: shapValues,
        amount: data.amount ?? 0,
        phone: data.recipientPhone ?? '',
      );

      // Velocity alert bullet injected if frequent small transfers detected
      final finalBullets = _injectVelocityBullet(bullets, data.velocity, data.amount ?? 0);

      emit(RiskFusedState(data.copyWith(
        xgbRiskScore: xgbScore,
        shapValues: shapValues,
        finalScore: riskResult.finalScore,
        riskLabel: riskResult.riskLabel,
        llmBullets: finalBullets,
      )));
    } catch (e) {
      emit(TransferErrorState(data, errorType: ErrorType.networkTimeout, retryEvent: event));
    }
  }

  // Inject a velocity warning bullet if applicable
  List<String> _injectVelocityBullet(List<String> bullets, int velocity, double amount) {
    if (velocity >= 3 && amount < 200) {
      return [
        'You have made $velocity transfers in the past hour — repeated small transfers are a common scam tactic.',
        ...bullets,
      ];
    }
    return bullets;
  }

  void _onWarningAcknowledged(
    WarningAcknowledged event,
    Emitter<TransferState> emit,
  ) {
    emit(WarningAcknowledgedState(state.data));
  }

  Future<void> _onTransferConfirmed(
    TransferConfirmed event,
    Emitter<TransferState> emit,
  ) async {
    final data = state.data;
    emit(TransferExecutingState(data));

    try {
      final result = await _api.executeTransfer(
        userId: _userId,
        phone: data.recipientPhone ?? '',
        amount: data.amount ?? 0,
        scamCheckId: data.scamCheckId ?? '',
        mlScore: data.finalScore ?? 0,
      );

      // Record this transfer for velocity tracking
      _recentTransferTimes.add(DateTime.now());

      final txnId = result['txn_id'] as String? ?? 'txn_unknown';
      final rawTs = result['timestamp'] as String?;
      final timestamp = rawTs != null ? DateTime.tryParse(rawTs) ?? DateTime.now() : DateTime.now();

      emit(TransferSuccessState(data, txnId: txnId, timestamp: timestamp));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('402') || msg.contains('Insufficient')) {
        emit(TransferErrorState(data, errorType: ErrorType.insufficientFunds));
      } else if (msg.contains('403') || msg.contains('scam')) {
        emit(TransferErrorState(data, errorType: ErrorType.scamBlocked));
      } else {
        emit(TransferErrorState(data, errorType: ErrorType.networkTimeout, retryEvent: event));
      }
    }
  }

  void _onTransferCancelled(
    TransferCancelled event,
    Emitter<TransferState> emit,
  ) {
    emit(const TransferIdle());
  }

  void _onTransferRetried(
    TransferRetried event,
    Emitter<TransferState> emit,
  ) {
    if (state is TransferErrorState) {
      final retryEvent = (state as TransferErrorState).retryEvent;
      if (retryEvent != null) add(retryEvent);
    }
  }
}
