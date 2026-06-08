import 'dart:math' as math;

import 'package:colmeia/shared/widgets/charts/chart_capture_image_processor.dart';

const double kDefaultChartCaptureMaxPixelRatio = 3;
const double kWideChartCaptureMaxPixelRatio = 2;

/// Resolves the device pixel ratio used when rasterizing a chart for PDF export.
///
/// Wide logical charts use a lower cap so capture stays within
/// [kChartPdfEmbedMaxWidth] without oversampling.
double resolveChartExportPixelRatio({
  required double logicalWidth,
  double? pixelRatio,
  double? devicePixelRatio,
  int targetPixelWidth = kChartPdfEmbedMaxWidth,
  double maxPixelRatio = kDefaultChartCaptureMaxPixelRatio,
  double wideChartCapPixelRatio = kWideChartCaptureMaxPixelRatio,
}) {
  if (pixelRatio != null) {
    return pixelRatio.clamp(1, maxPixelRatio).toDouble();
  }

  if (logicalWidth <= 0) {
    return (devicePixelRatio ?? 1).clamp(1, maxPixelRatio).toDouble();
  }

  final adaptive = math.min(maxPixelRatio, targetPixelWidth / logicalWidth);
  final cap = logicalWidth > targetPixelWidth
      ? wideChartCapPixelRatio
      : maxPixelRatio;
  return math.min(adaptive, cap).clamp(1, maxPixelRatio).toDouble();
}
