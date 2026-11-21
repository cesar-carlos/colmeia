import 'dart:convert';

import 'package:colmeia/core/config/app_dotenv_loader.dart';
import 'package:colmeia/core/config/env_keys.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, String> assets;
  late List<String> requests;
  late bool includeLocal;

  setUp(() {
    dotenv.clean();
    rootBundle.clear();
    assets = <String, String>{
      EnvAssetPaths.bundledDefault: 'TEST_CONFIG=default',
    };
    requests = <String>[];
    includeLocal = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final key = utf8.decode(message!.buffer.asUint8List());
          requests.add(key);
          if (key == 'AssetManifest.bin') {
            return const StandardMessageCodec().encodeMessage(
              <String, Object?>{
                EnvAssetPaths.bundledDefault: <Object?>[],
                if (includeLocal) EnvAssetPaths.bundledLocal: <Object?>[],
              },
            );
          }
          final content = assets[key];
          return content == null
              ? null
              : ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    rootBundle.clear();
    dotenv.clean();
  });

  test('should not request a local file absent from the bundle', () async {
    await loadAppDotenv();

    expect(dotenv.env['TEST_CONFIG'], 'default');
    expect(requests, isNot(contains(EnvAssetPaths.bundledLocal)));
  });

  test('should merge a local file explicitly included in the bundle', () async {
    includeLocal = true;
    assets[EnvAssetPaths.bundledLocal] = 'TEST_CONFIG=local\nEXTRA_CONFIG=yes';

    await loadAppDotenv();

    expect(dotenv.env['TEST_CONFIG'], 'local');
    expect(dotenv.env['EXTRA_CONFIG'], 'yes');
  });

  test(
    'should preserve defaults when the optional asset cannot be read',
    () async {
      includeLocal = true;

      await loadAppDotenv();

      expect(dotenv.env['TEST_CONFIG'], 'default');
    },
  );

  test('should fail when required default configuration is missing', () async {
    assets.clear();

    await expectLater(loadAppDotenv(), throwsA(isA<FileNotFoundError>()));
    expect(requests, isNot(contains(EnvAssetPaths.bundledLocal)));
  });
}
