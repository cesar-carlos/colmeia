import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/config/app_feature_flags.dart';
import 'package:go_router/go_router.dart';

/// True when [path] (e.g. [Uri.path]) targets URLs removed with the reports
/// module; used for bookmark redirects.
bool shouldRedirectLegacyReportsPath(String path) {
  return path == '/reports' || path.startsWith('/reports/');
}

bool isExternalClientRegistrationReviewPath(String path) {
  return path == '/client-auth/registration/review' ||
      path == '/api/v1/client-auth/registration/review';
}

bool isExternalClientPasswordRecoveryReviewPath(String path) {
  return path == '/client-auth/password-recovery/review' ||
      path == '/api/v1/client-auth/password-recovery/review';
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
  final token = state.uri.queryParameters['token']?.trim();
  if (token != null && token.isNotEmpty) {
    if (isExternalClientRegistrationReviewPath(state.uri.path)) {
      return Uri(
        path: AppRoute.registrationStatus.path,
        queryParameters: <String, String>{'token': token},
      ).toString();
    }
    if (isExternalClientPasswordRecoveryReviewPath(state.uri.path)) {
      return Uri(
        path: AppRoute.passwordRecoveryReset.path,
        queryParameters: <String, String>{'token': token},
      ).toString();
    }
  }
  return null;
}
