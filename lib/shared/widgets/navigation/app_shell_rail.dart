import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
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
      leading: _ShellRailBrand(extended: extended),
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

class _ShellRailBrand extends StatelessWidget {
  const _ShellRailBrand({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;

    if (!extended) {
      return Padding(
        padding: EdgeInsets.only(top: tokens.contentSpacing),
        child: Icon(
          Icons.hexagon_outlined,
          color: colors.primary,
          size: 22,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.contentSpacing,
        tokens.contentSpacing,
        tokens.contentSpacing,
        tokens.gapMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Colmeia',
            style: typography.sectionHeaderH2.copyWith(
              color: colors.primary,
              fontSize: theme.textTheme.titleLarge?.fontSize,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: tokens.gapXs),
          Text(
            'HIVE WORKSPACE',
            style: typography.utilityOverline.copyWith(
              color: colors.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
