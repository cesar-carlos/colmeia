import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';

enum AppRoute {
  login(
    path: '/login',
    title: 'Entrar',
  ),
  register(
    path: '/register',
    title: 'Solicitar acesso',
  ),
  dashboardStore(
    path: '/dashboard/store/:storeId',
    title: 'Dashboard principal',
    shellIndex: 0,
  ),
  dashboard(
    path: '/dashboard',
    title: 'Dashboard principal',
    shellIndex: 0,
  ),
  reportDetail(
    path: '/reports/:reportId',
    title: 'Detalhes do relatorio',
    shellIndex: 1,
  ),
  reports(
    path: '/reports',
    title: 'Relatorios',
    shellIndex: 1,
  ),
  settings(
    path: '/settings',
    title: 'Configuracoes',
    shellIndex: 2,
  )
  ;

  const AppRoute({
    required this.path,
    required this.title,
    this.shellIndex,
  });

  final String path;
  final String title;
  final int? shellIndex;

  bool get isShellRoute => shellIndex != null;
  UserPermission? get requiredPermission {
    switch (this) {
      case AppRoute.reports:
      case AppRoute.reportDetail:
        return UserPermission.viewReports;
      case AppRoute.dashboard:
      case AppRoute.dashboardStore:
        return UserPermission.viewDashboard;
      case AppRoute.login:
      case AppRoute.register:
      case AppRoute.settings:
        return null;
    }
  }

  static const List<AppRoute> shellRoutes = <AppRoute>[
    dashboard,
    reports,
    settings,
  ];

  static AppRoute fromLocation(String location) {
    return AppRoute.values.firstWhere(
      (route) => route.matches(location),
      orElse: () => login,
    );
  }

  bool matches(String location) {
    final parameterMarkerIndex = path.indexOf('/:');
    if (parameterMarkerIndex != -1) {
      final prefix = path.substring(0, parameterMarkerIndex + 1);
      return location.startsWith(prefix);
    }

    return location == path || location.startsWith('$path/');
  }
}
