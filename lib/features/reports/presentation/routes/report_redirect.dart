import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';

String? redirectWithReportAccessGuard({
  required CurrentUserContextController userContextController,
  required AppRoute matchedRoute,
  String? reportId,
}) {
  if (!_requiresReportAccess(matchedRoute)) {
    return null;
  }

  if (matchedRoute == AppRoute.reports) {
    return userContextController.hasAnyReportAccess()
        ? null
        : AppRoute.dashboard.path;
  }

  if (reportId != null && userContextController.canAccessReport(reportId)) {
    return null;
  }

  return AppRoute.dashboard.path;
}

bool _requiresReportAccess(AppRoute route) {
  return route == AppRoute.reports || route == AppRoute.reportDetail;
}
