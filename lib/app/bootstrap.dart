import 'dart:async';

import 'package:colmeia/app/app.dart';
import 'package:colmeia/app/router/app_router.dart';
import 'package:colmeia/app/socket_lifecycle_observer.dart';
import 'package:colmeia/app/theme/app_theme_mode_controller.dart';
import 'package:colmeia/app/web_url_strategy.dart';
import 'package:colmeia/core/config/agent_bridge_transport.dart';
import 'package:colmeia/core/config/app_dotenv_loader.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/logging/app_logger.dart';
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

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureColmeiaWebUrlStrategy();
  AppLogger.configureForRuntime();
  await loadAppDotenv();

  // Boot-time observability: surface the resolved bridge transport
  // immediately so triaging "why is the app still on REST?" does not
  // require a Sentry round-trip — the answer shows up in the very
  // first lines of `flutter logs`. Cheap (single info line per cold
  // start) and pays for itself on every env-flip rollout.
  final resolvedTransport = AppEnvironment.agentBridgeTransport;
  AppLogger.info(
    'Bootstrap: agent bridge transport resolved',
    context: <String, Object?>{
      'component': 'bootstrap',
      'transport': resolvedTransport.name,
      'socketRelayEnabled': AppEnvironment.socketRelayEnabled,
      'socketPresenceListenerEnabled':
          AppEnvironment.socketPresenceListenerEnabled,
      'socketWarmUpAfterLogin': AppEnvironment.socketWarmUpAfterLogin,
    },
  );

  await runAppWithOptionalSentry(() async {
    await setupDependencies();
    await getIt<WindowsAutoUpdateController>().initialize();
    if (resolvedTransport == AgentBridgeTransport.socket) {
      // Activate metrics only when the socket channel is enabled. On REST
      // builds the listener stays unregistered (lazy singleton).
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
          // Only materialise ConsumerSocketConnection on socket builds.
          // REST-only builds do not need to wire (or even instantiate) the
          // socket stack here; the observer becomes a no-op for the
          // socket-bound actions when the connection is null.
          final transport = AppEnvironment.agentBridgeTransport;
          final connection = transport == AgentBridgeTransport.socket
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
