import 'dart:async';

import 'package:colmeia/app/router/app_routes.dart';
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

typedef AppShellRouteNavigate =
    Future<void> Function(
      BuildContext context,
      AppRoute route,
    );

typedef AppShellProfileNavigate =
    Future<void> Function(
      BuildContext context,
    );

/// Shared column for shell drawer and rail: brand, profile, routes, sign out.
class AppShellNavigationPanel extends StatelessWidget {
  const AppShellNavigationPanel({
    required this.currentRoute,
    required this.visibleShellRoutes,
    required this.closeOverlayBeforeSignOut,
    required this.onShellRouteSelected,
    required this.onProfileOpen,
    super.key,
  });

  final AppRoute currentRoute;
  final List<AppRoute> visibleShellRoutes;
  final bool closeOverlayBeforeSignOut;
  final AppShellRouteNavigate onShellRouteSelected;
  final AppShellProfileNavigate onProfileOpen;

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showAppSignOutConfirmDialog(context);
    if (!context.mounted || !confirmed) {
      return;
    }
    if (closeOverlayBeforeSignOut) {
      Navigator.of(context).pop();
    }
    await context.read<AuthController>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;
    final l10n = AppLocalizations.of(context);
    final isSigningOut = context.select<AuthController, bool>(
      (controller) => controller.isLoading,
    );
    final userData = context
        .select<CurrentUserContextController, AppShellUserSummary>(
          selectAppShellUserSummary,
        );
    final shellRoutes = buildAppShellRoutePresentations(
      visibleShellRoutes,
      l10n,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.contentSpacing,
        tokens.gapMd,
        tokens.contentSpacing,
        tokens.contentSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppShellDrawerHeader(title: l10n.shellAppBrandName),
          SizedBox(height: tokens.sectionSpacing),
          AppShellNavProfileCard(
            name: userData.name,
            roleLabel: userData.roleLabel,
            thumbnailUrl: userData.thumbnailUrl,
            semanticsLabel: l10n.shellOpenProfileSemantics,
            onTap: isSigningOut
                ? null
                : () {
                    unawaited(onProfileOpen(context));
                  },
          ),
          SizedBox(height: tokens.sectionSpacing),
          Expanded(
            child: Semantics(
              container: true,
              label: l10n.shellNavMainSemantics,
              child: AppShellDrawerMenuList(
                children: shellRoutes
                    .map(
                      (presentation) => AppShellDrawerMenuItem(
                        icon: appShellRouteIcon(
                          presentation.route,
                          selected:
                              presentation.route.shellIndex ==
                              currentRoute.shellIndex,
                        ),
                        title: presentation.label,
                        subtitle: presentation.subtitle,
                        selected:
                            presentation.route.shellIndex ==
                            currentRoute.shellIndex,
                        onTap: isSigningOut
                            ? null
                            : () {
                                unawaited(
                                  onShellRouteSelected(
                                    context,
                                    presentation.route,
                                  ),
                                );
                              },
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
          Divider(
            height: 1,
            color: colors.outlineVariant.withValues(alpha: 0.42),
          ),
          SizedBox(height: tokens.gapSm),
          AppShellNavFooterAction(
            icon: Icons.logout_rounded,
            label: isSigningOut
                ? l10n.shellNavSigningOut
                : l10n.shellNavSignOut,
            isLoading: isSigningOut,
            loadingSemanticsLabel: l10n.shellNavSignOutSemanticsLoading,
            onTap: isSigningOut
                ? null
                : () {
                    unawaited(_handleSignOut(context));
                  },
          ),
        ],
      ),
    );
  }
}
