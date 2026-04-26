// Malaysian phone number validator
// Accepts: +60XXXXXXXXX (9-11 digits) or 01XXXXXXXX (10-11 digits)
// Examples: +60123456789, 0123456789, +601234567890
bool validateMalaysianPhone(String phone) {
  final cleaned = phone.trim().replaceAll(RegExp(r'[\s\-]'), ''); // Remove spaces and dashes
  final regex = RegExp(r'^\+60[0-9]{9,11}$|^0[0-9]{9,10}$');
  return regex.hasMatch(cleaned);
}

// Amount validator
// Returns null if valid, error message if invalid
String? validateAmount(double amount, double balance) {
  if (amount <= 0) return 'Amount must be greater than zero';
  if (amount > balance) return 'Insufficient funds';
  return null;
}

// Report description validator
String? validateDescription(String description) {
  if (description.trim().length < 20) {
    return 'Description must be at least 20 characters';
  }
  return null;
}
