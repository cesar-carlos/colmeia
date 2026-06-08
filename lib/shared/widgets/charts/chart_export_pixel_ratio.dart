import 'dart:math' as math;

import 'package:colmeia/shared/widgets/charts/chart_capture_image_processor.dart';

const double kDefaultChartCaptureMaxPixelRatio = 3;
const double kWideChartCaptureMaxPixelRatio = 2;

/// Resolves the device pixel ratio used when rasterizing a chart for PDF export.
///
/// Wide logical charts use a lower cap so capture stays within
/// [kChartPdfEmbedMaxWidth] without oversampling. When [logicalHeight] is set,
/// the ratio also respects [kChartPdfEmbedMaxHeight] so square exports are not
/// rasterized larger than the PDF embed slot.
double resolveChartExportPixelRatio({
  required double logicalWidth,
  double? logicalHeight,
  double? pixelRatio,
  double? devicePixelRatio,
  int targetPixelWidth = kChartPdfEmbedMaxWidth,
  int targetPixelHeight = kChartPdfEmbedMaxHeight,
  double maxPixelRatio = kDefaultChartCaptureMaxPixelRatio,
  double wideChartCapPixelRatio = kWideChartCaptureMaxPixelRatio,
}) {
  if (pixelRatio != null) {
    return pixelRatio.clamp(1, maxPixelRatio).toDouble();
  }

  if (logicalWidth <= 0) {
    return (devicePixelRatio ?? 1).clamp(1, maxPixelRatio).toDouble();
  }

  final widthScale = targetPixelWidth / logicalWidth;
  final heightScale = logicalHeight != null && logicalHeight > 0
      ? targetPixelHeight / logicalHeight
      : double.infinity;
  final adaptive = math.min(
    maxPixelRatio,
    math.min(widthScale, heightScale),
  );
  final cap = logicalWidth > targetPixelWidth
      ? wideChartCapPixelRatio
      : maxPixelRatio;
  return math.min(adaptive, cap).clamp(1, maxPixelRatio).toDouble();
}

/// Whether rasterizing at [pixelRatio] keeps the capture within PDF embed bounds.
bool chartCaptureFitsPdfEmbedBounds({
  required double logicalWidth,
  required double logicalHeight,
  required double pixelRatio,
  int targetPixelWidth = kChartPdfEmbedMaxWidth,
  int targetPixelHeight = kChartPdfEmbedMaxHeight,
}) {
  if (logicalWidth <= 0 || logicalHeight <= 0) {
    return false;
  }
  final width = (logicalWidth * pixelRatio).round();
  final height = (logicalHeight * pixelRatio).round();
  return width <= targetPixelWidth && height <= targetPixelHeight;
}
