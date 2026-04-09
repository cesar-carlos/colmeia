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
          canAccessRoute: false,
          matchedRoute: AppRoute.dashboard,
          isUserContextLoading: false,
        ),
      ).equals(AppRoute.login.path);
    });

    test('should keep guests on login route', () {
      check(
        resolveAuthRedirect(
          isAuthenticated: false,
          canAccessRoute: true,
          matchedRoute: AppRoute.login,
          isUserContextLoading: false,
        ),
      ).isNull();
    });

    test('should redirect authenticated users away from login', () {
      check(
        resolveAuthRedirect(
          isAuthenticated: true,
          canAccessRoute: true,
          matchedRoute: AppRoute.login,
          isUserContextLoading: false,
        ),
      ).equals(AppRoute.settings.path);
    });

    test('should keep authenticated users on protected routes', () {
      check(
        resolveAuthRedirect(
          isAuthenticated: true,
          canAccessRoute: true,
          matchedRoute: AppRoute.settings,
          isUserContextLoading: false,
        ),
      ).isNull();
    });

    test(
      'should defer dashboard access denial while user context is loading',
      () {
        check(
          resolveAuthRedirect(
            isAuthenticated: true,
            canAccessRoute: false,
            matchedRoute: AppRoute.dashboard,
            isUserContextLoading: true,
          ),
        ).isNull();
        check(
          resolveAuthRedirect(
            isAuthenticated: true,
            canAccessRoute: false,
            matchedRoute: AppRoute.dashboardStore,
            isUserContextLoading: true,
          ),
        ).isNull();
      },
    );

    test(
      'should send authenticated users to settings when dashboard is denied '
      'after context resolved',
      () {
        check(
          resolveAuthRedirect(
            isAuthenticated: true,
            canAccessRoute: false,
            matchedRoute: AppRoute.dashboard,
            isUserContextLoading: false,
          ),
        ).equals(AppRoute.settings.path);
      },
    );
  });
}
