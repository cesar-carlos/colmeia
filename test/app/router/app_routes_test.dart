import 'package:checks/checks.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';
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

    test('should resolve active shell paths', () {
      check(AppRoute.fromLocation('/sales')).equals(AppRoute.sales);
      check(AppRoute.fromLocation('/sales-monitoring')).equals(
        AppRoute.salesMonitoring,
      );
    });

    test('should keep sales monitoring below dashboard in shell order', () {
      check(AppRoute.shellRoutes).deepEquals(<AppRoute>[
        AppRoute.dashboard,
        AppRoute.salesMonitoring,
        AppRoute.sales,
        AppRoute.agents,
        AppRoute.settings,
      ]);
      check(AppRoute.dashboard.shellNavSelectionIndex).equals(0);
      check(AppRoute.salesMonitoring.shellNavSelectionIndex).equals(1);
      check(AppRoute.sales.shellNavSelectionIndex).equals(2);
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
    });

    test('should resolve shell root route for shell details and roots', () {
      check(AppRoute.salesCard.shellRootRoute).equals(AppRoute.sales);
      check(AppRoute.dashboardStore.shellRootRoute).equals(AppRoute.dashboard);
      check(AppRoute.agentsDetail.shellRootRoute).equals(AppRoute.agents);
      check(AppRoute.sales.shellRootRoute).equals(AppRoute.sales);
      check(AppRoute.salesMonitoring.shellRootRoute).equals(
        AppRoute.salesMonitoring,
      );
      check(AppRoute.login.shellRootRoute).isNull();
    });

    test('should require sales permission for sales monitoring', () {
      check(AppRoute.salesMonitoring.requiredPermission).equals(
        UserPermission.viewSales,
      );
    });

    test('should resolve shell navigation target for drawer and rail taps', () {
      check(
        AppRoute.resolveShellNavigationTarget(
          current: AppRoute.sales,
          currentLocation: AppRoute.sales.path,
          tapped: AppRoute.sales,
        ),
      ).isNull();
      check(
        AppRoute.resolveShellNavigationTarget(
          current: AppRoute.salesCard,
          currentLocation: '/sales/produto_rank_lucro',
          tapped: AppRoute.sales,
        ),
      ).equals(AppRoute.sales);
      check(
        AppRoute.resolveShellNavigationTarget(
          current: AppRoute.dashboardStore,
          currentLocation: '/dashboard/store/03',
          tapped: AppRoute.dashboard,
        ),
      ).equals(AppRoute.dashboard);
      check(
        AppRoute.resolveShellNavigationTarget(
          current: AppRoute.agentsDetail,
          currentLocation: '/agents/42',
          tapped: AppRoute.agents,
        ),
      ).equals(AppRoute.agents);
      check(
        AppRoute.resolveShellNavigationTarget(
          current: AppRoute.settings,
          currentLocation: '/settings/component-demos/app-buttons-demo',
          tapped: AppRoute.settings,
        ),
      ).equals(AppRoute.settings);
      check(
        AppRoute.resolveShellNavigationTarget(
          current: AppRoute.salesCard,
          currentLocation: '/sales/produto_rank_lucro',
          tapped: AppRoute.dashboard,
        ),
      ).equals(AppRoute.dashboard);
    });
  });
}
