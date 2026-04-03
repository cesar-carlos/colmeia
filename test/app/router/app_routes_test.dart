import 'package:checks/checks.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRoute', () {
    test('should prefer the most specific auth route', () {
      check(
        AppRoute.fromLocation(AppRoute.registrationStatus.path),
      ).equals(AppRoute.registrationStatus);
    });

    test('should resolve nested dashboard route from location', () {
      check(AppRoute.fromLocation('/dashboard/store/03')).equals(
        AppRoute.dashboardStore,
      );
    });

    test('should resolve settings route from location', () {
      check(AppRoute.fromLocation('/settings')).equals(AppRoute.settings);
    });
  });
}
