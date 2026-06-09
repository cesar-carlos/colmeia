/// Outcome of attempting to capture and share a chart image.
sealed class ChartShareResult {
  const ChartShareResult();
}

/// The chart image was shared successfully.
final class ChartShareSuccess extends ChartShareResult {
  const ChartShareSuccess();
}

/// Sharing failed before or during the platform share sheet.
final class ChartShareFailure extends ChartShareResult {
  const ChartShareFailure(
    this.reason, {
    this.pdfFilePath,
  });

  final ChartShareFailureReason reason;

  /// Path to a generated PDF temp file when share failed after PDF creation.
  final String? pdfFilePath;
}

/// Why chart capture/share could not complete.
enum ChartShareFailureReason {
  missingBoundary,
  invalidRenderObject,
  imageEncodingFailed,
  pdfGenerationFailed,
  shareInProgress,
  sharePlatformFailed,
  shareCancelled,
}
