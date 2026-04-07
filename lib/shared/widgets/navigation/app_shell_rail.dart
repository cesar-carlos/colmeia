import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_drawer_header.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_drawer_menu_item.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_drawer_menu_list.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_nav_footer_action.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_nav_profile_card.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_route_presentation.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_user_summary.dart';
import 'package:colmeia/shared/widgets/navigation/show_app_sign_out_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppShellRail extends StatelessWidget {
  const AppShellRail({
    required this.currentRoute,
    required this.visibleShellRoutes,
    super.key,
  });

  final AppRoute currentRoute;
  final List<AppRoute> visibleShellRoutes;

  List<_RailMenuEntry> _buildMenuEntries(
    BuildContext context,
    List<AppShellRoutePresentation> routes,
  ) {
    return routes
        .map(
          (route) => _RailMenuEntry(
            title: route.label,
            subtitle: route.subtitle,
            icon: appShellRouteIcon(
              route.route,
              selected: route.route.shellIndex == currentRoute.shellIndex,
            ),
            selected: route.route.shellIndex == currentRoute.shellIndex,
            onTap: () => _handleShellRouteTap(context, route.route),
          ),
        )
        .toList(growable: false);
  }

  void _handleShellRouteTap(BuildContext context, AppRoute route) {
    if (route.shellIndex != currentRoute.shellIndex) {
      context.goTo(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (visibleShellRoutes.length < 2) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;
    final isSigningOut = context.select<AuthController, bool>(
      (controller) => controller.isLoading,
    );
    final userData = context
        .select<CurrentUserContextController, AppShellUserSummary>(
          selectAppShellUserSummary,
        );
    final shellRoutes = buildAppShellRoutePresentations(
      visibleShellRoutes,
      AppLocalizations.of(context),
    );
    final menuEntries = _buildMenuEntries(context, shellRoutes);
    final railWidth = AppBreakpoints.isDesktop(context)
        ? tokens.shellRailWidthDesktop
        : tokens.shellRailWidthTablet;

    return SizedBox(
      width: railWidth,
      child: ColoredBox(
        color: colors.surfaceContainerLowest,
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
                name: userData.name,
                roleLabel: userData.roleLabel,
                thumbnailUrl: userData.thumbnailUrl,
              ),
              SizedBox(height: tokens.sectionSpacing),
              Expanded(
                child: AppShellDrawerMenuList(
                  children: menuEntries
                      .map(
                        (entry) => AppShellDrawerMenuItem(
                          icon: entry.icon,
                          title: entry.title,
                          subtitle: entry.subtitle,
                          selected: entry.selected,
                          onTap: isSigningOut ? null : entry.onTap,
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              Divider(
                height: 1,
                color: colors.outlineVariant.withValues(alpha: 0.42),
              ),
              SizedBox(height: tokens.gapSm),
              AppShellNavFooterAction(
                icon: Icons.logout_rounded,
                label: isSigningOut ? 'Saindo...' : 'Sair',
                isLoading: isSigningOut,
                onTap: () async {
                  final confirmed = await showAppSignOutConfirmDialog(context);
                  if (!context.mounted || !confirmed) {
                    return;
                  }
                  await context.read<AuthController>().signOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailMenuEntry {
  const _RailMenuEntry({
    required this.title,
    required this.icon,
    this.subtitle,
    this.selected = false,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;
}
