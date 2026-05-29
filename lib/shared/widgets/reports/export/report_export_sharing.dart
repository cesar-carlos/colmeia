import 'dart:typed_data';

import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus, XFile;

/// Shares exported report [bytes] as a file using the platform share sheet.
Future<void> shareReportExportBytes({
  required AppReportExportFormat format,
  required Uint8List bytes,
  String? title,
}) async {
  final fileName =
      '${sanitizeReportFileName(title ?? 'relatorio')}.${format.fileExtension}';
  await SharePlus.instance.share(
    ShareParams(
      files: <XFile>[
        XFile.fromData(
          bytes,
          name: fileName,
          mimeType: format.mimeType,
        ),
      ],
      subject: title ?? 'Relatório',
    ),
  );
}

/// Strips characters that are unsafe for file names and replaces spaces.
String sanitizeReportFileName(String name) {
  return name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
}
