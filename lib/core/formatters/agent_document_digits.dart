/// Keeps only ASCII digits; returns null when [raw] is null or has no digits.
String? digitsOnlyDocument(String? raw) {
  if (raw == null) {
    return null;
  }
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return null;
  }
  return digits;
}
