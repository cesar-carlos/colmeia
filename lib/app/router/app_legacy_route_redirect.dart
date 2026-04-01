import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/config/app_feature_flags.dart';
import 'package:go_router/go_router.dart';

/// True when [path] (e.g. [Uri.path]) targets URLs removed with the reports
/// module; used for bookmark redirects.
bool shouldRedirectLegacyReportsPath(String path) {
  return path == '/reports' || path.startsWith('/reports/');
}

/// Sends users away from removed report URLs (e.g. saved links). Runs before
/// auth guards so unauthenticated visitors are forwarded to `/dashboard` and
/// then to login by the existing auth redirect.
String? redirectRemovedReportRoutes(GoRouterState state) {
  if (!AppFeatureFlags.legacyReportsPathsRedirectToDashboard) {
    return null;
  }
  if (shouldRedirectLegacyReportsPath(state.uri.path)) {
    return AppRoute.dashboard.path;
  }
  return null;
}
