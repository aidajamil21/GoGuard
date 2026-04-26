// Masks all but last 4 digits
// "+60123456789" → "*******6789"
// MUST be used everywhere phones appear in logs

String maskPhone(String phone) {
  if (phone.length <= 4) return phone;
  return '${'*' * (phone.length - 4)}'
      '${phone.substring(phone.length - 4)}';
}
