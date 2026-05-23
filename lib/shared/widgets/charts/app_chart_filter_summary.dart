/// Shared middle-dot separator and parsing for chart fullscreen filter chips.
abstract final class AppChartFilterSummary {
  static const int middleDotCodePoint = 0x00B7;

  /// Spaced middle dot (` · `) used to join filter summary segments.
  static String get spacedMiddleDotSeparator =>
      ' ${String.fromCharCode(middleDotCodePoint)} ';

  /// UTF-8 bytes for U+00B7 (`C2 B7`) misread as Latin-1 become U+00C2 + U+00B7.
  static String normalizeMiddleDotMojibake(String value) {
    final mojibakeSeparator = String.fromCharCodes(<int>[
      0x00C2,
      middleDotCodePoint,
    ]);
    return value.replaceAll(
      mojibakeSeparator,
      String.fromCharCode(middleDotCodePoint),
    );
  }

  /// Splits [value] on the middle-dot separator after [normalizeMiddleDotMojibake].
  static List<String> splitOnMiddleDot(String value) {
    final normalized = normalizeMiddleDotMojibake(value);
    return normalized
        .split(String.fromCharCode(middleDotCodePoint))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
  }
}
