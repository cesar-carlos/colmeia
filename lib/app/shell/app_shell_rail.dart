import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/shell/app_shell_navigation_panel.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

class AppShellRail extends StatelessWidget {
  const AppShellRail({
    required this.currentLocation,
    required this.currentRoute,
    required this.visibleShellRoutes,
    super.key,
  });

  final String currentLocation;
  final AppRoute currentRoute;
  final List<AppRoute> visibleShellRoutes;

  @override
  Widget build(BuildContext context) {
    if (visibleShellRoutes.length < 2) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;
    final railWidth = tokens.shellRailWidthDesktop;

    return SizedBox(
      width: railWidth,
      child: ColoredBox(
        color: colors.surfaceContainerLowest,
        child: AppShellNavigationPanel(
          currentLocation: currentLocation,
          currentRoute: currentRoute,
          visibleShellRoutes: visibleShellRoutes,
          closeOverlayBeforeNavigate: false,
        ),
      ),
    );
  }
}
