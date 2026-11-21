import 'dart:async';
import 'dart:io';

import 'package:colmeia/shared/widgets/reports/export/report_export_sharing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    const pathProviderChannel = MethodChannel(
      'plugins.flutter.io/path_provider',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          if (call.method == 'getTemporaryDirectory') {
            return Directory.systemTemp.path;
          }
          return null;
        });
  });

  tearDown(() async {
    const pathProviderChannel = MethodChannel(
      'plugins.flutter.io/path_provider',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);

    const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, null);
  });

  test('createShareableXFile writes bytes to a temp path on desktop', () async {
    final bytes = Uint8List.fromList(<int>[1, 2, 3, 4]);
    final xFile = await createShareableXFile(
      bytes: bytes,
      fileName: 'chart_test.pdf',
      mimeType: 'application/pdf',
    );

    if (Platform.isWindows || Platform.isAndroid) {
      final file = File(xFile.path);
      expect(file.existsSync(), isTrue);
      expect(file.readAsBytesSync(), bytes);
      expect(file.parent.path, isNot(file.path));
      expect(
        file.parent.parent.uri.pathSegments,
        contains('colmeia_share_exports'),
      );
      await deleteShareTempFile(xFile.path);
      return;
    }

    expect(xFile.name, 'chart_test.pdf');
    expect(await xFile.readAsBytes(), bytes);
  });

  test('deleteShareTempFile removes uuid temp directory', () async {
    final parent = Directory(
      p.join(
        Directory.systemTemp.path,
        'colmeia_share_exports',
        const Uuid().v4(),
      ),
    );
    await parent.create(recursive: true);
    final file = await File(p.join(parent.path, 'cleanup_test.pdf'))
        .writeAsBytes(
          <int>[5, 6, 7],
        );
    expect(parent.existsSync(), isTrue);

    await deleteShareTempFile(file.path);

    expect(parent.existsSync(), isFalse);
  });

  test('should ignore empty and relative cleanup paths', () async {
    await deleteShareTempFile('');
    await deleteShareTempFile('report.pdf');
    expect(Directory.current.existsSync(), isTrue);
  });

  test('should preserve files outside the share export directory', () async {
    final directory = await Directory.systemTemp.createTemp('colmeia_guard_');
    addTearDown(() => directory.delete(recursive: true));
    final file = await File(p.join(directory.path, 'keep.pdf')).writeAsString(
      'keep',
    );
    await deleteShareTempFile(file.path);
    expect(await file.readAsString(), 'keep');
  });

  test('shareExportBytes uses share_plus with path-backed PDF file', () async {
    if (!(Platform.isWindows || Platform.isMacOS)) {
      return;
    }

    Map<dynamic, dynamic>? capturedArgs;
    const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, (call) async {
          if (call.method == 'share') {
            capturedArgs = call.arguments as Map<dynamic, dynamic>?;
            return 'dev.fluttercommunity.plus/share/unavailable';
          }
          return null;
        });

    final bytes = Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46]);
    final result = await shareExportBytes(
      bytes: bytes,
      fileName: 'grafico.pdf',
      mimeType: 'application/pdf',
      subject: 'Grafico',
      title: 'Grafico de vendas',
    );

    expect(result.shareResult.status, ShareResultStatus.unavailable);
    expect(result.isUnconfirmedShare, Platform.isWindows);
    expect(capturedArgs, isNotNull);
    final paths = capturedArgs!['paths'] as List<dynamic>?;
    expect(paths, isNotNull);
    expect(paths, hasLength(1));
    final sharedPath = paths!.single as String;
    expect(File(sharedPath).existsSync(), isTrue);
    expect(capturedArgs!['title'], 'Grafico de vendas');
    expect(
      (capturedArgs!['mimeTypes'] as List<dynamic>).single,
      'application/pdf',
    );

    if (!deferShareTempFileCleanupUntilStale()) {
      await deleteShareTempFile(sharedPath);
    } else {
      expect(File(sharedPath).existsSync(), isTrue);
      await deleteShareTempFile(sharedPath);
    }
  });

  test('deferShareTempFileCleanupUntilStale is true only on Windows', () {
    expect(
      deferShareTempFileCleanupUntilStale(),
      Platform.isWindows,
    );
  });

  test(
    'should preserve the PDF path when the native share call times out',
    () async {
      if (!(Platform.isWindows || Platform.isMacOS)) {
        return;
      }
      const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
      final pending = Completer<Object?>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(shareChannel, (_) => pending.future);

      final result = await shareExportBytes(
        bytes: Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46]),
        fileName: 'timeout.pdf',
        mimeType: 'application/pdf',
        shareTimeout: const Duration(milliseconds: 10),
      );

      expect(result.isUnconfirmedShare, isFalse);
      expect(result.shareResult.status, ShareResultStatus.unavailable);
      expect(result.tempFilePath, isNotNull);
      expect(File(result.tempFilePath!).existsSync(), isTrue);
      pending.complete('dev.fluttercommunity.plus/share/unavailable');
      await deleteShareTempFile(result.tempFilePath!);
    },
  );
}
