import 'package:colmeia/core/localization/app_localizations_fallback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fallbackAppLocalizationsForPlatform returns a concrete delegate', () {
    final l10n = fallbackAppLocalizationsForPlatform();
    expect(l10n.shellAppBrandName, isNotEmpty);
  });
}
