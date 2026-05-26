import 'dart:async';

import 'package:colmeia/app/app.dart';
import 'package:colmeia/app/preferences/app_user_experience_preferences_controller.dart';
import 'package:colmeia/app/router/app_router.dart';
import 'package:colmeia/app/socket_lifecycle_observer.dart';
import 'package:colmeia/app/theme/app_theme_mode_controller.dart';
import 'package:colmeia/app/web_url_strategy.dart';
import 'package:colmeia/core/config/agent_bridge_transport.dart';
import 'package:colmeia/core/config/app_dotenv_loader.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/observability/app_global_error_handlers.dart';
import 'package:colmeia/core/observability/sentry_bootstrap.dart';
import 'package:colmeia/core/observability/socket/socket_metrics_listener.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/update/windows_auto_update_controller.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

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
  configureColmeiaWebUrlStrategy();
  AppLogger.configureForRuntime();
  installGlobalErrorHandlers();
  installBrandedErrorWidget();
  await loadAppDotenv();

  // Boot-time observability: surface the resolved bridge transport
  // immediately so triaging "why is the app still on REST?" does not
  // require a Sentry round-trip — the answer shows up in the very
  // first lines of `flutter logs`. Cheap (single info line per cold
  // start) and pays for itself on every env-flip rollout.
  logResolvedAgentBridgeTransportAtBootstrap();

  await runAppWithOptionalSentry(() async {
    await setupDependencies();
    unawaited(
      getIt<WindowsAutoUpdateController>()
          .initialize()
          .catchError((Object error, StackTrace st) {
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
    runApp(const ColmeiaBootstrap());
  });
}

class ColmeiaBootstrap extends StatelessWidget {
  const ColmeiaBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<AuthController>(
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
        ),
        ChangeNotifierProvider<CurrentUserContextController>(
          create: (_) => getIt<CurrentUserContextController>(),
        ),
        ChangeNotifierProvider<AppThemeModeController>(
          create: (_) => getIt<AppThemeModeController>(),
        ),
        ChangeNotifierProvider<AppUserExperiencePreferencesController>(
          create: (_) => getIt<AppUserExperiencePreferencesController>(),
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
