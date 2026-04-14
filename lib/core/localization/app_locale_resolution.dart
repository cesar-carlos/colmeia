import 'package:flutter/material.dart';

/// Resolves [locale] against [supported], preferring `pt_BR` when the device
/// reports Portuguese without a country code.
///
/// When [locale] is null (observed on some web embeds), prefers `pt_BR` if
/// listed in [supported], otherwise falls back to the first supported locale
/// (typically `en`). Product is Brazil-first; change here if a global default
/// must differ.
Locale lookupColmeiaLocale(Locale? locale, Iterable<Locale> supported) {
  final supportedList = supported.toList();
  if (locale == null) {
    const preferred = Locale('pt', 'BR');
    for (final option in supportedList) {
      if (option == preferred) {
        return option;
      }
    }
    return supportedList.first;
  }
  for (final option in supportedList) {
    if (option == locale) {
      return option;
    }
  }
  if (locale.languageCode == 'pt') {
    Locale? matchBr;
    Locale? matchPt;
    for (final option in supportedList) {
      if (option.languageCode != 'pt') {
        continue;
      }
      if (option.countryCode == 'BR') {
        matchBr = option;
        break;
      }
      matchPt ??= option;
    }
    if (matchBr != null) {
      return matchBr;
    }
    if (matchPt != null) {
      return matchPt;
    }
  }
  return basicLocaleListResolution(<Locale>[locale], supportedList);
}
