import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/shell/app_shell_route_presentation.dart';
import 'package:colmeia/app/shell/app_shell_user_summary.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/features/user_context/presentation/localization/user_role_label_l10n.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_nav_footer_action.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_nav_header.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_nav_menu_item.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_nav_menu_list.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_nav_profile_card.dart';
import 'package:colmeia/shared/widgets/navigation/show_app_sign_out_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Shared column for shell drawer and rail: brand, profile, routes, sign out.
class AppShellNavigationPanel extends StatelessWidget {
  const AppShellNavigationPanel({
    required this.currentLocation,
    required this.currentRoute,
    required this.visibleShellRoutes,
    required this.closeOverlayBeforeNavigate,
    super.key,
  });

  final String currentLocation;
  final AppRoute currentRoute;
  final List<AppRoute> visibleShellRoutes;

  /// When true, calls [Navigator.pop] before navigating (drawer behavior).
  /// When false, navigates directly (rail behavior).
  final bool closeOverlayBeforeNavigate;

  void _handleRouteSelected(BuildContext context, AppRoute route) {
    final targetRoute = AppRoute.resolveShellNavigationTarget(
      currentLocation: currentLocation,
      current: currentRoute,
      tapped: route,
    );
    if (targetRoute == null) {
      return;
    }
    if (closeOverlayBeforeNavigate) {
      Navigator.of(context).pop();
    }
    context.goTo(targetRoute);
  }

  void _handleProfileOpen(BuildContext context) {
    if (closeOverlayBeforeNavigate) {
      Navigator.of(context).pop();
    }
    context.goTo(AppRoute.settings);
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showAppSignOutConfirmDialog(context);
    if (!context.mounted || !confirmed) {
      return;
    }
    if (closeOverlayBeforeNavigate) {
      Navigator.of(context).pop();
    }
    await context.read<AuthController>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colors = context.appColors;
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
          AppShellNavHeader(title: l10n.shellAppBrandName),
          SizedBox(height: tokens.sectionSpacing),
          AppShellNavProfileCard(
            name: userData.name,
            roleLabel: userRoleLabelDisplay(l10n, userData.roleLabel),
            thumbnailUrl: userData.thumbnailUrl,
            semanticsLabel: l10n.shellOpenProfileSemantics,
            onTap: isSigningOut ? null : () => _handleProfileOpen(context),
          ),
          SizedBox(height: tokens.sectionSpacing),
          Expanded(
            child: Semantics(
              container: true,
              label: l10n.shellNavMainSemantics,
              child: AppShellNavMenuList(
                children: shellRoutes
                    .map(
                      (presentation) {
                        final isSelected =
                            presentation.route.shellIndex ==
                            currentRoute.shellNavSelectionIndex;
                        return AppShellNavMenuItem(
                          key: ValueKey<String>(
                            'shell-nav-${presentation.route.name}',
                          ),
                          icon: appShellRouteIcon(
                            presentation.route,
                            selected: isSelected,
                          ),
                          title: presentation.label,
                          subtitle: presentation.subtitle,
                          selected: isSelected,
                          onTap: isSigningOut
                              ? null
                              : () => _handleRouteSelected(
                                  context,
                                  presentation.route,
                                ),
                        );
                      },
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
