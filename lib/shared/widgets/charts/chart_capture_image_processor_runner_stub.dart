
import 'package:colmeia/shared/widgets/charts/chart_capture_image_processor.dart';
import 'package:flutter/foundation.dart';

Future<Uint8List> runPngDownscaleForPdfEmbed(Uint8List pngBytes) {
  return compute(downscalePngForPdfEmbedSync, pngBytes);
}
