import 'dart:typed_data';

import 'package:colmeia/shared/widgets/reports/export/report_export_sharing.dart';

/// Platform share boundary for chart PDF bytes (injectable in tests).
typedef ChartShareBytesSharer = Future<ShareExportBytesResult> Function({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  String? subject,
  String? title,
});
