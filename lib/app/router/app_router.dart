import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/router/app_shell_routes.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/auth/presentation/routes/auth_redirect.dart';
import 'package:colmeia/features/auth/presentation/routes/auth_routes.dart';
import 'package:colmeia/features/reports/presentation/routes/report_redirect.dart';
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
      final authRedirect = redirectWithAuthGuard(
        authController: _authController,
        state: state,
      );
      if (authRedirect != null) {
        return authRedirect;
      }

      return redirectWithReportAccessGuard(
        userContextController: _userContextController,
        matchedRoute: AppRoute.fromLocation(state.matchedLocation),
        reportId: state.pathParameters['reportId'],
      );
    },
    routes: <RouteBase>[
      ...buildAuthRoutes(),
      ...buildAppShellRoutes(),
    ],
  );
}
