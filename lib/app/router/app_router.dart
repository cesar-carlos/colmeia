import 'package:colmeia/app/router/app_legacy_route_redirect.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/router/app_shell_routes.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/auth/presentation/routes/auth_redirect.dart';
import 'package:colmeia/features/auth/presentation/routes/auth_routes.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  AppRouter(
    this._authController,
    this._userContextController,
  );

  final AuthController _authController;
  final CurrentUserContextController _userContextController;

  late final GoRouter router = GoRouter(
    initialLocation: AppRoute.dashboard.path,
    refreshListenable: Listenable.merge(<Listenable>[
      _authController,
      _userContextController,
    ]),
    redirect: (context, state) {
      final legacyRedirect = redirectRemovedReportRoutes(state);
      if (legacyRedirect != null) {
        return legacyRedirect;
      }
      return redirectWithAuthGuard(
        authController: _authController,
        state: state,
      );
    },
    routes: <RouteBase>[
      ...buildAuthRoutes(),
      ...buildAppShellRoutes(),
    ],
  );
}
