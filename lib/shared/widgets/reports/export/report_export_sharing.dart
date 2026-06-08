import 'dart:io' show File, Platform;
import 'dart:typed_data';

import 'package:colmeia/shared/utils/sanitize_report_file_name.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'
    show ShareParams, SharePlus, ShareResult, XFile;

export 'package:colmeia/shared/utils/sanitize_report_file_name.dart'
    show sanitizeReportFileName;

bool _shareRequiresTempFilePath() {
  return !kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
}

/// Creates an [XFile] suitable for desktop share sheets (path-backed on Windows).
Future<XFile> createShareableXFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  if (_shareRequiresTempFilePath()) {
    final directory = await getTemporaryDirectory();
    final filePath = p.join(directory.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return XFile(filePath, mimeType: mimeType, name: fileName);
  }

  return XFile.fromData(
    bytes,
    name: fileName,
    mimeType: mimeType,
  );
}

/// Shares arbitrary file [bytes] using the platform share sheet.
Future<ShareResult> shareExportBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  String? subject,
}) async {
  final xFile = await createShareableXFile(
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
  );
  return SharePlus.instance.share(
    ShareParams(
      files: <XFile>[xFile],
      subject: subject,
    ),
  );
}

/// Shares exported report [bytes] as a file using the platform share sheet.
Future<void> shareReportExportBytes({
  required AppReportExportFormat format,
  required Uint8List bytes,
  String? title,
}) async {
  final fileName =
      '${sanitizeReportFileName(title ?? 'relatorio')}.${format.fileExtension}';
  await shareExportBytes(
    bytes: bytes,
    fileName: fileName,
    mimeType: format.mimeType,
    subject: title ?? 'Relatório',
  );
}
