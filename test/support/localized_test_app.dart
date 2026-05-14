import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class LocalizedTestApp extends StatelessWidget {
  const LocalizedTestApp({
    required this.child,
    super.key,
    this.locale = const Locale('pt', 'BR'),
  });

  final Widget child;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }
}
