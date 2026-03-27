import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:go_router/go_router.dart';

String? redirectWithAuthGuard({
  required AuthController authController,
  required GoRouterState state,
}) {
  final matchedRoute = AppRoute.fromLocation(state.matchedLocation);

  return resolveAuthRedirect(
    isAuthenticated: authController.isAuthenticated,
    matchedRoute: matchedRoute,
  );
}

String? resolveAuthRedirect({
  required bool isAuthenticated,
  required AppRoute matchedRoute,
}) {
  final isGuestOnlyRoute = switch (matchedRoute) {
    AppRoute.login || AppRoute.register => true,
    _ => false,
  };

  if (!isAuthenticated) {
    return isGuestOnlyRoute ? null : AppRoute.login.path;
  }

  return isGuestOnlyRoute ? AppRoute.dashboard.path : null;
}
