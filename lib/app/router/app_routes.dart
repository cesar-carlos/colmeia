import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';

enum AppRoute {
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
    title: 'Dashboard principal',
    shellIndex: 0,
  ),
  dashboard(
    path: '/dashboard',
    title: 'Dashboard principal',
    shellIndex: 0,
  ),
  settings(
    path: '/settings',
    title: 'Perfil',
    shellIndex: 1,
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
      case AppRoute.dashboard:
      case AppRoute.dashboardStore:
        return UserPermission.viewDashboard;
      case AppRoute.login:
      case AppRoute.register:
      case AppRoute.registrationStatus:
      case AppRoute.passwordRecovery:
      case AppRoute.passwordRecoveryReset:
      case AppRoute.settings:
        return null;
    }
  }

  static const List<AppRoute> shellRoutes = <AppRoute>[
    dashboard,
    settings,
  ];

  static AppRoute fromLocation(String location) {
    final matchedRoutes = AppRoute.values
        .where((route) => route.matches(location))
        .toList(growable: false);
    if (matchedRoutes.isEmpty) {
      return login;
    }

    matchedRoutes.sort(
      (left, right) => right.path.length.compareTo(left.path.length),
    );
    return matchedRoutes.first;
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
