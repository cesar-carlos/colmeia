import 'dart:async';

import 'package:auto_updater/auto_updater.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/preferences/app_user_preferences_store.dart';
import 'package:colmeia/core/update/app_auto_update_support.dart';
import 'package:colmeia/core/update/appcast_probe_client.dart';
import 'package:colmeia/core/update/auto_updater_client.dart';
import 'package:colmeia/core/update/windows_auto_update_diagnostic.dart';
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

  bool _initialized = false;
  bool _listenerRegistered = false;

  Future<void> initialize() async {
    if (_initialized) {
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
      await _autoUpdaterClient.setFeedUrl(_state.feedUrl);
      await _autoUpdaterClient.setScheduledCheckInterval(
        scheduledCheckIntervalInSeconds,
      );

      _initialized = true;
      _applyState(
        _state.copyWith(
          status: WindowsAutoUpdateStatus.idle,
          headline: 'Atualizacoes automaticas prontas neste build Windows.',
          details:
              'O feed oficial foi configurado e o app checara novas releases em background.',
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
      _setFailure(
        headline: 'Nao foi possivel inicializar o auto-update.',
        details: error.toString(),
      );
    }
  }

  Future<void> checkForUpdates({bool inBackground = false}) async {
    _refreshAvailability(notify: false);
    if (_state.availability != AppAutoUpdateAvailability.supported) {
      notifyListeners();
      return;
    }

    _ensureListenerRegistered();
    _applyState(
      _state.copyWith(
        status: WindowsAutoUpdateStatus.checking,
        headline: 'Verificando atualizacoes...',
        details: inBackground
            ? 'Checagem inicial em background em andamento.'
            : 'Consultando o feed oficial para encontrar uma release mais recente.',
      ),
    );

    try {
      final probeResult = await _appcastProbeClient(
        feedUrl: _state.feedUrl,
      );
      if (!probeResult.success) {
        _setFailure(
          headline: _headlineForProbeFailure(probeResult),
          details: probeResult.details,
        );
        return;
      }

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
      _setFailure(
        headline: 'Nao foi possivel verificar atualizacoes agora.',
        details: error.toString(),
      );
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
        headline: 'Atualizacao pronta para instalacao.',
        details:
            'O Windows concluira o processo quando o aplicativo for encerrado para aplicar a nova versao.',
        lastCheckedAt: DateTime.now(),
      ),
    );
  }

  @override
  void onUpdaterCheckingForUpdate(Appcast? appcast) {
    _applyState(
      _state.copyWith(
        status: WindowsAutoUpdateStatus.checking,
        headline: 'Verificando atualizacoes...',
        details: 'Consultando o feed oficial configurado para este build.',
      ),
    );
  }

  @override
  void onUpdaterError(UpdaterError? error) {
    _setFailure(
      headline: 'Nao foi possivel concluir a verificacao de atualizacoes.',
      details: error?.message,
    );
  }

  @override
  void onUpdaterUpdateAvailable(AppcastItem? appcastItem) {
    _applyState(
      _state.copyWith(
        status: WindowsAutoUpdateStatus.updateAvailable,
        headline: 'Nova versao encontrada.',
        details:
            'O fluxo nativo do Windows/WinSparkle assumiu o download da atualizacao para esta instalacao.',
        lastCheckedAt: DateTime.now(),
      ),
    );
  }

  @override
  void onUpdaterUpdateDownloaded(AppcastItem? appcastItem) {
    _applyState(
      _state.copyWith(
        status: WindowsAutoUpdateStatus.readyToInstall,
        headline: 'Atualizacao baixada.',
        details:
            'Feche o aplicativo quando o updater solicitar para concluir a substituicao da versao atual.',
        lastCheckedAt: DateTime.now(),
      ),
    );
  }

  @override
  void onUpdaterUpdateNotAvailable(UpdaterError? error) {
    _applyState(
      _state.copyWith(
        status: WindowsAutoUpdateStatus.upToDate,
        headline: 'Este build ja esta atualizado.',
        details:
            'Nenhuma release mais nova foi encontrada no appcast oficial neste momento.',
        lastCheckedAt: DateTime.now(),
      ),
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
            status: _initialized
                ? _state.status
                : hasDiagnostic
                ? _state.status
                : WindowsAutoUpdateStatus.unavailable,
            headline: _initialized
                ? _state.headline
                : hasDiagnostic
                ? _state.headline
                : 'Atualizacoes automaticas disponiveis para este build.',
            details: _initialized
                ? _state.details
                : hasDiagnostic
                ? _state.details
                : 'O app esta pronto para usar o feed oficial assim que a inicializacao terminar.',
            feedUrl: normalizedFeedUrl,
          ),
          notify: notify,
        );
      case AppAutoUpdateAvailability.feedUrlMissing:
        _applyState(
          WindowsAutoUpdateState(
            availability: availability,
            status: WindowsAutoUpdateStatus.unavailable,
            headline: 'Atualizacoes automaticas indisponiveis neste build.',
            details:
                'Este instalador foi gerado sem o feed oficial de atualizacoes. Instale uma versao publicada pelo GitHub Releases ou gere o instalador com o feed configurado.',
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
            headline: 'Feed de atualizacao invalido.',
            details:
                'Este instalador foi gerado com um feed de atualizacoes invalido. Gere novamente o instalador com uma URL appcast .xml valida.',
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

  void _setFailure({
    required String headline,
    String? details,
  }) {
    _applyState(
      _state.copyWith(
        status: WindowsAutoUpdateStatus.failed,
        headline: headline,
        details: details ?? 'Revise a conectividade e tente novamente.',
        lastCheckedAt: DateTime.now(),
      ),
    );
  }

  void _restorePersistedDiagnostic() {
    final diagnostic = _preferencesStore.windowsAutoUpdateDiagnostic;
    if (diagnostic == null) {
      return;
    }

    _state = WindowsAutoUpdateState(
      availability: _state.availability,
      status: diagnostic.status,
      headline: diagnostic.headline,
      details: diagnostic.details,
      feedUrl: diagnostic.feedUrl,
      lastCheckedAt: diagnostic.lastCheckedAt,
    );
  }

  void _applyState(
    WindowsAutoUpdateState nextState, {
    bool persistDiagnostic = true,
    bool notify = true,
  }) {
    _state = nextState;
    if (persistDiagnostic) {
      _persistDiagnostic(nextState);
    }
    if (notify) {
      notifyListeners();
    }
  }

  void _persistDiagnostic(WindowsAutoUpdateState state) {
    unawaited(
      _preferencesStore.persistWindowsAutoUpdateDiagnostic(
        WindowsAutoUpdateDiagnostic(
          status: state.status,
          headline: state.headline,
          details: state.details,
          feedUrl: state.feedUrl,
          lastCheckedAt: state.lastCheckedAt,
        ),
      ),
    );
  }

  String _headlineForProbeFailure(AppcastProbeResult probeResult) {
    return switch (probeResult.failureKind) {
      AppcastProbeFailureKind.invalidUrl => 'Feed de atualizacao invalido.',
      AppcastProbeFailureKind.timeout =>
        'O feed oficial nao respondeu a tempo.',
      AppcastProbeFailureKind.httpError =>
        'O feed oficial nao esta acessivel no momento.',
      AppcastProbeFailureKind.invalidPayload =>
        'O feed oficial respondeu com conteudo inesperado.',
      AppcastProbeFailureKind.network =>
        'Nao foi possivel acessar o feed oficial agora.',
      null => 'Nao foi possivel verificar atualizacoes agora.',
    };
  }

  static bool _defaultSupportsNativeUpdates() =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
}
