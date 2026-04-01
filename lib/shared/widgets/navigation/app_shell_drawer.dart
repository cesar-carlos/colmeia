import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/settings/presentation/routes/settings_routes.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_flat_button.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_drawer_header.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_drawer_menu_item.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_drawer_menu_list.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_nav_footer_action.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_nav_profile_card.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_route_presentation.dart';
import 'package:colmeia/shared/widgets/navigation/show_app_sign_out_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AppShellDrawer extends StatelessWidget {
  const AppShellDrawer({
    required this.currentRoute,
    required this.visibleShellRoutes,
    super.key,
  });

  final AppRoute currentRoute;
  final List<AppRoute> visibleShellRoutes;

  List<_DrawerMenuEntry> _buildMenuEntries(BuildContext context) {
    final hasDashboardRoute = visibleShellRoutes.any(
      (route) => route.shellIndex == AppRoute.dashboard.shellIndex,
    );
    final hasSettingsRoute = visibleShellRoutes.contains(AppRoute.settings);
    final dashboardSelected =
        currentRoute.shellIndex == AppRoute.dashboard.shellIndex;
    final settingsSelected = currentRoute == AppRoute.settings;

    return <_DrawerMenuEntry>[
      if (hasDashboardRoute)
        _DrawerMenuEntry(
          title: 'Dashboard',
          icon: appShellRouteIcon(
            AppRoute.dashboard,
            selected: dashboardSelected,
          ),
          selected: dashboardSelected,
          onTap: () => _handleShellRouteTap(context, AppRoute.dashboard),
        ),
      const _DrawerMenuEntry(
        title: 'Analytics',
        icon: Icons.auto_graph_rounded,
      ),
      const _DrawerMenuEntry(
        title: 'Reports',
        icon: Icons.assessment_outlined,
      ),
      if (hasSettingsRoute)
        _DrawerMenuEntry(
          title: 'Settings',
          icon: appShellRouteIcon(
            AppRoute.settings,
            selected: settingsSelected,
          ),
          selected: settingsSelected,
          onTap: () => _handleShellRouteTap(context, AppRoute.settings),
        ),
    ];
  }

  void _handleShellRouteTap(BuildContext context, AppRoute route) {
    Navigator.of(context).pop();
    if (route.shellIndex != currentRoute.shellIndex) {
      context.goTo(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;
    final userScope = context.watch<CurrentUserContextController>().userScope;
    final menuEntries = _buildMenuEntries(context);

    return Drawer(
      width: 296,
      child: ColoredBox(
        color: colors.surfaceContainerLowest,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.contentSpacing,
              tokens.gapMd,
              tokens.contentSpacing,
              tokens.contentSpacing,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const AppShellDrawerHeader(),
                SizedBox(height: tokens.sectionSpacing),
                AppShellNavProfileCard(
                  name: userScope.name,
                  roleLabel: userScope.roleLabel,
                ),
                SizedBox(height: tokens.sectionSpacing),
                Expanded(
                  child: AppShellDrawerMenuList(
                    children: menuEntries
                        .map(
                          (entry) => AppShellDrawerMenuItem(
                            icon: entry.icon,
                            title: entry.title,
                            selected: entry.selected,
                            onTap: entry.onTap,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                if (kDebugMode) ...<Widget>[
                  SizedBox(height: tokens.gapSm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppFlatButton(
                      fillWidth: false,
                      icon: const Icon(Icons.widgets_outlined),
                      label: 'Componentes (dev)',
                      semanticsLabel:
                          'Abrir catalogo de componentes de desenvolvimento',
                      onPressed: () {
                        Navigator.of(context).pop();
                        unawaited(
                          context.push(sharedComponentsDemoIndexLocation),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: tokens.gapMd),
                ],
                Divider(
                  height: 1,
                  color: colors.outlineVariant.withValues(alpha: 0.42),
                ),
                SizedBox(height: tokens.gapSm),
                AppShellNavFooterAction(
                  icon: Icons.logout_rounded,
                  label: 'Sair',
                  onTap: () async {
                    final confirmed = await showAppSignOutConfirmDialog(
                      context,
                    );
                    if (!context.mounted || !confirmed) {
                      return;
                    }
                    Navigator.of(context).pop();
                    await context.read<AuthController>().signOut();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerMenuEntry {
  const _DrawerMenuEntry({
    required this.title,
    required this.icon,
    this.selected = false,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
}
