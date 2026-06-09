import 'dart:async';
import 'dart:io' show Directory, File, Platform;
import 'dart:typed_data';

import 'package:colmeia/shared/utils/sanitize_report_file_name.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'
    show ShareParams, SharePlus, ShareResult, ShareResultStatus, XFile;
import 'package:uuid/uuid.dart';

export 'package:colmeia/shared/utils/sanitize_report_file_name.dart'
    show sanitizeReportFileName;

const Duration _kShareTempMaxAge = Duration(hours: 24);

bool _shareRequiresTempFilePath() {
  if (kIsWeb) {
    return false;
  }
  return Platform.isWindows ||
      Platform.isLinux ||
      Platform.isMacOS ||
      Platform.isAndroid ||
      Platform.isIOS;
}

/// Windows share UI returns before the user picks a target; keep temp files
/// until stale sweep so the shell can read them asynchronously.
@visibleForTesting
bool deferShareTempFileCleanupUntilStale() {
  return !kIsWeb && Platform.isWindows;
}

String _resolvedShareFileName(String fileName) {
  final baseName = p.basename(fileName);
  if (baseName.isEmpty || baseName == '.pdf') {
    return 'export.pdf';
  }
  return baseName;
}

String _resolvedShareTitle({
  required String fileName,
  String? title,
  String? subject,
}) {
  final resolved = title ?? subject;
  if (resolved != null && resolved.isNotEmpty) {
    return resolved;
  }
  return p.basenameWithoutExtension(fileName);
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

/// Outcome of sharing exported bytes, including a temp file path when present.
class ShareExportBytesResult {
  const ShareExportBytesResult({
    required this.shareResult,
    this.tempFilePath,
  });

  final ShareResult shareResult;
  final String? tempFilePath;
}

bool _shouldCleanupShareTempFileAfterAttempt(ShareResult result) {
  if (!_shareRequiresTempFilePath()) {
    return false;
  }
  if (deferShareTempFileCleanupUntilStale()) {
    return false;
  }
  return result.status == ShareResultStatus.success;
}

/// Shares arbitrary file [bytes] using the platform share sheet.
Future<ShareExportBytesResult> shareExportBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  String? subject,
  String? title,
}) async {
  final resolvedFileName = _resolvedShareFileName(fileName);
  final resolvedTitle = _resolvedShareTitle(
    title: title,
    subject: subject,
    fileName: resolvedFileName,
  );

  final xFile = await createShareableXFile(
    bytes: bytes,
    fileName: resolvedFileName,
    mimeType: mimeType,
  );
  final tempFilePath = _shareRequiresTempFilePath() ? xFile.path : null;
  try {
    final shareResult = await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[xFile],
        subject: subject,
        title: resolvedTitle,
      ),
    );
    if (_shouldCleanupShareTempFileAfterAttempt(shareResult)) {
      unawaited(deleteShareTempFile(xFile.path));
    }
    return ShareExportBytesResult(
      shareResult: shareResult,
      tempFilePath: tempFilePath,
    );
  } on Object {
    return ShareExportBytesResult(
      shareResult: const ShareResult(
        'share_failed',
        ShareResultStatus.unavailable,
      ),
      tempFilePath: tempFilePath,
    );
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
