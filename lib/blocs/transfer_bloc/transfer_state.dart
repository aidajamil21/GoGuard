import '../../models/transfer_flow_data.dart';
import 'transfer_event.dart';

enum ErrorType { networkTimeout, scamBlocked, insufficientFunds, unknown }

abstract class TransferState {
  final TransferFlowData data;
  const TransferState(this.data);
}

class TransferIdle extends TransferState {
  const TransferIdle() : super(const TransferFlowData());
}

class RecipientCheckingState extends TransferState {
  const RecipientCheckingState(super.data);
}

// GNN result ready — shown on ScamCheckScreen
class RecipientCheckedState extends TransferState {
  const RecipientCheckedState(super.data);
}

// Whitelisted contact — skip GNN screen, go straight to amount
class WhitelistedRecipientState extends TransferState {
  const WhitelistedRecipientState(super.data);
}

class AmountEntryState extends TransferState {
  const AmountEntryState(super.data);
}

class BehaviouralAnalysingState extends TransferState {
  const BehaviouralAnalysingState(super.data);
}

class RiskFusedState extends TransferState {
  const RiskFusedState(super.data);
}

class WarningAcknowledgedState extends TransferState {
  const WarningAcknowledgedState(super.data);
}

class TransferExecutingState extends TransferState {
  const TransferExecutingState(super.data);
}

class TransferSuccessState extends TransferState {
  final String txnId;
  final DateTime timestamp;
  const TransferSuccessState(super.data, {
    required this.txnId,
    required this.timestamp,
  });
}

class TransferErrorState extends TransferState {
  final ErrorType errorType;
  final TransferEvent? retryEvent;
  const TransferErrorState(
    super.data, {
    required this.errorType,
    this.retryEvent,
  });
}
