import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads [AppLocalizations] from the element that hosts [T].
///
/// Call after pumping a tree that includes [AppLocalizations.localizationsDelegates]
/// and an instance of [T]. Throws if [T] is not found or localization is missing.
AppLocalizations localizedFromWidget<T extends Widget>(WidgetTester tester) {
  return AppLocalizations.of(tester.element(find.byType(T)));
}
