import 'package:checks/checks.dart';
import 'package:colmeia/core/update/app_auto_update_support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppAutoUpdateSupport.resolveAvailability', () {
    test(
      'should return unsupportedPlatform outside native Windows updater',
      () {
        final availability = AppAutoUpdateSupport.resolveAvailability(
          supportsNativeUpdates: false,
          feedUrl: 'https://example.com/appcast.xml',
        );

        check(
          availability,
        ).equals(AppAutoUpdateAvailability.unsupportedPlatform);
      },
    );

    test('should return feedUrlMissing when feed is empty', () {
      final availability = AppAutoUpdateSupport.resolveAvailability(
        supportsNativeUpdates: true,
        feedUrl: '   ',
      );

      check(availability).equals(AppAutoUpdateAvailability.feedUrlMissing);
    });

    test('should return feedUrlInvalid when url is not xml', () {
      final availability = AppAutoUpdateSupport.resolveAvailability(
        supportsNativeUpdates: true,
        feedUrl: 'https://example.com/releases/latest',
      );

      check(availability).equals(AppAutoUpdateAvailability.feedUrlInvalid);
    });

    test('should accept xml feed urls with query string', () {
      final availability = AppAutoUpdateSupport.resolveAvailability(
        supportsNativeUpdates: true,
        feedUrl: 'https://example.com/appcast.xml?cb=123',
      );

      check(availability).equals(AppAutoUpdateAvailability.supported);
    });
  });
}
