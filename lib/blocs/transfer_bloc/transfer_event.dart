abstract class TransferEvent {}

class RecipientSubmitted extends TransferEvent {
  final String phone;
  final String? nickname;
  final bool isWhitelisted;
  RecipientSubmitted(this.phone, {this.nickname, this.isWhitelisted = false});
}

class RecipientCheckConfirmed extends TransferEvent {}
class RecipientCheckCancelled extends TransferEvent {}

class AmountSubmitted extends TransferEvent {
  final double amount;
  final double balance;
  AmountSubmitted({required this.amount, required this.balance});
}

class BehaviouralAnalysisStarted extends TransferEvent {}
class WarningAcknowledged extends TransferEvent {}
class TransferConfirmed extends TransferEvent {}
class TransferCancelled extends TransferEvent {}
class TransferRetried extends TransferEvent {}
