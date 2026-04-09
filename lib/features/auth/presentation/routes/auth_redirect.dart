import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:go_router/go_router.dart';

String? redirectWithAuthGuard({
  required AuthController authController,
  required CurrentUserContextController userContextController,
  required GoRouterState state,
}) {
  final matchedRoute = AppRoute.fromLocation(state.matchedLocation);
  final canAccessMatchedRoute = userContextController.canAccessRoute(matchedRoute);
  final canAccessDashboardHome = userContextController.canAccessRoute(
    AppRoute.dashboard,
  );

  final redirect = resolveAuthRedirect(
    isAuthenticated: authController.isAuthenticated,
    canAccessMatchedRoute: canAccessMatchedRoute,
    canAccessDashboardHome: canAccessDashboardHome,
    matchedRoute: matchedRoute,
    isUserContextLoading: userContextController.isLoadingInitial,
  );

  if (redirect != null) {
    AppLogger.debug(
      'Auth guard resolved route redirect',
      context: <String, Object?>{
        'operation': 'authGuardRedirect',
        'matchedRoute': matchedRoute.name,
        'redirect': redirect,
        'isAuthenticated': authController.isAuthenticated,
        'canAccessMatchedRoute': canAccessMatchedRoute,
        'canAccessDashboardHome': canAccessDashboardHome,
        'isUserContextLoading': userContextController.isLoadingInitial,
      },
    );
  }

  return redirect;
}

String? resolveAuthRedirect({
  required bool isAuthenticated,
  required bool canAccessMatchedRoute,
  required bool canAccessDashboardHome,
  required AppRoute matchedRoute,
  required bool isUserContextLoading,
}) {
  final isGuestOnlyRoute = switch (matchedRoute) {
    AppRoute.login ||
    AppRoute.register ||
    AppRoute.registrationStatus ||
    AppRoute.passwordRecovery ||
    AppRoute.passwordRecoveryReset => true,
    _ => false,
  };

  if (!isAuthenticated) {
    return isGuestOnlyRoute ? null : AppRoute.login.path;
  }

  if (isGuestOnlyRoute) {
    if (isUserContextLoading || canAccessDashboardHome) {
      return AppRoute.dashboard.path;
    }

    return AppRoute.settings.path;
  }

  if (canAccessMatchedRoute) {
    return null;
  }

  if (isUserContextLoading &&
      (matchedRoute == AppRoute.dashboard ||
          matchedRoute == AppRoute.dashboardStore)) {
    return null;
  }

  return AppRoute.settings.path;
}
