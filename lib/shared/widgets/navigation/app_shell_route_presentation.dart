import 'package:colmeia/app/router/app_routes.dart';
import 'package:flutter/material.dart';

String appShellRouteLabel(AppRoute route) {
  switch (route) {
    case AppRoute.dashboard:
    case AppRoute.dashboardStore:
      return 'Dashboard';
    case AppRoute.reports:
    case AppRoute.reportDetail:
      return 'Relatórios';
    case AppRoute.settings:
      return 'Perfil';
    case AppRoute.login:
    case AppRoute.register:
      return route.title;
  }
}

String? appShellRouteSubtitle(AppRoute route) {
  switch (route) {
    case AppRoute.dashboard:
    case AppRoute.dashboardStore:
      return 'Resumo operacional e KPIs';
    case AppRoute.reports:
    case AppRoute.reportDetail:
      return 'Consultas e relatórios dinâmicos';
    case AppRoute.settings:
      return 'Conta, permissões e preferências';
    case AppRoute.login:
    case AppRoute.register:
      return null;
  }
}

IconData appShellRouteIcon(AppRoute route, {required bool selected}) {
  switch (route) {
    case AppRoute.dashboard:
    case AppRoute.dashboardStore:
      return selected
          ? Icons.space_dashboard_rounded
          : Icons.space_dashboard_outlined;
    case AppRoute.reports:
    case AppRoute.reportDetail:
      return selected ? Icons.assessment_rounded : Icons.assessment_outlined;
    case AppRoute.settings:
      return selected ? Icons.person_rounded : Icons.person_outline_rounded;
    case AppRoute.login:
    case AppRoute.register:
      return Icons.arrow_forward_rounded;
  }
}
