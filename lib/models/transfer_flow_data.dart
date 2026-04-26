import 'risk_label.dart';

class TransferFlowData {
  final String? recipientPhone;
  final String? recipientNickname;
  final bool isWhitelisted;
  final double? gnnRiskScore;
  final Map<String, dynamic>? graphFeatures;
  final String? scamCheckId;
  final double? amount;
  final double? xgbRiskScore;
  final Map<String, dynamic>? shapValues;
  final double? finalScore;
  final RiskLabel? riskLabel;
  final List<String>? llmBullets;
  final int velocity;

  const TransferFlowData({
    this.recipientPhone,
    this.recipientNickname,
    this.isWhitelisted = false,
    this.gnnRiskScore,
    this.graphFeatures,
    this.scamCheckId,
    this.amount,
    this.xgbRiskScore,
    this.shapValues,
    this.finalScore,
    this.riskLabel,
    this.llmBullets,
    this.velocity = 0,
  });

  TransferFlowData copyWith({
    String? recipientPhone,
    String? recipientNickname,
    bool? isWhitelisted,
    double? gnnRiskScore,
    Map<String, dynamic>? graphFeatures,
    String? scamCheckId,
    double? amount,
    double? xgbRiskScore,
    Map<String, dynamic>? shapValues,
    double? finalScore,
    RiskLabel? riskLabel,
    List<String>? llmBullets,
    int? velocity,
  }) {
    return TransferFlowData(
      recipientPhone:   recipientPhone   ?? this.recipientPhone,
      recipientNickname: recipientNickname ?? this.recipientNickname,
      isWhitelisted:    isWhitelisted    ?? this.isWhitelisted,
      gnnRiskScore:     gnnRiskScore     ?? this.gnnRiskScore,
      graphFeatures:    graphFeatures    ?? this.graphFeatures,
      scamCheckId:      scamCheckId      ?? this.scamCheckId,
      amount:           amount           ?? this.amount,
      xgbRiskScore:     xgbRiskScore     ?? this.xgbRiskScore,
      shapValues:       shapValues       ?? this.shapValues,
      finalScore:       finalScore       ?? this.finalScore,
      riskLabel:        riskLabel        ?? this.riskLabel,
      llmBullets:       llmBullets       ?? this.llmBullets,
      velocity:         velocity         ?? this.velocity,
    );
  }
}
