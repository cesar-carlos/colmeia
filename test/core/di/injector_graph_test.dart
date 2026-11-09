import 'dart:io';

import 'package:colmeia/app/bootstrap.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/domain/ports/agent_presence_stream.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('colmeia-di-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => directory.path,
        );
  });
  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await directory.delete(recursive: true);
  });
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });
  tearDown(() async {
    await resetDependenciesForTesting();
    debugDefaultTargetPlatformOverride = null;
    dotenv.clean();
  });

  test(
    'should clean registrations when storage initialization fails',
    () async {
      _configure();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      messenger.setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(code: 'storage_unavailable');
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(
          channel,
          (_) async => directory.path,
        );
      });

      await expectLater(setupDependencies(), throwsA(isA<PlatformException>()));
      expect(getIt.findAll<Object>(), isEmpty);
    },
  );

  for (final config in [
    (transport: 'rest', presence: false, relay: false),
    (transport: 'rest', presence: true, relay: false),
    (transport: 'rest', presence: false, relay: true),
    (transport: 'rest', presence: true, relay: true),
    (transport: 'socket', presence: false, relay: false),
    (transport: 'socket', presence: true, relay: true),
  ]) {
    for (final fake in [false, true]) {
      test(
        'should resolve the full graph with $config and fake=$fake',
        () async {
          _configure(
            transport: config.transport,
            presence: config.presence,
            relay: config.relay,
            fake: fake,
          );
          await Future.wait([setupDependencies(), setupDependencies()]);
          validateBootstrapDependencies();
          final singletons = getIt.findAll<Object>(
            instantiateLazySingletons: true,
          );
          final all = getIt.findAll<Object>(
            instantiateLazySingletons: true,
            callFactories: true,
          );
          for (final instance in all.whereType<ChangeNotifier>()) {
            if (!singletons.any((value) => identical(value, instance))) {
              instance.dispose();
            }
          }
          final auth = getIt<AuthController>();
          await setupDependencies();
          expect(getIt<AuthController>(), same(auth));
          expect(all.length, greaterThan(singletons.length));
        },
      );
    }
  }

  test(
    'should detect missing lifecycle dependencies before mounting the app',
    () async {
      _configure();
      await setupDependencies();
      await getIt.unregister<AgentPresenceStream>();
      expect(validateBootstrapDependencies, throwsStateError);
    },
  );

  test(
    'should clean partial registrations and allow retry after setup fails',
    () async {
      _configure(poolSize: 2);
      await expectLater(setupDependencies(), throwsStateError);
      expect(getIt.findAll<Object>(), isEmpty);
      _configure();
      await setupDependencies();
      validateBootstrapDependencies();
    },
  );
}

void _configure({
  String transport = 'rest',
  bool presence = false,
  bool relay = false,
  bool fake = false,
  int poolSize = 1,
}) {
  dotenv.loadFromString(
    envString:
        '''
API_BASE_URL=https://example.invalid
USE_FAKE_BACKEND=$fake
AGENT_BRIDGE_TRANSPORT=$transport
SOCKET_PRESENCE_LISTENER_ENABLED=$presence
SOCKET_RELAY_ENABLED=$relay
SOCKET_BATCH_ENABLED=$relay
SOCKET_PAYLOAD_WORKER_ISOLATES_ENABLED=false
SOCKET_PAYLOAD_REQUIRE_SIGNATURE=false
SOCKET_CONNECTION_POOL_SIZE=$poolSize
''',
  );
}
