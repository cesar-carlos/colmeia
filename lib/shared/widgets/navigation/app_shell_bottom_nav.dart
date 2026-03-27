import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_route_presentation.dart';
import 'package:flutter/material.dart';

class AppShellBottomNav extends StatelessWidget {
  const AppShellBottomNav({
    required this.currentRoute,
    required this.visibleShellRoutes,
    super.key,
  });

  final AppRoute currentRoute;
  final List<AppRoute> visibleShellRoutes;

  @override
  Widget build(BuildContext context) {
    if (visibleShellRoutes.length < 2) {
      return const SizedBox.shrink();
    }

    final selectedIndex = visibleShellRoutes.indexWhere(
      (route) => route.shellIndex == currentRoute.shellIndex,
    );
    final safeIndex = selectedIndex >= 0 ? selectedIndex : 0;

    return SafeArea(
      top: false,
      child: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (index) {
          final target = visibleShellRoutes[index];
          if (target.shellIndex == currentRoute.shellIndex) {
            return;
          }
          context.goTo(target);
        },
        destinations: <NavigationDestination>[
          for (final route in visibleShellRoutes)
            NavigationDestination(
              icon: Icon(appShellRouteIcon(route, selected: false)),
              selectedIcon: Icon(appShellRouteIcon(route, selected: true)),
              label: appShellRouteLabel(route),
            ),
        ],
      ),
    );
  }
}
