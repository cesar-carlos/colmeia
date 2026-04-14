import 'dart:ui' show PlatformDispatcher;

import 'package:colmeia/core/localization/app_locale_resolution.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:colmeia/l10n/app_localizations_pt.dart';

/// Resolves `AppLocalizations` when no widget build context is available
/// (e.g. overview controller before the page attaches), using the platform
/// locale and the same rules as `lookupColmeiaLocale`.
///
/// Mirrors the generated `lookupAppLocalizations` mapping without throwing.
AppLocalizations fallbackAppLocalizationsForPlatform() {
  final resolved = lookupColmeiaLocale(
    PlatformDispatcher.instance.locale,
    AppLocalizations.supportedLocales,
  );
  if (resolved.languageCode == 'pt' && resolved.countryCode == 'BR') {
    return AppLocalizationsPtBr();
  }
  switch (resolved.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
    default:
      return AppLocalizationsEn();
  }
}
