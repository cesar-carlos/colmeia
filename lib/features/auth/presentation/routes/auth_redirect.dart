import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:go_router/go_router.dart';

String? redirectWithAuthGuard({
  required AuthController authController,
  required CurrentUserContextController userContextController,
  required GoRouterState state,
}) {
  final matchedRoute = AppRoute.fromLocation(state.matchedLocation);

  return resolveAuthRedirect(
    isAuthenticated: authController.isAuthenticated,
    canAccessRoute: userContextController.canAccessRoute(matchedRoute),
    matchedRoute: matchedRoute,
    isUserContextLoading: userContextController.isLoadingInitial,
  );
}

String? resolveAuthRedirect({
  required bool isAuthenticated,
  required bool canAccessRoute,
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
    return AppRoute.settings.path;
  }

  if (canAccessRoute) {
    return null;
  }

  if (isUserContextLoading &&
      (matchedRoute == AppRoute.dashboard ||
          matchedRoute == AppRoute.dashboardStore)) {
    return null;
  }

  return AppRoute.settings.path;
}
