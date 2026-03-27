import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_route_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('appShellRouteLabel', () {
    test('should map dashboard variants to Dashboard', () {
      expect(appShellRouteLabel(AppRoute.dashboard), 'Dashboard');
      expect(appShellRouteLabel(AppRoute.dashboardStore), 'Dashboard');
    });

    test('should map reports variants to Relatórios', () {
      expect(appShellRouteLabel(AppRoute.reports), 'Relatórios');
      expect(appShellRouteLabel(AppRoute.reportDetail), 'Relatórios');
    });

    test('should map settings to Perfil', () {
      expect(appShellRouteLabel(AppRoute.settings), 'Perfil');
    });

    test('should use enum title for auth routes', () {
      expect(appShellRouteLabel(AppRoute.login), AppRoute.login.title);
      expect(appShellRouteLabel(AppRoute.register), AppRoute.register.title);
    });
  });

  group('appShellRouteSubtitle', () {
    test('should describe shell destinations', () {
      expect(
        appShellRouteSubtitle(AppRoute.dashboard),
        'Resumo operacional e KPIs',
      );
      expect(
        appShellRouteSubtitle(AppRoute.dashboardStore),
        'Resumo operacional e KPIs',
      );
      expect(
        appShellRouteSubtitle(AppRoute.reports),
        'Consultas e relatórios dinâmicos',
      );
      expect(
        appShellRouteSubtitle(AppRoute.reportDetail),
        'Consultas e relatórios dinâmicos',
      );
      expect(
        appShellRouteSubtitle(AppRoute.settings),
        'Conta, permissões e preferências',
      );
    });

    test('should omit subtitle for auth routes', () {
      expect(appShellRouteSubtitle(AppRoute.login), isNull);
      expect(appShellRouteSubtitle(AppRoute.register), isNull);
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

    test('should switch outlined vs filled for reports', () {
      expect(
        appShellRouteIcon(AppRoute.reports, selected: false),
        Icons.assessment_outlined,
      );
      expect(
        appShellRouteIcon(AppRoute.reportDetail, selected: true),
        Icons.assessment_rounded,
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
  });
}
