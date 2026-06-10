import 'dart:async';

import 'package:colmeia/app/app.dart';
import 'package:colmeia/app/bootstrap_failure_app.dart';
import 'package:colmeia/app/preferences/app_user_experience_preferences_controller.dart';
import 'package:colmeia/app/router/app_router.dart';
import 'package:colmeia/app/socket_lifecycle_observer.dart';
import 'package:colmeia/app/theme/app_theme_mode_controller.dart';
import 'package:colmeia/app/web_url_strategy.dart';
import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/config/agent_bridge_transport.dart';
import 'package:colmeia/core/config/app_dotenv_loader.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/observability/app_global_error_handlers.dart';
import 'package:colmeia/core/observability/sentry_bootstrap.dart'
    show
        configureSentryBootScope,
        runAppWithOptionalSentry,
        sentryProvidesBootstrapZoneGuarding,
        shouldInitializeSentry;
import 'package:colmeia/core/observability/socket/socket_metrics_listener.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/relay/relay_conversation_pre_warmer.dart';
import 'package:colmeia/core/storage/app_hive.dart';
import 'package:colmeia/core/update/windows_auto_update_controller.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_map_static_data.dart';
import 'package:colmeia/shared/widgets/export/pdf_export_font_cache.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

@visibleForTesting
void logResolvedAgentBridgeTransportAtBootstrap() {
  final rawTransport = AppEnvironment.agentBridgeTransportRaw;
  final parsedTransport = AgentBridgeTransport.tryParse(rawTransport);
  final resolvedTransport =
      parsedTransport ?? AppEnvironment.agentBridgeTransport;
  final hasExplicitInvalidTransport =
      rawTransport.trim().isNotEmpty && parsedTransport == null;

  if (hasExplicitInvalidTransport) {
    AppLogger.warning(
      'Bootstrap: invalid AGENT_BRIDGE_TRANSPORT value; falling back to default transport',
      context: <String, Object?>{
        'component': 'bootstrap',
        'rawTransport': rawTransport,
        'resolvedTransport': resolvedTransport.wireValue,
        'fallbackApplied': true,
      },
    );
  }

  AppLogger.info(
    'Bootstrap: agent bridge transport resolved',
    context: <String, Object?>{
      'component': 'bootstrap',
      'transport': resolvedTransport.wireValue,
      'rawTransport': rawTransport.isEmpty ? null : rawTransport,
      'socketRelayEnabled': AppEnvironment.socketRelayEnabled,
      'socketPresenceListenerEnabled':
          AppEnvironment.socketPresenceListenerEnabled,
      'socketWarmUpAfterLogin': AppEnvironment.socketWarmUpAfterLogin,
    },
  );
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  configureColmeiaWebUrlStrategy();
  AppLogger.configureForRuntime();
  installGlobalErrorHandlers();
  installBrandedErrorWidget();

  if (sentryProvidesBootstrapZoneGuarding) {
    await _runBootstrapOrShowFailure();
    return;
  }

  await runZonedGuarded(
    _runBootstrapOrShowFailure,
    _onBootstrapZoneError,
  );
}

void _onBootstrapZoneError(Object error, StackTrace stack) {
  AppLogger.error(
    'Uncaught bootstrap zone error',
    context: const <String, Object?>{
      'component': 'bootstrap',
    },
    error: error,
    stackTrace: stack,
  );
}

Future<void> _runBootstrapOrShowFailure() async {
  await runAppWithOptionalSentry(_executeBootstrapPhases);
}

Future<void> _executeBootstrapPhases() async {
  try {
    await loadAppDotenv();

    // Boot-time observability: surface the resolved bridge transport
    // immediately so triaging "why is the app still on REST?" does not
    // require a Sentry round-trip — the answer shows up in the very
    // first lines of `flutter logs`. Cheap (single info line per cold
    // start) and pays for itself on every env-flip rollout.
    logResolvedAgentBridgeTransportAtBootstrap();
  } on Object catch (error, stackTrace) {
    await _handleBootstrapFailure(
      phase: 'load_dotenv',
      error: error,
      stackTrace: stackTrace,
    );
    return;
  }

  try {
    await _bootstrapAppRunner();
  } on Object catch (error, stackTrace) {
    await _handleBootstrapFailure(
      phase: 'setup_dependencies',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

Future<void> _bootstrapAppRunner() async {
    await setupDependencies();
    await configureSentryBootScope();
    unawaited(
      AppBrazilMapStaticData.precacheBrazilUfGeoJsonAsset().catchError(
        (Object error, StackTrace st) {
          AppLogger.warning(
            'Brazil UF GeoJSON precache failed',
            context: const <String, Object?>{
              'operation':
                  'AppBrazilMapStaticData.precacheBrazilUfGeoJsonAsset',
            },
            error: error,
            stackTrace: st,
          );
          return false;
        },
      ),
    );
    unawaited(
      PdfExportFontCache.warmFonts().catchError((Object error, StackTrace st) {
        AppLogger.warning(
          'PDF export font warm-up failed',
          context: const <String, Object?>{
            'operation': 'PdfExportFontCache.warmFonts',
          },
          error: error,
          stackTrace: st,
        );
      }),
    );
    unawaited(
      getIt<WindowsAutoUpdateController>().initialize().catchError((
        Object error,
        StackTrace st,
      ) {
        AppLogger.warning(
          'Windows auto-update initialization failed',
          context: const <String, Object?>{
            'operation': 'WindowsAutoUpdateController.initialize',
          },
          error: error,
          stackTrace: st,
        );
      }),
    );
    if (AppEnvironment.consumerSocketLifecycleEnabled) {
      getIt<SocketMetricsListener>().start();
    }
    // Touch the relay pre-warmer so its connection-state subscription
    // attaches before the first `connect()` lands. It is a lazy singleton
    // gated by relay availability inside `injector_client_agents.dart`, so
    // REST-only or relay-disabled builds skip this entirely.
    if (getIt.isRegistered<RelayConversationPreWarmer>()) {
      getIt<RelayConversationPreWarmer>();
    }
    runApp(const ColmeiaBootstrap());
}

Future<void> _handleBootstrapFailure({
  required String phase,
  required Object error,
  required StackTrace stackTrace,
}) async {
  AppLogger.error(
    'Bootstrap failed',
    context: <String, Object?>{
      'component': 'bootstrap',
      'bootstrap_phase': phase,
    },
    error: error,
    stackTrace: stackTrace,
  );
  await _captureBootstrapException(
    phase: phase,
    error: error,
    stackTrace: stackTrace,
  );
  final offersHiveRecovery = _isHiveRecoverableBootstrapPhase(phase);
  runApp(
    BootstrapFailureApp(
      onRetry: _retryBootstrap,
      onClearCacheAndRetry:
          offersHiveRecovery ? _clearLocalCacheAndRetryBootstrap : null,
    ),
  );
}

bool _isHiveRecoverableBootstrapPhase(String phase) =>
    phase == 'setup_dependencies';

Future<void> _clearLocalCacheAndRetryBootstrap() async {
  await AppHive.clearLocalKvCacheForRecovery();
  await _retryBootstrap();
}

Future<void> _retryBootstrap() async {
  if (getIt.isRegistered<AppCacheStore>()) {
    await getIt.reset();
  }
  await _runBootstrapOrShowFailure();
}

Future<void> _captureBootstrapException({
  required String phase,
  required Object error,
  required StackTrace stackTrace,
}) async {
  if (!shouldInitializeSentry) {
    return;
  }

  await Sentry.captureException(
    error,
    stackTrace: stackTrace,
    withScope: (scope) {
      unawaited(scope.setTag('bootstrap_phase', phase));
    },
  );
}

/// GetIt lazy singletons must not be [ChangeNotifier.dispose]d by Provider
/// when the widget tree is torn down (tests, hot restart). Process lifetime
/// is owned by GetIt reset, not by [ColmeiaBootstrap] mount cycles.
void _noopProviderDispose<T>(BuildContext _, T _) {}

class ColmeiaBootstrap extends StatelessWidget {
  const ColmeiaBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ListenableProvider<AuthController>(
          create: (_) {
            final controller = getIt<AuthController>();
            unawaited(
              controller.initialize().catchError((Object error, StackTrace st) {
                AppLogger.error(
                  'Auth controller initialize failed',
                  context: const <String, Object?>{
                    'operation': 'initializeAuthController',
                  },
                  error: error,
                  stackTrace: st,
                );
              }),
            );
            return controller;
          },
          dispose: _noopProviderDispose,
        ),
        ListenableProvider<CurrentUserContextController>(
          create: (_) => getIt<CurrentUserContextController>(),
          dispose: _noopProviderDispose,
        ),
        ListenableProvider<AppThemeModeController>(
          create: (_) => getIt<AppThemeModeController>(),
          dispose: _noopProviderDispose,
        ),
        ListenableProvider<AppUserExperiencePreferencesController>(
          create: (_) => getIt<AppUserExperiencePreferencesController>(),
          dispose: _noopProviderDispose,
        ),
        Provider<GoRouter>(
          create: (context) {
            return AppRouter(
              context.read<AuthController>(),
              context.read<CurrentUserContextController>(),
            ).router;
          },
          dispose: (_, router) => router.dispose(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final transport = AppEnvironment.agentBridgeTransport;
          // Materialise the consumer socket for lifecycle when relay, socket
          // bridge, or realtime presence uses the `/consumers` namespace.
          final needsSocket = AppEnvironment.consumerSocketLifecycleEnabled;
          final connection = needsSocket
              ? getIt<ConsumerSocketConnection>()
              : null;
          return SocketLifecycleObserver(
            connection: connection,
            authGate: context.read<AuthController>(),
            transport: transport,
            warmUpAfterLogin: AppEnvironment.socketWarmUpAfterLogin,
            child: const ColmeiaApp(),
          );
        },
      ),
    );
  }
}
