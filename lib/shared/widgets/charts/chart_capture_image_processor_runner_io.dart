import 'dart:io';

import 'package:colmeia/shared/widgets/charts/chart_capture_image_processor.dart';
import 'package:flutter/foundation.dart';

Future<Uint8List> runPngDownscaleForPdfEmbed(Uint8List pngBytes) {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return Future<Uint8List>.value(downscalePngForPdfEmbedSync(pngBytes));
  }
  return compute(downscalePngForPdfEmbedSync, pngBytes);
}
