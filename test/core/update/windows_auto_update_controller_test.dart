import 'dart:async';

import 'package:auto_updater/auto_updater.dart';
import 'package:checks/checks.dart';
import 'package:colmeia/core/preferences/app_user_preferences_store.dart';
import 'package:colmeia/core/update/app_auto_update_support.dart';
import 'package:colmeia/core/update/appcast_probe_client.dart';
import 'package:colmeia/core/update/auto_updater_client.dart';
import 'package:colmeia/core/update/windows_auto_update_controller.dart';
import 'package:colmeia/core/update/windows_auto_update_diagnostic.dart';
import 'package:colmeia/core/update/windows_auto_update_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('WindowsAutoUpdateController', () {
    test('should stay hidden on unsupported platforms', () async {
      final controller = WindowsAutoUpdateController(
        autoUpdaterClient: _FakeAutoUpdaterClient(),
        appcastProbeClient: _FakeProbeHarness().client,
        feedUrlResolver: () => 'https://example.com/appcast.xml',
        preferencesStore: await _createPreferencesStore(),
        supportsNativeUpdates: () => false,
      );

      await controller.initialize();

      check(controller.state.availability).equals(
        AppAutoUpdateAvailability.unsupportedPlatform,
      );
      check(controller.state.shouldShowInSettings).isFalse();
    });

    test(
      'should expose informative disabled state when feed is missing',
      () async {
        final controller = WindowsAutoUpdateController(
          autoUpdaterClient: _FakeAutoUpdaterClient(),
          appcastProbeClient: _FakeProbeHarness().client,
          feedUrlResolver: () => '',
          preferencesStore: await _createPreferencesStore(),
          supportsNativeUpdates: () => true,
        );

        await controller.initialize();

        check(controller.state.availability).equals(
          AppAutoUpdateAvailability.feedUrlMissing,
        );
        check(controller.state.canCheckForUpdates).isFalse();
        check(controller.state.headline).contains('indisponiveis');
        check(controller.state.details).isNotNull().contains('feed oficial');
        check(controller.state.lastCheckedAt).isNull();
      },
    );

    test(
      'should clear stale last check when current build has no feed',
      () async {
        final prefsStore = await _createPreferencesStore();
        await prefsStore.persistWindowsAutoUpdateDiagnostic(
          WindowsAutoUpdateDiagnostic(
            status: WindowsAutoUpdateStatus.upToDate,
            headline: 'Este build ja esta atualizado.',
            details: 'Nenhuma release mais nova foi encontrada.',
            feedUrl: 'https://example.com/appcast.xml',
            lastCheckedAt: DateTime(2026, 5, 5, 12),
          ),
        );
        final controller = WindowsAutoUpdateController(
          autoUpdaterClient: _FakeAutoUpdaterClient(),
          appcastProbeClient: _FakeProbeHarness().client,
          feedUrlResolver: () => '',
          preferencesStore: prefsStore,
          supportsNativeUpdates: () => true,
        );

        await controller.initialize();

        check(controller.state.availability).equals(
          AppAutoUpdateAvailability.feedUrlMissing,
        );
        check(controller.state.lastCheckedAt).isNull();
      },
    );

    test('should initialize updater and trigger background check', () async {
      final client = _FakeAutoUpdaterClient();
      final probeHarness = _FakeProbeHarness();
      final controller = WindowsAutoUpdateController(
        autoUpdaterClient: client,
        appcastProbeClient: probeHarness.client,
        feedUrlResolver: () => 'https://example.com/appcast.xml',
        preferencesStore: await _createPreferencesStore(),
        supportsNativeUpdates: () => true,
      );

      await controller.initialize();
      await Future<void>.delayed(Duration.zero);

      check(client.feedUrls).deepEquals(<String>[
        'https://example.com/appcast.xml',
      ]);
      check(client.scheduledIntervals).deepEquals(<int>[
        WindowsAutoUpdateController.scheduledCheckIntervalInSeconds,
      ]);
      check(client.checkCalls).deepEquals(<bool>[true]);
      check(probeHarness.feedUrls).deepEquals(<String>[
        'https://example.com/appcast.xml',
      ]);
      check(controller.state.status).equals(WindowsAutoUpdateStatus.checking);
    });

    test('should expose update available and up-to-date callbacks', () async {
      final client = _FakeAutoUpdaterClient();
      final controller = WindowsAutoUpdateController(
        autoUpdaterClient: client,
        appcastProbeClient: _FakeProbeHarness().client,
        feedUrlResolver: () => 'https://example.com/appcast.xml',
        preferencesStore: await _createPreferencesStore(),
        supportsNativeUpdates: () => true,
      );

      await controller.initialize();

      controller.onUpdaterUpdateAvailable(null);
      check(controller.state.status).equals(
        WindowsAutoUpdateStatus.updateAvailable,
      );

      controller.onUpdaterUpdateNotAvailable(null);
      check(controller.state.status).equals(WindowsAutoUpdateStatus.upToDate);
    });

    test('should expose failed state when updater reports error', () async {
      final client = _FakeAutoUpdaterClient();
      final controller = WindowsAutoUpdateController(
        autoUpdaterClient: client,
        appcastProbeClient: _FakeProbeHarness().client,
        feedUrlResolver: () => 'https://example.com/appcast.xml',
        preferencesStore: await _createPreferencesStore(),
        supportsNativeUpdates: () => true,
      );

      await controller.initialize();
      controller.onUpdaterError(UpdaterError('network error'));

      check(controller.state.status).equals(WindowsAutoUpdateStatus.failed);
      check(controller.state.details).equals('network error');
    });

    test('should stop before native check when appcast probe fails', () async {
      final client = _FakeAutoUpdaterClient();
      final probeHarness = _FakeProbeHarness(
        nextResult: const AppcastProbeResult.failure(
          failureKind: AppcastProbeFailureKind.timeout,
          details: 'O feed demorou mais que o esperado para responder.',
        ),
      );
      final controller = WindowsAutoUpdateController(
        autoUpdaterClient: client,
        appcastProbeClient: probeHarness.client,
        feedUrlResolver: () => 'https://example.com/appcast.xml',
        preferencesStore: await _createPreferencesStore(),
        supportsNativeUpdates: () => true,
      );

      await controller.initialize();
      client.checkCalls.clear();

      await controller.checkForUpdates();

      check(client.checkCalls).isEmpty();
      check(controller.state.status).equals(WindowsAutoUpdateStatus.failed);
      check(controller.state.headline).equals(
        'O feed oficial nao respondeu a tempo.',
      );
      check(controller.state.details).equals(
        'O feed demorou mais que o esperado para responder.',
      );
    });

    test(
      'should treat empty appcast as feed without releases without native check',
      () async {
        final client = _FakeAutoUpdaterClient();
        final probeHarness = _FakeProbeHarness(
          nextResult: const AppcastProbeResult.success(hasReleases: false),
        );
        final controller = WindowsAutoUpdateController(
          autoUpdaterClient: client,
          appcastProbeClient: probeHarness.client,
          feedUrlResolver: () => 'https://example.com/appcast.xml',
          preferencesStore: await _createPreferencesStore(),
          supportsNativeUpdates: () => true,
        );

        await controller.initialize();
        client.checkCalls.clear();

        await controller.checkForUpdates();

        check(client.checkCalls).isEmpty();
        check(controller.state.status).equals(
          WindowsAutoUpdateStatus.feedWithoutReleases,
        );
        check(controller.state.headline).equals(
          'Feed sem releases publicadas.',
        );
        check(controller.state.details!).contains('ainda nao ha itens de release');
        check(controller.state.lastCheckedAt).isNotNull();
      },
    );

    test('should ignore concurrent check while probe is in flight', () async {
      final client = _FakeAutoUpdaterClient();
      final probeHarness = _SlowProbeHarness();
      final controller = WindowsAutoUpdateController(
        autoUpdaterClient: client,
        appcastProbeClient: probeHarness.client,
        feedUrlResolver: () => 'https://example.com/appcast.xml',
        preferencesStore: await _createPreferencesStore(),
        supportsNativeUpdates: () => true,
      );

      final firstCheck = controller.checkForUpdates();
      await Future<void>.delayed(Duration.zero);
      await controller.checkForUpdates();
      probeHarness.complete();
      await firstCheck;

      check(probeHarness.feedUrls.length).equals(1);
    });

    test(
      'should ignore persisted diagnostic when feed url changed',
      () async {
        final checkedAt = DateTime(2026, 5, 5, 12);
        final prefsStore = await _createPreferencesStore();
        await prefsStore.persistWindowsAutoUpdateDiagnostic(
          WindowsAutoUpdateDiagnostic(
            status: WindowsAutoUpdateStatus.upToDate,
            headline: 'Este build ja esta atualizado.',
            details: 'Nenhuma release mais nova foi encontrada.',
            feedUrl: 'https://old.example.com/appcast.xml',
            lastCheckedAt: checkedAt,
          ),
        );

        final controller = WindowsAutoUpdateController(
          autoUpdaterClient: _FakeAutoUpdaterClient(),
          appcastProbeClient: _FakeProbeHarness().client,
          feedUrlResolver: () => 'https://example.com/appcast.xml',
          preferencesStore: prefsStore,
          supportsNativeUpdates: () => true,
        );

        await controller.initialize();

        expect(
          controller.state.headline,
          isNot(contains('Este build ja esta atualizado.')),
        );
        check(controller.state.lastCheckedAt).isNull();
      },
    );

    test(
      'should reset persisted in-flight status before background check',
      () async {
        final prefsStore = await _createPreferencesStore();
        await prefsStore.persistWindowsAutoUpdateDiagnostic(
          WindowsAutoUpdateDiagnostic(
            status: WindowsAutoUpdateStatus.updateAvailable,
            headline: 'Nova versao encontrada.',
            details: 'Download em andamento.',
            feedUrl: 'https://example.com/appcast.xml',
            lastCheckedAt: DateTime(2026, 5, 5, 12),
          ),
        );

        final controller = WindowsAutoUpdateController(
          autoUpdaterClient: _FakeAutoUpdaterClient(),
          appcastProbeClient: _FakeProbeHarness().client,
          feedUrlResolver: () => 'https://example.com/appcast.xml',
          preferencesStore: prefsStore,
          supportsNativeUpdates: () => true,
        );

        await controller.initialize();
        await Future<void>.delayed(Duration.zero);

        check(controller.state.status).equals(WindowsAutoUpdateStatus.checking);
      },
    );

    test(
      'should restore persisted last check while a new probe starts',
      () async {
        final checkedAt = DateTime(2026, 5, 5, 12);
        final prefsStore = await _createPreferencesStore();
        await prefsStore.persistWindowsAutoUpdateDiagnostic(
          WindowsAutoUpdateDiagnostic(
            status: WindowsAutoUpdateStatus.upToDate,
            headline: 'Este build ja esta atualizado.',
            details: 'Nenhuma release mais nova foi encontrada.',
            feedUrl: 'https://example.com/appcast.xml',
            lastCheckedAt: checkedAt,
          ),
        );

        final controller = WindowsAutoUpdateController(
          autoUpdaterClient: _FakeAutoUpdaterClient(),
          appcastProbeClient: _FakeProbeHarness().client,
          feedUrlResolver: () => 'https://example.com/appcast.xml',
          preferencesStore: prefsStore,
          supportsNativeUpdates: () => true,
        );

        await controller.initialize();
        await Future<void>.delayed(Duration.zero);

        check(controller.state.status).equals(WindowsAutoUpdateStatus.checking);
        check(controller.state.lastCheckedAt).equals(checkedAt);
      },
    );
  });
}

final class _FakeAutoUpdaterClient implements AutoUpdaterClient {
  final List<UpdaterListener> listeners = <UpdaterListener>[];
  final List<String> feedUrls = <String>[];
  final List<int> scheduledIntervals = <int>[];
  final List<bool> checkCalls = <bool>[];

  @override
  void addListener(UpdaterListener listener) {
    listeners.add(listener);
  }

  @override
  Future<void> checkForUpdates({required bool inBackground}) async {
    checkCalls.add(inBackground);
  }

  @override
  void removeListener(UpdaterListener listener) {
    listeners.remove(listener);
  }

  @override
  Future<void> setFeedUrl(String feedUrl) async {
    feedUrls.add(feedUrl);
  }

  @override
  Future<void> setScheduledCheckInterval(int intervalInSeconds) async {
    scheduledIntervals.add(intervalInSeconds);
  }
}

final class _FakeProbeHarness {
  _FakeProbeHarness({
    this.nextResult = const AppcastProbeResult.success(),
  });

  final AppcastProbeResult nextResult;
  final List<String> feedUrls = <String>[];

  Future<AppcastProbeResult> _invoke({required String feedUrl}) async {
    feedUrls.add(feedUrl);
    return nextResult;
  }

  AppcastProbeClient get client => _invoke;
}

final class _SlowProbeHarness {
  final List<String> feedUrls = <String>[];
  final Completer<void> _gate = Completer<void>();

  Future<AppcastProbeResult> _invoke({required String feedUrl}) async {
    feedUrls.add(feedUrl);
    await _gate.future;
    return const AppcastProbeResult.success();
  }

  AppcastProbeClient get client => _invoke;

  void complete() {
    if (!_gate.isCompleted) {
      _gate.complete();
    }
  }
}

Future<AppUserPreferencesStore> _createPreferencesStore() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  return AppUserPreferencesStore(prefs);
}
