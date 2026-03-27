import 'package:checks/checks.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/auth/presentation/routes/auth_redirect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveAuthRedirect', () {
    test('should redirect guests to login for protected routes', () {
      check(
        resolveAuthRedirect(
          isAuthenticated: false,
          matchedRoute: AppRoute.dashboard,
        ),
      ).equals(AppRoute.login.path);
    });

    test('should keep guests on login route', () {
      check(
        resolveAuthRedirect(
          isAuthenticated: false,
          matchedRoute: AppRoute.login,
        ),
      ).isNull();
    });

    test('should redirect authenticated users away from login', () {
      check(
        resolveAuthRedirect(
          isAuthenticated: true,
          matchedRoute: AppRoute.login,
        ),
      ).equals(AppRoute.dashboard.path);
    });

    test('should keep authenticated users on protected routes', () {
      check(
        resolveAuthRedirect(
          isAuthenticated: true,
          matchedRoute: AppRoute.reportDetail,
        ),
      ).isNull();
    });
  });
}
