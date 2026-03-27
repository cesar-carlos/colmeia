import 'dart:async';

import 'package:colmeia/app/app.dart';
import 'package:colmeia/app/router/app_router.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.configureForRuntime();
  await setupDependencies();

  runApp(const ColmeiaBootstrap());
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
            unawaited(controller.initialize());
            return controller;
          },
        ),
        ChangeNotifierProvider<CurrentUserContextController>(
          create: (_) => getIt<CurrentUserContextController>(),
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
      child: const ColmeiaApp(),
    );
  }
}
