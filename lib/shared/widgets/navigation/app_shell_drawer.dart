import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;
    final userContext = context.watch<CurrentUserContextController>();
    final userScope = userContext.userScope;

    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(tokens.contentSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: cs.primaryContainer,
                    foregroundColor: cs.onPrimaryContainer,
                    child: const Icon(Icons.hexagon_outlined),
                  ),
                  SizedBox(width: tokens.gapMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Colmeia',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Menu principal',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: tokens.sectionSpacing),
              ...visibleShellRoutes.map((route) {
                final selected =
                    route.shellIndex != null &&
                    route.shellIndex == currentRoute.shellIndex;
                final subtitle = _subtitleForRoute(route);
                return Padding(
                  padding: EdgeInsets.only(bottom: tokens.gapSm),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(tokens.cardRadius),
                    ),
                    tileColor: selected ? cs.primaryContainer : null,
                    leading: Icon(
                      _iconForRoute(route, selected: selected),
                      color: selected ? cs.onPrimaryContainer : cs.onSurface,
                    ),
                    title: Text(
                      _labelForRoute(route),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: selected ? cs.onPrimaryContainer : null,
                      ),
                    ),
                    subtitle: subtitle == null
                        ? null
                        : Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: selected
                                  ? cs.onPrimaryContainer.withValues(alpha: 0.8)
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                    onTap: () {
                      Navigator.of(context).pop();
                      if (route != currentRoute) {
                        context.goTo(route);
                      }
                    },
                  ),
                );
              }),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(tokens.contentSpacing),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(tokens.cardRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      userScope.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: tokens.gapXs),
                    Text(
                      userScope.roleLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: tokens.gapSm),
                    Text(
                      'Loja ativa: ${userContext.activeStore.name}',
                      style: theme.textTheme.bodySmall,
                    ),
                    SizedBox(height: tokens.contentSpacing),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await context.read<AuthController>().signOut();
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sair'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _labelForRoute(AppRoute route) {
    switch (route) {
      case AppRoute.dashboard:
      case AppRoute.dashboardStore:
        return 'Dashboard';
      case AppRoute.reports:
      case AppRoute.reportDetail:
        return 'Relatórios';
      case AppRoute.settings:
        return 'Ajustes';
      case AppRoute.login:
      case AppRoute.register:
        return route.title;
    }
  }

  String? _subtitleForRoute(AppRoute route) {
    switch (route) {
      case AppRoute.dashboard:
      case AppRoute.dashboardStore:
        return 'Resumo operacional e KPIs';
      case AppRoute.reports:
      case AppRoute.reportDetail:
        return 'Consultas e relatórios dinâmicos';
      case AppRoute.settings:
        return 'Perfil, sessão e preferências';
      case AppRoute.login:
      case AppRoute.register:
        return null;
    }
  }

  IconData _iconForRoute(AppRoute route, {required bool selected}) {
    switch (route) {
      case AppRoute.dashboard:
      case AppRoute.dashboardStore:
        return selected
            ? Icons.space_dashboard_rounded
            : Icons.space_dashboard_outlined;
      case AppRoute.reports:
      case AppRoute.reportDetail:
        return selected ? Icons.assessment_rounded : Icons.assessment_outlined;
      case AppRoute.settings:
        return selected ? Icons.settings_rounded : Icons.settings_outlined;
      case AppRoute.login:
      case AppRoute.register:
        return Icons.arrow_forward_rounded;
    }
  }
}
