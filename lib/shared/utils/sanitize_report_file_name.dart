/// Strips characters that are unsafe for file names and replaces spaces.
String sanitizeReportFileName(String name) {
  return name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
}
