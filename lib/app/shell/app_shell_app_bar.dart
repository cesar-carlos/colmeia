import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/router/shell_section_navigation.dart';
import 'package:colmeia/app/shell/app_shell_user_summary.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_brand_icon.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_user_avatar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

IconData _shellLeadingBackIcon() {
  if (kIsWeb) {
    return Icons.arrow_back;
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return Icons.arrow_back_ios_new;
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
      return Icons.arrow_back;
  }
}

class AppShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppShellAppBar({
    super.key,
    this.primary = true,
    this.showBrandTitle = true,
  });

  /// When `false`, sits beside the desktop rail in the body (no duplicate
  /// top status-bar padding). When `true` (default), used as [Scaffold.appBar].
  final bool primary;

  final bool showBrandTitle;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final l10n = AppLocalizations.of(context);
    final userData = context
        .select<CurrentUserContextController, AppShellUserSummary>(
          selectAppShellUserSummary,
        );

    final useRail = AppBreakpoints.useRail(context);
    final showUserDetails = useRail;
    final materialLocalizations = MaterialLocalizations.of(context);
    final showBack = shellSectionBackVisible(context);
    final titleSpacing = showBrandTitle ? 0.0 : tokens.contentSpacing;

    final Widget? leading;
    final bool automaticallyImplyLeading;
    final double? leadingWidth;
    if (showBack) {
      automaticallyImplyLeading = false;
      leadingWidth = null;
      leading = IconButton(
        tooltip: materialLocalizations.backButtonTooltip,
        onPressed: () => navigateShellSectionUp(context),
        icon: Icon(_shellLeadingBackIcon()),
      );
    } else {
      automaticallyImplyLeading = true;
      leadingWidth = null;
      leading = null;
    }

    final brandTitle = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const AppShellBrandIcon(),
        SizedBox(width: tokens.gapSm),
        Semantics(
          header: true,
          label: l10n.shellAppBrandName,
          child: Text(
            l10n.shellAppBrandName,
            style: typography.sectionHeaderH2.copyWith(
              fontSize: theme.textTheme.titleMedium?.fontSize,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
        ),
      ],
    );

    final title = showBrandTitle ? brandTitle : null;

    return AppBar(
      primary: primary,
      toolbarHeight: preferredSize.height,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      leadingWidth: leadingWidth,
      titleSpacing: titleSpacing,
      title: title,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      actions: <Widget>[
        SizedBox(width: tokens.gapSm),
        Padding(
          padding: EdgeInsetsDirectional.only(
            end: tokens.contentSpacing,
            start: tokens.gapSm,
          ),
          child: _ShellUserChip(
            name: userData.name,
            thumbnailUrl: userData.thumbnailUrl,
            subtitle: showUserDetails ? userData.roleLabel : null,
            semanticsLabel: l10n.shellOpenSettingsSemantics,
            onTap: () => context.goTo(AppRoute.settings),
          ),
        ),
      ],
    );
  }
}

class _ShellUserChip extends StatelessWidget {
  const _ShellUserChip({
    required this.name,
    required this.onTap,
    required this.semanticsLabel,
    this.thumbnailUrl,
    this.subtitle,
  });

  final String name;
  final String semanticsLabel;
  final String? thumbnailUrl;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final tokens = theme.extension<AppThemeTokens>()!;
    final showSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;

    return Semantics(
      label: semanticsLabel,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: showSubtitle ? tokens.gapSm : 0,
              vertical: tokens.gapXs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppShellUserAvatar(
                  name: name,
                  thumbnailUrl: thumbnailUrl,
                  radius: 18,
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.onPrimaryContainer,
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (showSubtitle) ...<Widget>[
                  SizedBox(width: tokens.gapSm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 148),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        SizedBox(height: tokens.gapXs / 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
