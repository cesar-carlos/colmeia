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
  sales(
    path: '/sales',
    title: 'Vendas',
  ),
  salesCard(
    path: '/sales/:cardId',
    title: 'Vendas',
  ),
  chartFullscreen(
    path: '/charts/fullscreen',
    title: 'Grafico',
  ),
  returns(
    path: '/returns',
    title: 'Devolucoes',
  ),
  finance(
    path: '/finance',
    title: 'Financeiro',
  ),
  purchases(
    path: '/purchases',
    title: 'Compras',
  ),
  inventory(
    path: '/inventory',
    title: 'Estoque',
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
    sales,
    inventory,
    agents,
    settings,
  ];

  /// Position in [shellRoutes] for drawer/rail highlight, or null when not a
  /// primary shell tab (e.g. [agentsDetail], auth routes, [unmatched]).
  int? get shellIndex {
    if (this == AppRoute.unmatched ||
        this == AppRoute.agentsDetail ||
        this == AppRoute.chartFullscreen ||
        this == AppRoute.login ||
        this == AppRoute.register ||
        this == AppRoute.registrationStatus ||
        this == AppRoute.passwordRecovery ||
        this == AppRoute.passwordRecoveryReset) {
      return null;
    }
    if (this == AppRoute.dashboardStore) {
      return shellRoutes.indexOf(AppRoute.dashboard);
    }
    if (this == AppRoute.salesCard) {
      return shellRoutes.indexOf(AppRoute.sales);
    }
    final index = shellRoutes.indexOf(this);
    return index >= 0 ? index : null;
  }

  IconData get selectedNavigationIcon {
    switch (this) {
      case AppRoute.unmatched:
        return Icons.help_outline_rounded;
      case AppRoute.dashboard:
      case AppRoute.dashboardStore:
        return Icons.space_dashboard_rounded;
      case AppRoute.sales:
      case AppRoute.salesCard:
        return Icons.point_of_sale_rounded;
      case AppRoute.chartFullscreen:
        return Icons.open_in_full_rounded;
      case AppRoute.returns:
        return Icons.assignment_return_rounded;
      case AppRoute.finance:
        return Icons.account_balance_rounded;
      case AppRoute.purchases:
        return Icons.shopping_cart_rounded;
      case AppRoute.inventory:
        return Icons.inventory_2_rounded;
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
        return Icons.space_dashboard_outlined;
      case AppRoute.sales:
      case AppRoute.salesCard:
        return Icons.point_of_sale_outlined;
      case AppRoute.chartFullscreen:
        return Icons.open_in_full_outlined;
      case AppRoute.returns:
        return Icons.assignment_return_outlined;
      case AppRoute.finance:
        return Icons.account_balance_outlined;
      case AppRoute.purchases:
        return Icons.shopping_cart_outlined;
      case AppRoute.inventory:
        return Icons.inventory_2_outlined;
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

  /// Shell drawer/rail highlight index; [agentsDetail] shares [agents].
  int? get shellNavSelectionIndex {
    switch (this) {
      case AppRoute.agentsDetail:
        return AppRoute.agents.shellIndex;
      case AppRoute.salesCard:
        return AppRoute.sales.shellIndex;
      case AppRoute.unmatched:
      case AppRoute.chartFullscreen:
      case AppRoute.login:
      case AppRoute.register:
      case AppRoute.registrationStatus:
      case AppRoute.passwordRecovery:
      case AppRoute.passwordRecoveryReset:
        return null;
      case AppRoute.dashboard:
      case AppRoute.dashboardStore:
      case AppRoute.sales:
      case AppRoute.returns:
      case AppRoute.finance:
      case AppRoute.purchases:
      case AppRoute.inventory:
      case AppRoute.agents:
      case AppRoute.settings:
        return shellIndex;
    }
  }

  UserPermission? get requiredPermission {
    switch (this) {
      case AppRoute.dashboard:
      case AppRoute.dashboardStore:
        return UserPermission.viewDashboard;
      case AppRoute.sales:
      case AppRoute.salesCard:
        return UserPermission.viewSales;
      case AppRoute.returns:
        return UserPermission.viewReturns;
      case AppRoute.finance:
        return UserPermission.viewFinance;
      case AppRoute.purchases:
        return UserPermission.viewPurchases;
      case AppRoute.inventory:
        return UserPermission.viewInventory;
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
