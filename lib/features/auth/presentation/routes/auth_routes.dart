import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/auth/presentation/pages/login_page.dart';
import 'package:colmeia/features/auth/presentation/pages/register_page.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> buildAuthRoutes() {
  return <RouteBase>[
    GoRoute(
      name: AppRoute.login.name,
      path: AppRoute.login.path,
      builder: (context, state) {
        return const LoginPage();
      },
    ),
    GoRoute(
      name: AppRoute.register.name,
      path: AppRoute.register.path,
      builder: (context, state) {
        return const RegisterPage();
      },
    ),
  ];
}
