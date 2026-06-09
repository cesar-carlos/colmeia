import 'dart:async';
import 'dart:io' show Directory, File, Platform;
import 'dart:typed_data';

import 'package:colmeia/shared/utils/sanitize_report_file_name.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart'
    show ShareParams, SharePlus, ShareResult, ShareResultStatus, XFile;
import 'package:uuid/uuid.dart';

export 'package:colmeia/shared/utils/sanitize_report_file_name.dart'
    show sanitizeReportFileName;

const Duration _kShareTempMaxAge = Duration(hours: 24);

bool _shareRequiresTempFilePath() {
  return !kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
}

bool _sharePdfViaPrintingOnWindows(String mimeType) {
  return !kIsWeb && Platform.isWindows && mimeType == 'application/pdf';
}

String _resolvedShareFileName(String fileName) {
  final baseName = p.basename(fileName);
  if (baseName.isEmpty || baseName == '.pdf') {
    return 'export.pdf';
  }
  return baseName;
}

Future<void> _sweepStaleShareTempDirectories(Directory tempRoot) async {
  final cutoff = DateTime.now().subtract(_kShareTempMaxAge);
  try {
    await for (final entity in tempRoot.list()) {
      if (entity is! Directory) {
        continue;
      }
      try {
        final stat = entity.statSync();
        if (stat.modified.isBefore(cutoff)) {
          await entity.delete(recursive: true);
        }
      } on Object {
        // Best-effort cleanup; ignore locked or removed directories.
      }
    }
  } on Object {
    // Best-effort cleanup.
  }
}

@visibleForTesting
Future<void> deleteShareTempFile(String filePath) async {
  try {
    final file = File(filePath);
    final parent = file.parent;
    if (parent.existsSync()) {
      await parent.delete(recursive: true);
    }
  } on Object {
    // Best-effort cleanup after share attempt.
  }
}

/// Creates an [XFile] suitable for desktop share sheets (path-backed on Windows).
Future<XFile> createShareableXFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  if (_shareRequiresTempFilePath()) {
    final directory = await getTemporaryDirectory();
    unawaited(_sweepStaleShareTempDirectories(directory));
    final resolvedFileName = _resolvedShareFileName(fileName);
    final fileDirectory = Directory(
      p.join(directory.path, const Uuid().v4()),
    );
    await fileDirectory.create(recursive: true);
    final filePath = p.normalize(
      p.join(fileDirectory.path, resolvedFileName),
    );
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return XFile(
      file.absolute.path,
      mimeType: mimeType,
      name: resolvedFileName,
    );
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
  String? title,
}) async {
  final resolvedFileName = _resolvedShareFileName(fileName);
  final resolvedTitle = title ?? subject;

  if (_sharePdfViaPrintingOnWindows(mimeType)) {
    final opened = await Printing.sharePdf(
      bytes: bytes,
      filename: resolvedFileName,
      subject: subject,
    );
    if (!opened) {
      throw StateError('Printing.sharePdf failed to open PDF on Windows');
    }
    return const ShareResult(
      'printing.sharePdf',
      ShareResultStatus.unavailable,
    );
  }

  final xFile = await createShareableXFile(
    bytes: bytes,
    fileName: resolvedFileName,
    mimeType: mimeType,
  );
  try {
    return await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[xFile],
        subject: subject,
        title: resolvedTitle,
      ),
    );
  } finally {
    if (_shareRequiresTempFilePath()) {
      unawaited(deleteShareTempFile(xFile.path));
    }
  }
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
    title: title,
  );
}
