/// Normalizes phone numbers for storage and lookup (E.164-style).
class PhoneNormalizer {
  PhoneNormalizer._();

  static String? normalize(String raw) {
    var phone = raw.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (phone.isEmpty) return null;
    if (!phone.startsWith('+')) {
      if (phone.startsWith('0')) phone = phone.substring(1);
      phone = '+92$phone';
    }
    if (!RegExp(r'^\+\d{10,15}$').hasMatch(phone)) return null;
    return phone;
  }

  /// Firestore-safe document id for [normalize] output.
  static String docId(String normalizedPhone) =>
      normalizedPhone.replaceFirst('+', '');
}
