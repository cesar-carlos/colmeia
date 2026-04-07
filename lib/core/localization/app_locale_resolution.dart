import 'package:flutter/material.dart';

/// Resolves [locale] against [supported], preferring `pt_BR` when the device
/// reports Portuguese without a country code.
Locale lookupColmeiaLocale(Locale? locale, Iterable<Locale> supported) {
  final supportedList = supported.toList();
  if (locale == null) {
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
