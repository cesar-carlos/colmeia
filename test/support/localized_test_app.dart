import 'package:colmeia/app/theme/app_legacy_material_theme.dart';
import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/core/localization/app_locale_resolution.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

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
      builder: (context, child) => AppLegacyMaterialTheme(child: child!),
      theme: AppTheme.light(),
      locale: locale,
      localizationsDelegates: colmeiaLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }
}
