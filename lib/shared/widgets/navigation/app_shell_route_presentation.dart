import 'package:colmeia/app/router/app_routes.dart';
import 'package:flutter/material.dart';

class AppShellRoutePresentation {
  const AppShellRoutePresentation({
    required this.route,
    required this.label,
    required this.selectedIcon,
    required this.unselectedIcon,
    this.subtitle,
  });

  final AppRoute route;
  final String label;
  final String? subtitle;
  final IconData selectedIcon;
  final IconData unselectedIcon;
}

AppShellRoutePresentation appShellRoutePresentation(AppRoute route) {
  return AppShellRoutePresentation(
    route: route,
    label: route.navigationLabel,
    subtitle: route.navigationSubtitle,
    selectedIcon: route.selectedNavigationIcon,
    unselectedIcon: route.unselectedNavigationIcon,
  );
}

List<AppShellRoutePresentation> buildAppShellRoutePresentations(
  Iterable<AppRoute> routes,
) {
  return routes.map(appShellRoutePresentation).toList(growable: false);
}

String appShellRouteLabel(AppRoute route) {
  return appShellRoutePresentation(route).label;
}

String? appShellRouteSubtitle(AppRoute route) {
  return appShellRoutePresentation(route).subtitle;
}

IconData appShellRouteIcon(AppRoute route, {required bool selected}) {
  final presentation = appShellRoutePresentation(route);
  return selected ? presentation.selectedIcon : presentation.unselectedIcon;
}
