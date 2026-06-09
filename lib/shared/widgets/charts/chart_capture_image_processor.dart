import 'dart:math' as math;
import 'dart:typed_data';

import 'package:colmeia/shared/widgets/charts/chart_capture_image_processor_runner_stub.dart'
    if (dart.library.io) 'package:colmeia/shared/widgets/charts/chart_capture_image_processor_runner_io.dart';
import 'package:image/image.dart' as img;

/// Target pixel width for chart images embedded in A4 landscape PDFs
/// (~150–200 DPI of the usable page width).
const int kChartPdfEmbedMaxWidth = 1550;

/// Target pixel height for chart images embedded in A4 landscape PDFs.
const int kChartPdfEmbedMaxHeight = 520;

/// Downscales [pngBytes] to fit within [kChartPdfEmbedMaxWidth] ×
/// [kChartPdfEmbedMaxHeight] while preserving aspect ratio.
///
/// Returns the original bytes when already within bounds or when decoding fails.
Future<Uint8List> downscalePngForPdfEmbed(Uint8List pngBytes) {
  return runPngDownscaleForPdfEmbed(pngBytes);
}

/// Synchronous downscale entry point for background isolates.
Uint8List downscalePngForPdfEmbedSync(Uint8List pngBytes) {
  final decoded = img.decodePng(pngBytes);
  if (decoded == null) {
    return pngBytes;
  }

  if (decoded.width <= kChartPdfEmbedMaxWidth &&
      decoded.height <= kChartPdfEmbedMaxHeight) {
    return pngBytes;
  }

  final scale = math.min(
    kChartPdfEmbedMaxWidth / decoded.width,
    kChartPdfEmbedMaxHeight / decoded.height,
  );
  if (scale >= 1) {
    return pngBytes;
  }

  final targetWidth = math.max(1, (decoded.width * scale).round());
  final targetHeight = math.max(1, (decoded.height * scale).round());

  try {
    final resized = img.copyResize(
      decoded,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.linear,
    );
    return Uint8List.fromList(img.encodePng(resized));
  } on Object {
    return pngBytes;
  }
}

/// Decodes PNG dimensions for tests and diagnostics.
Future<({int width, int height})?> decodePngDimensions(
  Uint8List pngBytes,
) async {
  final decoded = img.decodePng(pngBytes);
  if (decoded == null) {
    return null;
  }
  return (width: decoded.width, height: decoded.height);
}
