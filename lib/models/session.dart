class Contact {
  final String name;
  final String phone;
  const Contact({required this.name, required this.phone});
}

class TransactionSummary {
  final String txnId;
  final double amount;
  final String recipientPhone;
  final DateTime timestamp;
  const TransactionSummary({
    required this.txnId,
    required this.amount,
    required this.recipientPhone,
    required this.timestamp,
  });
}

class Session {
  final String userId;
  double balance;
  List<Contact> recentContacts;
  List<TransactionSummary> transactionHistory;
  final String sessionToken;

  Session({
    required this.userId,
    required this.balance,
    required this.recentContacts,
    required this.transactionHistory,
    required this.sessionToken,
  });
}
