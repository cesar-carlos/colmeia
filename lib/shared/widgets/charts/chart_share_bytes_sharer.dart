import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Platform share boundary for chart PDF bytes (injectable in tests).
typedef ChartShareBytesSharer = Future<ShareResult> Function({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  String? subject,
  String? title,
});
