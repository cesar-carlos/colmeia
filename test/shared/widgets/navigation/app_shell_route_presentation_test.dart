import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/l10n/app_localizations_pt.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_route_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsPt();

  group('appShellRouteLabel', () {
    test('should map dashboard variants to shell label', () {
      expect(
        appShellRouteLabel(AppRoute.dashboard, l10n),
        l10n.shellNavDashboardLabel,
      );
      expect(
        appShellRouteLabel(AppRoute.dashboardStore, l10n),
        l10n.shellNavDashboardLabel,
      );
    });

    test('should map settings to shell label', () {
      expect(
        appShellRouteLabel(AppRoute.settings, l10n),
        l10n.shellNavSettingsLabel,
      );
    });

    test('should map active shell routes to shell labels', () {
      expect(appShellRouteLabel(AppRoute.sales, l10n), l10n.shellNavSalesLabel);
      expect(
        appShellRouteLabel(AppRoute.salesMonitoring, l10n),
        l10n.shellNavSalesMonitoringLabel,
      );
      expect(
        appShellRouteLabel(AppRoute.inventory, l10n),
        l10n.shellNavInventoryLabel,
      );
    });

    test('should use enum title for auth routes', () {
      expect(appShellRouteLabel(AppRoute.login, l10n), AppRoute.login.title);
      expect(
        appShellRouteLabel(AppRoute.register, l10n),
        AppRoute.register.title,
      );
      expect(
        appShellRouteLabel(AppRoute.chartFullscreen, l10n),
        AppRoute.chartFullscreen.title,
      );
    });
  });

  group('appShellRouteSubtitle', () {
    test('should describe shell destinations', () {
      expect(
        appShellRouteSubtitle(AppRoute.dashboard, l10n),
        l10n.shellNavDashboardSubtitle,
      );
      expect(
        appShellRouteSubtitle(AppRoute.dashboardStore, l10n),
        l10n.shellNavDashboardSubtitle,
      );
      expect(
        appShellRouteSubtitle(AppRoute.settings, l10n),
        l10n.shellNavSettingsSubtitle,
      );
    });

    test('should describe active shell destinations', () {
      expect(
        appShellRouteSubtitle(AppRoute.sales, l10n),
        l10n.shellNavSalesSubtitle,
      );
      expect(
        appShellRouteSubtitle(AppRoute.salesMonitoring, l10n),
        l10n.shellNavSalesMonitoringSubtitle,
      );
      expect(
        appShellRouteSubtitle(AppRoute.inventory, l10n),
        l10n.shellNavInventorySubtitle,
      );
    });

    test('should omit subtitle for auth routes', () {
      expect(appShellRouteSubtitle(AppRoute.login, l10n), isNull);
      expect(appShellRouteSubtitle(AppRoute.register, l10n), isNull);
      expect(appShellRouteSubtitle(AppRoute.chartFullscreen, l10n), isNull);
    });
  });

  group('appShellRouteIcon', () {
    test('should switch outlined vs filled for dashboard', () {
      expect(
        appShellRouteIcon(AppRoute.dashboard, selected: false),
        Icons.space_dashboard_outlined,
      );
      expect(
        appShellRouteIcon(AppRoute.dashboardStore, selected: true),
        Icons.space_dashboard_rounded,
      );
    });

    test('should switch outline vs filled for settings', () {
      expect(
        appShellRouteIcon(AppRoute.settings, selected: false),
        Icons.person_outline_rounded,
      );
      expect(
        appShellRouteIcon(AppRoute.settings, selected: true),
        Icons.person_rounded,
      );
    });

    test('should switch outline vs filled for sales', () {
      expect(
        appShellRouteIcon(AppRoute.sales, selected: false),
        Icons.point_of_sale_outlined,
      );
      expect(
        appShellRouteIcon(AppRoute.sales, selected: true),
        Icons.point_of_sale_rounded,
      );
      expect(
        appShellRouteIcon(AppRoute.salesMonitoring, selected: false),
        Icons.map_outlined,
      );
      expect(
        appShellRouteIcon(AppRoute.salesMonitoring, selected: true),
        Icons.map_rounded,
      );
    });
  });
}
