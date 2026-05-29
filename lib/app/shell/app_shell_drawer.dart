import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/shell/app_shell_navigation_panel.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

class AppShellDrawer extends StatelessWidget {
  const AppShellDrawer({
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
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Drawer(
      width: tokens.shellDrawerWidth,
      child: SafeArea(
        child: AppShellNavigationPanel(
          currentLocation: currentLocation,
          currentRoute: currentRoute,
          visibleShellRoutes: visibleShellRoutes,
          closeOverlayBeforeNavigate: true,
        ),
      ),
    );
  }
}
