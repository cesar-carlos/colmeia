import 'dart:io';

import 'package:colmeia/shared/widgets/charts/chart_pdf_build_isolate.dart';
import 'package:flutter/foundation.dart';

Future<Uint8List> runChartPdfBuild(ChartPdfBuildPayload payload) {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return buildChartPdfInIsolate(payload);
  }
  return compute(buildChartPdfInIsolate, payload);
}
