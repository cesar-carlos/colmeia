import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/app/theme/app_theme_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ColmeiaApp extends StatelessWidget {
  const ColmeiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = context.read<GoRouter>();
    final themeMode = context.watch<AppThemeModeController>().themeMode;

    return MaterialApp.router(
      title: 'Colmeia',
      debugShowCheckedModeBanner: false,
      supportedLocales: const <Locale>[
        Locale('pt', 'BR'),
        Locale('en'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
