import 'dart:async';

import 'package:auto_updater/auto_updater.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/preferences/app_user_preferences_store.dart';
import 'package:colmeia/core/update/app_auto_update_support.dart';
import 'package:colmeia/core/update/appcast_probe_client.dart';
import 'package:colmeia/core/update/auto_updater_client.dart';
import 'package:colmeia/core/update/windows_auto_update_diagnostic.dart';
import 'package:colmeia/core/update/windows_auto_update_messages.dart';
import 'package:colmeia/core/update/windows_auto_update_state.dart';
import 'package:flutter/foundation.dart';

class WindowsAutoUpdateController extends ChangeNotifier with UpdaterListener {
  WindowsAutoUpdateController({
    required AutoUpdaterClient autoUpdaterClient,
    required AppcastProbeClient appcastProbeClient,
    required String Function() feedUrlResolver,
    required AppUserPreferencesStore preferencesStore,
    bool Function()? supportsNativeUpdates,
  }) : _autoUpdaterClient = autoUpdaterClient,
       _appcastProbeClient = appcastProbeClient,
       _feedUrlResolver = feedUrlResolver,
       _preferencesStore = preferencesStore,
       _supportsNativeUpdates =
           supportsNativeUpdates ?? _defaultSupportsNativeUpdates;

  static const int scheduledCheckIntervalInSeconds = 3600;

  final AutoUpdaterClient _autoUpdaterClient;
  final AppcastProbeClient _appcastProbeClient;
  final String Function() _feedUrlResolver;
  final AppUserPreferencesStore _preferencesStore;
  final bool Function() _supportsNativeUpdates;

  WindowsAutoUpdateState _state = const WindowsAutoUpdateState.initial();
  WindowsAutoUpdateState get state => _state;

  bool _listenerRegistered = false;
  bool _checkInFlight = false;
  Future<void> _persistenceQueue = Future<void>.value();
  Future<void>? _nativeConfigurationFuture;

  bool get _isInitialized => _state.isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _restorePersistedDiagnostic();
    _refreshAvailability(notify: false);
    if (_state.availability != AppAutoUpdateAvailability.supported) {
      notifyListeners();
      return;
    }

    _ensureListenerRegistered();

    try {
      await _ensureNativeUpdaterConfigured();
      _applyState(
        _state.copyWith(
          status: WindowsAutoUpdateStatus.idle,
          headline: WindowsAutoUpdateMessages.initReadyHeadline,
          details: WindowsAutoUpdateMessages.initReadyDetails,
        ),
      );

      unawaited(checkForUpdates(inBackground: true));
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Windows auto-update initialization failed',
        context: <String, Object?>{
          'component': 'windows_auto_update_controller',
          'feedUrl': _state.feedUrl,
        },
        error: error,
        stackTrace: stackTrace,
      );
      await _setFailure(
        headline: WindowsAutoUpdateMessages.initFailedHeadline,
        details: WindowsAutoUpdateMessages.initFailedDetails,
      );
    }
  }

  Future<void> checkForUpdates({bool inBackground = false}) async {
    if (_checkInFlight) {
      return;
    }

    _refreshAvailability(notify: false);
    if (_state.availability != AppAutoUpdateAvailability.supported) {
      notifyListeners();
      return;
    }

    _checkInFlight = true;
    _ensureListenerRegistered();

    if (!_isInitialized) {
      try {
        await _ensureNativeUpdaterConfigured();
      } on Object catch (error, stackTrace) {
        AppLogger.error(
          'Windows auto-update partial initialization failed',
          context: <String, Object?>{
            'component': 'windows_auto_update_controller',
            'feedUrl': _state.feedUrl,
            'inBackground': inBackground,
          },
          error: error,
          stackTrace: stackTrace,
        );
        await _setFailure(
          headline: WindowsAutoUpdateMessages.initFailedHeadline,
          details: WindowsAutoUpdateMessages.initFailedDetails,
        );
      }
      if (!_isInitialized) {
        _checkInFlight = false;
        return;
      }
    }

    _applyState(
      _state.copyWith(
        status: WindowsAutoUpdateStatus.checking,
        headline: WindowsAutoUpdateMessages.checkingHeadline,
        details: inBackground
            ? WindowsAutoUpdateMessages.checkingDetailsBackground
            : WindowsAutoUpdateMessages.checkingDetailsForeground,
      ),
    );

    try {
      final probeResult = await _appcastProbeClient(
        feedUrl: _state.feedUrl,
      );
      if (!probeResult.success) {
        await _setFailure(
          headline: _headlineForProbeFailure(probeResult),
          details:
              probeResult.details ??
              WindowsAutoUpdateMessages.genericRetryDetails,
        );
        return;
      }

      if (!probeResult.hasReleases) {
        await _applyFeedWithoutReleasesState();
        return;
      }

      // WinSparkle fetches the appcast again; the Dio probe above only gates
      // empty feeds and connectivity before delegating to the native updater.
      await _autoUpdaterClient.checkForUpdates(inBackground: inBackground);
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Windows auto-update check failed',
        context: <String, Object?>{
          'component': 'windows_auto_update_controller',
          'feedUrl': _state.feedUrl,
          'inBackground': inBackground,
        },
        error: error,
        stackTrace: stackTrace,
      );
      await _setFailure(
        headline: WindowsAutoUpdateMessages.checkFailedHeadline,
        details: WindowsAutoUpdateMessages.checkFailedDetails,
      );
    } finally {
      _checkInFlight = false;
    }
  }

  @override
  void dispose() {
    if (_listenerRegistered) {
      _autoUpdaterClient.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onUpdaterBeforeQuitForUpdate(AppcastItem? appcastItem) {
    _applyState(
      _state.copyWith(
        status: WindowsAutoUpdateStatus.readyToInstall,
        headline: WindowsAutoUpdateMessages.readyToInstallHeadline,
        details: WindowsAutoUpdateMessages.readyToInstallDetails,
        lastCheckedAt: DateTime.now(),
      ),
    );
  }

  @override
  void onUpdaterCheckingForUpdate(Appcast? appcast) {
    if (_checkInFlight) {
      return;
    }
    _applyState(
      _state.copyWith(
        status: WindowsAutoUpdateStatus.checking,
        headline: WindowsAutoUpdateMessages.checkingHeadline,
        details: WindowsAutoUpdateMessages.checkingDetailsNative,
      ),
    );
  }

  @override
  void onUpdaterError(UpdaterError? error) {
    AppLogger.error(
      'Windows auto-update native updater error',
      context: <String, Object?>{
        'component': 'windows_auto_update_controller',
        'feedUrl': _state.feedUrl,
        'updaterMessage': error?.message,
      },
      error: error,
    );
    unawaited(
      _setFailure(
        headline: WindowsAutoUpdateMessages.updaterErrorHeadline,
        details: WindowsAutoUpdateMessages.updaterErrorDetails,
      ),
    );
  }

  @override
  void onUpdaterUpdateAvailable(AppcastItem? appcastItem) {
    _applyState(
      _state.copyWith(
        status: WindowsAutoUpdateStatus.updateAvailable,
        headline: WindowsAutoUpdateMessages.updateAvailableHeadline,
        details: WindowsAutoUpdateMessages.updateAvailableDetails,
        lastCheckedAt: DateTime.now(),
      ),
    );
  }

  @override
  void onUpdaterUpdateDownloaded(AppcastItem? appcastItem) {
    _applyState(
      _state.copyWith(
        status: WindowsAutoUpdateStatus.readyToInstall,
        headline: WindowsAutoUpdateMessages.updateDownloadedHeadline,
        details: WindowsAutoUpdateMessages.updateDownloadedDetails,
        lastCheckedAt: DateTime.now(),
      ),
    );
  }

  @override
  void onUpdaterUpdateNotAvailable(UpdaterError? error) {
    if (error != null) {
      AppLogger.error(
        'Windows auto-update reported not available with error',
        context: <String, Object?>{
          'component': 'windows_auto_update_controller',
          'feedUrl': _state.feedUrl,
          'updaterMessage': error.message,
        },
        error: error,
      );
      unawaited(
        _setFailure(
          headline: WindowsAutoUpdateMessages.updateNotAvailableErrorHeadline,
          details: WindowsAutoUpdateMessages.updateNotAvailableErrorDetails,
        ),
      );
      return;
    }

    unawaited(
      _applyUpToDateState(
        headline: WindowsAutoUpdateMessages.upToDateHeadline,
        details: WindowsAutoUpdateMessages.upToDateDetails,
      ),
    );
  }

  Future<void> _ensureNativeUpdaterConfigured() {
    if (_isInitialized) {
      return Future<void>.value();
    }

    return _nativeConfigurationFuture ??= _configureNativeUpdater().then((_) {
      if (!_isInitialized) {
        _applyState(
          _state.copyWith(isInitialized: true),
          notify: false,
        );
      }
    });
  }

  Future<void> _configureNativeUpdater() async {
    await _autoUpdaterClient.setFeedUrl(_state.feedUrl);
    await _autoUpdaterClient.setScheduledCheckInterval(
      scheduledCheckIntervalInSeconds,
    );
  }

  void _ensureListenerRegistered() {
    if (_listenerRegistered) {
      return;
    }
    _autoUpdaterClient.addListener(this);
    _listenerRegistered = true;
  }

  void _refreshAvailability({bool notify = true}) {
    final normalizedFeedUrl = AppAutoUpdateSupport.normalizeFeedUrl(
      _feedUrlResolver(),
    );
    final availability = AppAutoUpdateSupport.resolveAvailability(
      supportsNativeUpdates: _supportsNativeUpdates(),
      feedUrl: normalizedFeedUrl,
    );

    switch (availability) {
      case AppAutoUpdateAvailability.supported:
        final hasDiagnostic = _state.headline.isNotEmpty;
        _applyState(
          _state.copyWith(
            availability: availability,
            status: _isInitialized
                ? _state.status
                : hasDiagnostic
                ? _state.status
                : WindowsAutoUpdateStatus.unavailable,
            headline: _isInitialized
                ? _state.headline
                : hasDiagnostic
                ? _state.headline
                : WindowsAutoUpdateMessages.pendingInitHeadline,
            details: _isInitialized
                ? _state.details
                : hasDiagnostic
                ? _state.details
                : WindowsAutoUpdateMessages.pendingInitDetails,
            feedUrl: normalizedFeedUrl,
          ),
          notify: notify,
        );
      case AppAutoUpdateAvailability.feedUrlMissing:
        _applyState(
          WindowsAutoUpdateState(
            availability: availability,
            status: WindowsAutoUpdateStatus.unavailable,
            headline: WindowsAutoUpdateMessages.feedUrlMissingHeadline,
            details: WindowsAutoUpdateMessages.feedUrlMissingDetails,
            feedUrl: normalizedFeedUrl,
            lastCheckedAt: null,
          ),
          notify: notify,
        );
      case AppAutoUpdateAvailability.feedUrlInvalid:
        _applyState(
          WindowsAutoUpdateState(
            availability: availability,
            status: WindowsAutoUpdateStatus.unavailable,
            headline: WindowsAutoUpdateMessages.feedUrlInvalidHeadline,
            details: WindowsAutoUpdateMessages.feedUrlInvalidDetails,
            feedUrl: normalizedFeedUrl,
            lastCheckedAt: null,
          ),
          notify: notify,
        );
      case AppAutoUpdateAvailability.unsupportedPlatform:
        _applyState(
          const WindowsAutoUpdateState(
            availability: AppAutoUpdateAvailability.unsupportedPlatform,
            status: WindowsAutoUpdateStatus.unavailable,
            headline: '',
            details: null,
            feedUrl: '',
            lastCheckedAt: null,
          ),
          notify: notify,
          persistDiagnostic: false,
        );
    }
  }

  Future<void> _setFailure({
    required String headline,
    String? details,
  }) async {
    await _applyTerminalState(
      _state.copyWith(
        status: WindowsAutoUpdateStatus.failed,
        headline: headline,
        details: details ?? WindowsAutoUpdateMessages.genericRetryDetails,
        lastCheckedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _applyFeedWithoutReleasesState() async {
    await _applyTerminalState(
      _state.copyWith(
        status: WindowsAutoUpdateStatus.feedWithoutReleases,
        headline: WindowsAutoUpdateMessages.feedWithoutReleasesHeadline,
        details: WindowsAutoUpdateMessages.feedWithoutReleasesDetails,
        lastCheckedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _applyUpToDateState({
    required String headline,
    required String details,
  }) async {
    await _applyTerminalState(
      _state.copyWith(
        status: WindowsAutoUpdateStatus.upToDate,
        headline: headline,
        details: details,
        lastCheckedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _applyTerminalState(WindowsAutoUpdateState nextState) async {
    _state = nextState;
    await _schedulePersist(nextState);
    notifyListeners();
  }

  void _restorePersistedDiagnostic() {
    final diagnostic = _preferencesStore.windowsAutoUpdateDiagnostic;
    if (diagnostic == null) {
      return;
    }

    final currentFeedUrl = AppAutoUpdateSupport.normalizeFeedUrl(
      _feedUrlResolver(),
    );
    if (diagnostic.feedUrl != currentFeedUrl) {
      return;
    }

    final restoredStatus = switch (diagnostic.status) {
      WindowsAutoUpdateStatus.checking ||
      WindowsAutoUpdateStatus.updateAvailable ||
      WindowsAutoUpdateStatus.readyToInstall => WindowsAutoUpdateStatus.idle,
      _ => diagnostic.status,
    };

    _state = WindowsAutoUpdateState(
      availability: _state.availability,
      status: restoredStatus,
      headline: diagnostic.headline,
      details: diagnostic.details,
      feedUrl: diagnostic.feedUrl,
      lastCheckedAt: diagnostic.lastCheckedAt,
      isInitialized: _state.isInitialized,
    );
  }

  void _applyState(
    WindowsAutoUpdateState nextState, {
    bool persistDiagnostic = true,
    bool notify = true,
  }) {
    _state = nextState;
    if (persistDiagnostic) {
      unawaited(_schedulePersist(nextState));
    }
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _schedulePersist(WindowsAutoUpdateState state) {
    final operation = _persistenceQueue.then(
      (_) => _writeDiagnostic(state),
    );
    _persistenceQueue = operation.catchError((_) {});
    return operation;
  }

  Future<void> _writeDiagnostic(WindowsAutoUpdateState state) async {
    await _preferencesStore.persistWindowsAutoUpdateDiagnostic(
      WindowsAutoUpdateDiagnostic(
        status: state.status,
        headline: state.headline,
        details: state.details,
        feedUrl: state.feedUrl,
        lastCheckedAt: state.lastCheckedAt,
      ),
    );
  }

  String _headlineForProbeFailure(AppcastProbeResult probeResult) {
    return switch (probeResult.failureKind) {
      AppcastProbeFailureKind.invalidUrl =>
        WindowsAutoUpdateMessages.probeInvalidUrlHeadline,
      AppcastProbeFailureKind.timeout =>
        WindowsAutoUpdateMessages.probeTimeoutHeadline,
      AppcastProbeFailureKind.httpError =>
        WindowsAutoUpdateMessages.probeHttpErrorHeadline,
      AppcastProbeFailureKind.invalidPayload =>
        WindowsAutoUpdateMessages.probeInvalidPayloadHeadline,
      AppcastProbeFailureKind.network =>
        WindowsAutoUpdateMessages.probeNetworkHeadline,
      null => WindowsAutoUpdateMessages.probeGenericHeadline,
    };
  }

  static bool _defaultSupportsNativeUpdates() =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @visibleForTesting
  void debugSetStateForTests(WindowsAutoUpdateState state) {
    _applyState(state, persistDiagnostic: false);
  }
}
