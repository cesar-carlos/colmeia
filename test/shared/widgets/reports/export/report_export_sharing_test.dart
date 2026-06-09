import 'dart:io';

import 'package:colmeia/shared/widgets/reports/export/report_export_sharing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getTemporaryDirectory') {
        return Directory.systemTemp.path;
      }
      return null;
    });
  });

  tearDown(() async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
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
}
