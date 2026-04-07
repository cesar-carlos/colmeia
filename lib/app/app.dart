import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/app/theme/app_theme_mode_controller.dart';
import 'package:colmeia/core/localization/app_locale_resolution.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
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
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: lookupColmeiaLocale,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
