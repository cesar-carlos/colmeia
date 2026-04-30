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

    test('should resolve chart fullscreen route from location', () {
      check(AppRoute.fromLocation(AppRoute.chartFullscreen.path)).equals(
        AppRoute.chartFullscreen,
      );
      check(AppRoute.chartFullscreen.shellNavSelectionIndex).isNull();
    });

    test('should treat root path as dashboard home', () {
      check(AppRoute.fromLocation('/')).equals(AppRoute.dashboard);
      check(AppRoute.fromLocation('')).equals(AppRoute.dashboard);
    });

    test('should resolve placeholder shell paths', () {
      check(AppRoute.fromLocation('/sales')).equals(AppRoute.sales);
      check(AppRoute.fromLocation('/returns')).equals(AppRoute.returns);
      check(AppRoute.fromLocation('/finance')).equals(AppRoute.finance);
      check(AppRoute.fromLocation('/purchases')).equals(AppRoute.purchases);
      check(AppRoute.fromLocation('/inventory')).equals(AppRoute.inventory);
    });

    test('should resolve unknown paths to unmatched sentinel', () {
      check(AppRoute.fromLocation('/not-a-real-route')).equals(
        AppRoute.unmatched,
      );
    });

    test('should map agents detail to agents shell highlight index', () {
      check(AppRoute.agentsDetail.shellNavSelectionIndex).equals(
        AppRoute.agents.shellIndex,
      );
      check(AppRoute.agents.shellNavSelectionIndex).equals(
        AppRoute.agents.shellIndex,
      );
      check(AppRoute.dashboard.shellNavSelectionIndex).equals(0);
    });
  });
}
