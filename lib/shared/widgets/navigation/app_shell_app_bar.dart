import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_user_initials.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppShellAppBar({
    super.key,
    this.showSearchPill = true,
    this.searchHint = 'Buscar componentes...',
    this.primary = true,
    this.showBrandTitle = true,
  });

  /// Hidden on narrow ([AppBreakpoints.isMobile]) to avoid crowding the title.
  final bool showSearchPill;

  final String searchHint;

  /// When `false`, use next to [NavigationRail] inside the body (no duplicate
  /// top status-bar padding). When `true` (default), used as [Scaffold.appBar].
  final bool primary;

  final bool showBrandTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final userContext = context.watch<CurrentUserContextController>();
    final userScope = userContext.userScope;

    final showSearch = showSearchPill && !AppBreakpoints.isMobile(context);

    final brandTitle = Semantics(
      header: true,
      label: 'Colmeia',
      child: Text(
        'Colmeia',
        style: typography.sectionHeaderH2.copyWith(
          fontSize: theme.textTheme.titleLarge?.fontSize,
          fontWeight: FontWeight.w800,
          color: colors.primary,
        ),
      ),
    );

    final title = showSearch
        ? showBrandTitle
              ? Row(
                  children: <Widget>[
                    brandTitle,
                    SizedBox(width: tokens.gapMd),
                    Expanded(
                      child: _ShellSearchPill(hintText: searchHint),
                    ),
                  ],
                )
              : _ShellSearchPill(hintText: searchHint)
        : showBrandTitle
        ? brandTitle
        : null;

    return AppBar(
      primary: primary,
      titleSpacing: showBrandTitle
          ? (showSearch ? 16 : 0)
          : tokens.contentSpacing,
      title: title,
      actions: <Widget>[
        IconButton(
          tooltip: 'Notificações',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notificações em breve.'),
              ),
            );
          },
          icon: const Icon(
            Icons.notifications_outlined,
            semanticLabel: 'Notificações',
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: Semantics(
            label: 'Abrir configuracoes',
            button: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => context.goTo(AppRoute.settings),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.onPrimaryContainer,
                  child: Text(
                    appShellUserInitials(userScope.name),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShellSearchPill extends StatelessWidget {
  const _ShellSearchPill({required this.hintText});

  final String hintText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.appColors;
    final tokens = theme.extension<AppThemeTokens>()!;

    final hintStyle = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
    );

    return Semantics(
      label: 'Busca',
      hint: hintText,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Busca global em breve.')),
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colors.primary),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.gapMd,
                vertical: 10,
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                  ),
                  SizedBox(width: tokens.gapSm),
                  Expanded(
                    child: Text(
                      hintText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: hintStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
