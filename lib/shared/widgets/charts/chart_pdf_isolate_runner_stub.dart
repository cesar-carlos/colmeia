import 'package:colmeia/shared/widgets/charts/chart_pdf_build_isolate.dart';
import 'package:flutter/foundation.dart';

Future<Uint8List> runChartPdfBuild(ChartPdfBuildPayload payload) {
  return compute(buildChartPdfInIsolate, payload);
}
