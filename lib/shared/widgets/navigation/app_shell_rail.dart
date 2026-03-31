import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_route_presentation.dart';
import 'package:flutter/material.dart';

class _RailDestinationIcon extends StatelessWidget {
  const _RailDestinationIcon({
    required this.icon,
    required this.selected,
  });

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: <Widget>[
        Icon(
          icon,
          size: 24,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        ),
        if (selected)
          PositionedDirectional(
            end: -2,
            child: Container(
              width: 3,
              height: 26,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}

class AppShellRail extends StatelessWidget {
  const AppShellRail({
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
      (r) => r.shellIndex == currentRoute.shellIndex,
    );
    final safeIndex = selectedIndex >= 0 ? selectedIndex : 0;
    final extended = AppBreakpoints.isDesktop(context);

    return NavigationRail(
      extended: extended,
      useIndicator: false,
      selectedIndex: safeIndex,
      onDestinationSelected: (index) {
        final target = visibleShellRoutes[index];
        if (target.shellIndex == currentRoute.shellIndex) return;
        context.goTo(target);
      },
      destinations: <NavigationRailDestination>[
        for (final route in visibleShellRoutes)
          NavigationRailDestination(
            icon: _RailDestinationIcon(
              icon: appShellRouteIcon(route, selected: false),
              selected: false,
            ),
            selectedIcon: _RailDestinationIcon(
              icon: appShellRouteIcon(route, selected: true),
              selected: true,
            ),
            label: Text(appShellRouteLabel(route)),
          ),
      ],
    );
  }
}
