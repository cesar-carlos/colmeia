import 'dart:io';

import 'package:colmeia/shared/widgets/reports/export/report_export_sharing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    const pathProviderChannel =
        MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
      if (call.method == 'getTemporaryDirectory') {
        return Directory.systemTemp.path;
      }
      return null;
    });
  });

  tearDown(() async {
    const pathProviderChannel =
        MethodChannel('plugins.flutter.io/path_provider');
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

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final file = File(xFile.path);
      expect(file.existsSync(), isTrue);
      expect(file.readAsBytesSync(), bytes);
      expect(file.parent.path, isNot(file.path));
      file.parent.deleteSync(recursive: true);
      return;
    }

    expect(xFile.name, 'chart_test.pdf');
  });

  test('deleteShareTempFile removes uuid temp directory', () async {
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return;
    }

    final bytes = Uint8List.fromList(<int>[5, 6, 7]);
    final xFile = await createShareableXFile(
      bytes: bytes,
      fileName: 'cleanup_test.pdf',
      mimeType: 'application/octet-stream',
    );
    final parent = File(xFile.path).parent;
    expect(parent.existsSync(), isTrue);

    await deleteShareTempFile(xFile.path);

    expect(parent.existsSync(), isFalse);
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
}
