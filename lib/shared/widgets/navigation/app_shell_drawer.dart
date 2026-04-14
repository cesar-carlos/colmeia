import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_navigation_panel.dart';
import 'package:flutter/material.dart';

class AppShellDrawer extends StatelessWidget {
  const AppShellDrawer({
    required this.currentRoute,
    required this.visibleShellRoutes,
    super.key,
  });

  final AppRoute currentRoute;
  final List<AppRoute> visibleShellRoutes;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Drawer(
      width: tokens.shellDrawerWidth,
      child: SafeArea(
        child: AppShellNavigationPanel(
          currentRoute: currentRoute,
          visibleShellRoutes: visibleShellRoutes,
          closeOverlayBeforeSignOut: true,
          onShellRouteSelected: (context, route) async {
            Navigator.of(context).pop();
            if (route.shellIndex != currentRoute.shellIndex) {
              context.goTo(route);
            }
          },
          onProfileOpen: (context) async {
            Navigator.of(context).pop();
            context.goTo(AppRoute.settings);
          },
        ),
      ),
    );
  }
}
