import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';
import 'package:flutter/material.dart';

enum AppRoute {
  unmatched(
    path: '/__unmatched__',
    title: '',
  ),
  login(
    path: '/login',
    title: 'Entrar',
  ),
  register(
    path: '/register',
    title: 'Criar conta',
  ),
  registrationStatus(
    path: '/register/status',
    title: 'Status do cadastro',
  ),
  passwordRecovery(
    path: '/password-recovery',
    title: 'Recuperar acesso',
  ),
  passwordRecoveryReset(
    path: '/password-recovery/reset',
    title: 'Redefinir senha',
  ),
  dashboardStore(
    path: '/dashboard/store/:storeId',
    title: 'Visao geral',
  ),
  dashboard(
    path: '/dashboard',
    title: 'Visao geral',
  ),
  dashboardChart(
    path: '/dashboard/chart/:chartId',
    title: 'Visao geral',
  ),
  sales(
    path: '/sales',
    title: 'Vendas',
  ),
  salesCard(
    path: '/sales/:cardId',
    title: 'Vendas',
  ),
  salesMonitoring(
    path: '/sales-monitoring',
    title: 'Acompanhar vendas',
  ),
  chartFullscreen(
    path: '/charts/fullscreen',
    title: 'Grafico',
  ),
  agents(
    path: '/agents',
    title: 'Agentes',
  ),
  agentsDetail(
    path: '/agents/:agentId',
    title: 'Detalhe do agente',
  ),
  settings(
    path: '/settings',
    title: 'Perfil',
  )
  ;

  const AppRoute({
    required this.path,
    required this.title,
  });

  final String path;
  final String title;

  /// Order of top-level shell destinations; indices match [shellIndex] for
  /// routes listed here. [dashboardStore] shares the index of [dashboard].
  static const List<AppRoute> shellRoutes = <AppRoute>[
    dashboard,
    salesMonitoring,
    sales,
    agents,
    settings,
  ];

  /// Shell section owner for this route.
  ///
  /// Root shell routes return themselves. Detail routes that belong to a shell
  /// section resolve back to that root. Non-shell routes return `null`.
  AppRoute? get shellRootRoute {
    switch (this) {
      case AppRoute.dashboardStore:
      case AppRoute.dashboardChart:
        return AppRoute.dashboard;
      case AppRoute.salesCard:
        return AppRoute.sales;
      case AppRoute.salesMonitoring:
        return this;
      case AppRoute.agentsDetail:
        return AppRoute.agents;
      case AppRoute.dashboard:
      case AppRoute.sales:
      case AppRoute.agents:
      case AppRoute.settings:
        return this;
      case AppRoute.unmatched:
      case AppRoute.chartFullscreen:
      case AppRoute.login:
      case AppRoute.register:
      case AppRoute.registrationStatus:
      case AppRoute.passwordRecovery:
      case AppRoute.passwordRecoveryReset:
        return null;
    }
  }

  /// Position in [shellRoutes] for drawer/rail highlight, or null when not a
  /// primary shell tab (e.g. auth routes, [unmatched]).
  int? get shellIndex {
    final root = shellRootRoute;
    if (root == null) {
      return null;
    }
    final index = shellRoutes.indexOf(root);
    return index >= 0 ? index : null;
  }

  IconData get selectedNavigationIcon {
    switch (this) {
      case AppRoute.unmatched:
        return Icons.help_outline_rounded;
      case AppRoute.dashboard:
      case AppRoute.dashboardStore:
      case AppRoute.dashboardChart:
        return Icons.space_dashboard_rounded;
      case AppRoute.sales:
      case AppRoute.salesCard:
        return Icons.point_of_sale_rounded;
      case AppRoute.salesMonitoring:
        return Icons.map_rounded;
      case AppRoute.chartFullscreen:
        return Icons.open_in_full_rounded;
      case AppRoute.settings:
        return Icons.person_rounded;
      case AppRoute.agents:
        return Icons.hub_rounded;
      case AppRoute.agentsDetail:
        return Icons.hub_rounded;
      case AppRoute.login:
      case AppRoute.register:
      case AppRoute.registrationStatus:
      case AppRoute.passwordRecovery:
      case AppRoute.passwordRecoveryReset:
        return Icons.arrow_forward_rounded;
    }
  }

  IconData get unselectedNavigationIcon {
    switch (this) {
      case AppRoute.unmatched:
        return Icons.help_outline_outlined;
      case AppRoute.dashboard:
      case AppRoute.dashboardStore:
      case AppRoute.dashboardChart:
        return Icons.space_dashboard_outlined;
      case AppRoute.sales:
      case AppRoute.salesCard:
        return Icons.point_of_sale_outlined;
      case AppRoute.salesMonitoring:
        return Icons.map_outlined;
      case AppRoute.chartFullscreen:
        return Icons.open_in_full_outlined;
      case AppRoute.settings:
        return Icons.person_outline_rounded;
      case AppRoute.agents:
        return Icons.hub_outlined;
      case AppRoute.agentsDetail:
        return Icons.hub_outlined;
      case AppRoute.login:
      case AppRoute.register:
      case AppRoute.registrationStatus:
      case AppRoute.passwordRecovery:
      case AppRoute.passwordRecoveryReset:
        return Icons.arrow_forward_rounded;
    }
  }

  bool get isShellRoute => shellIndex != null;

  static String _normalizeLocation(String location) {
    final trimmed = location.trim();
    if (trimmed.isEmpty) {
      return '/';
    }
    if (trimmed.length > 1 && trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  bool matchesExactLocation(String location) {
    return _normalizeLocation(location) == _normalizeLocation(path);
  }

  /// Shell drawer/rail highlight index; [agentsDetail] shares [agents].
  int? get shellNavSelectionIndex => shellIndex;

  /// Resolves navigation target for drawer/rail shell items.
  ///
  /// Returns `null` when the tapped item already matches the current root route.
  /// When the current route is a detail route inside the same shell section,
  /// returns that section root so the shell returns to the section home without
  /// pushing another page.
  static AppRoute? resolveShellNavigationTarget({
    required AppRoute current,
    required String currentLocation,
    required AppRoute tapped,
  }) {
    final targetRoot = tapped.shellRootRoute;
    if (targetRoot == null) {
      return null;
    }
    final currentRoot = current.shellRootRoute;
    if (currentRoot != targetRoot) {
      return targetRoot;
    }
    if (targetRoot.matchesExactLocation(currentLocation)) {
      return null;
    }
    return targetRoot;
  }

  UserPermission? get requiredPermission {
    switch (this) {
      case AppRoute.dashboard:
      case AppRoute.dashboardStore:
      case AppRoute.dashboardChart:
        return UserPermission.viewDashboard;
      case AppRoute.sales:
      case AppRoute.salesCard:
      case AppRoute.salesMonitoring:
        return UserPermission.viewSales;
      case AppRoute.unmatched:
      case AppRoute.login:
      case AppRoute.register:
      case AppRoute.registrationStatus:
      case AppRoute.passwordRecovery:
      case AppRoute.passwordRecoveryReset:
      case AppRoute.settings:
      case AppRoute.agents:
      case AppRoute.agentsDetail:
      case AppRoute.chartFullscreen:
        return null;
    }
  }

  static AppRoute fromLocation(String location) {
    final trimmed = location.trim();
    if (trimmed.isEmpty || trimmed == '/') {
      return dashboard;
    }

    final matchedRoutes = AppRoute.values
        .where((route) => route.matches(trimmed))
        .toList(growable: false);
    if (matchedRoutes.isEmpty) {
      return unmatched;
    }

    matchedRoutes.sort(
      (left, right) => right.path.length.compareTo(left.path.length),
    );
    return matchedRoutes.first;
  }

  bool matches(String location) {
    if (this == AppRoute.unmatched) {
      return false;
    }
    final parameterMarkerIndex = path.indexOf('/:');
    if (parameterMarkerIndex != -1) {
      final prefix = path.substring(0, parameterMarkerIndex + 1);
      return location.startsWith(prefix);
    }

    return location == path || location.startsWith('$path/');
  }
}
