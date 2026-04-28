import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/network/api_routes.dart';
import 'package:colmeia/core/network/auth_refresh_coordinator.dart';
import 'package:colmeia/core/network/auth_request_options.dart';
import 'package:colmeia/core/network/auth_session_accessor.dart';
import 'package:dio/dio.dart';

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required Dio dio,
    required AuthSessionAccessor sessionAccessor,
    required AuthRefreshCoordinator refreshCoordinator,
    Duration proactiveRefreshWindow = defaultProactiveRefreshWindow,
    DateTime Function()? clock,
  }) : _dio = dio,
       _sessionAccessor = sessionAccessor,
       _refreshCoordinator = refreshCoordinator,
       _proactiveRefreshWindow = proactiveRefreshWindow,
       _clock = clock ?? DateTime.now;

  /// Default 30 s — wide enough to absorb mobile clock drift / NTP
  /// jitter and small enough not to refresh tokens that still have
  /// plenty of life. Tunable per build (e.g. flaky web sessions might
  /// prefer 60 s).
  static const Duration defaultProactiveRefreshWindow = Duration(seconds: 30);

  final Dio _dio;
  final AuthSessionAccessor _sessionAccessor;
  final AuthRefreshCoordinator _refreshCoordinator;
  final Duration _proactiveRefreshWindow;
  final DateTime Function() _clock;
  static const String _authorizationHeader = 'Authorization';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_shouldSkipAuth(options)) {
      handler.next(options);
      return;
    }

    if (options.headers.containsKey(_authorizationHeader)) {
      handler.next(options);
      return;
    }

    var session = await _sessionAccessor.read();

    // Proactive refresh: when the stored access token is already past
    // `expiresAt` (or about to expire within `_proactiveRefreshWindow`),
    // ask the coordinator to refresh BEFORE we attach the header.
    // Saves the round-trip cost of the 401 → refresh → retry path on
    // every request inside the window, and avoids a thundering herd
    // when the app wakes up from background with an expired session.
    //
    // Skipped on FormData uploads (Dio cannot replay multipart bodies
    // through the same RequestOptions) and on requests that opted out
    // of refresh — same allow-list as `onError`.
    if (session != null &&
        session.accessToken.isNotEmpty &&
        _shouldRefreshProactively(session.expiresAt, options)) {
      try {
        final refreshed = await _refreshCoordinator.refreshAccessToken();
        if (refreshed != null && refreshed.isNotEmpty) {
          // Re-read to get the freshly persisted session (with new
          // `expiresAt`) so the header below uses it.
          session = await _sessionAccessor.read() ?? session;
        }
      } on Object catch (error, stackTrace) {
        // Best-effort — if proactive refresh fails (network down,
        // server hiccup), fall back to sending the stale token and
        // let the existing 401 path do its job. Logged at warning
        // (above debug) because a recurring failure here means the
        // 401-driven retry is the only thing keeping the session
        // alive.
        AppLogger.warning(
          'Proactive token refresh failed; sending stored token',
          context: <String, Object?>{
            'operation': 'authInterceptor.proactiveRefresh',
          },
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    if (session != null && session.accessToken.isNotEmpty) {
      options.headers[_authorizationHeader] = 'Bearer ${session.accessToken}';
    }
    handler.next(options);
  }

  bool _shouldRefreshProactively(
    DateTime expiresAt,
    RequestOptions options,
  ) {
    if (options.data is FormData) {
      // Same reason we skip multipart on the 401 path: Dio cannot
      // replay the body, and a proactive refresh that mutates the
      // session would only help the 401 fallback that we already
      // disabled below for FormData.
      return false;
    }
    if (options.extra[AuthRequestOptions.disableAuthRetry] == true) {
      return false;
    }
    final window = _proactiveRefreshWindow;
    if (window <= Duration.zero) {
      return false;
    }
    final now = _clock();
    // Cutoff = expiresAt - window. We refresh as soon as `now` reaches
    // or passes the cutoff, mirroring `AuthSession.isExpiringWithin`.
    final cutoff = expiresAt.subtract(window);
    return !now.isBefore(cutoff);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Hub `credentialAuthRateLimit` applies to `/client-auth/login`. This
    // interceptor never calls login on HTTP 401 — only
    // `AuthRefreshCoordinator.refreshAccessToken()` → `/client-auth/refresh`.
    // Repeated 429s attributed to "login" are usually separate `login()` calls
    // (e.g. one per E2E process) or another client, not this path.
    final response = err.response;
    final request = err.requestOptions;
    if (response?.statusCode != 401 ||
        _shouldSkipAuth(request) ||
        request.data is FormData ||
        request.extra[AuthRequestOptions.disableAuthRetry] == true ||
        request.extra[AuthRequestOptions.retryAttempted] == true) {
      handler.next(err);
      return;
    }

    try {
      final refreshedAccessToken = await _refreshCoordinator
          .refreshAccessToken();
      if (refreshedAccessToken == null) {
        handler.next(err);
        return;
      }

      final retryHeaders = Map<String, dynamic>.from(request.headers)
        ..[_authorizationHeader] = 'Bearer $refreshedAccessToken';
      final retryExtra = Map<String, dynamic>.from(request.extra)
        ..[AuthRequestOptions.retryAttempted] = true;
      final retryRequest = request.copyWith(
        headers: retryHeaders,
        extra: retryExtra,
      );
      final retryResponse = await _dio.fetch<dynamic>(retryRequest);
      handler.resolve(retryResponse);
    } on Object {
      handler.next(err);
    }
  }

  bool _shouldSkipAuth(RequestOptions options) {
    if (options.extra[AuthRequestOptions.skipAuth] == true) {
      return true;
    }
    final normalizedPath = _normalizePath(options.path);
    return ClientAuthApiRoutes.unauthenticated.contains(normalizedPath);
  }

  String _normalizePath(String rawPath) {
    final parsed = Uri.tryParse(rawPath);
    if (parsed == null) {
      return rawPath;
    }
    if (parsed.hasScheme || parsed.host.isNotEmpty) {
      return parsed.path;
    }
    return rawPath;
  }
}
