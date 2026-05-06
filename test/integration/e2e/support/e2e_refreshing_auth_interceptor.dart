import 'package:colmeia/core/network/auth_interceptor.dart';
import 'package:colmeia/core/network/auth_request_options.dart';
import 'package:colmeia/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:colmeia/features/auth/data/models/auth_session_model.dart';
import 'package:dio/dio.dart';

/// Mutable session for E2E so [E2eRefreshingAuthInterceptor] can rotate JWTs.
final class E2eAuthSessionHolder {
  AuthSessionModel? value;
}

/// Same policy as production auth interceptor: refresh shortly before
/// [AuthSessionModel.expiresAt] and retry once on HTTP 401. Use this for E2E
/// when the hub issues short-lived access tokens (e.g. ~15 min).
final class E2eRefreshingAuthInterceptor extends QueuedInterceptor {
  E2eRefreshingAuthInterceptor({
    required Dio dio,
    required AuthRemoteDataSource refreshAuthApi,
    required E2eAuthSessionHolder sessionHolder,
    Duration proactiveRefreshWindow =
        AuthInterceptor.defaultProactiveRefreshWindow,
    DateTime Function()? clock,
  }) : _dio = dio,
       _refreshAuthApi = refreshAuthApi,
       _sessionHolder = sessionHolder,
       _proactiveRefreshWindow = proactiveRefreshWindow,
       _clock = clock ?? DateTime.now;

  final Dio _dio;
  final AuthRemoteDataSource _refreshAuthApi;
  final E2eAuthSessionHolder _sessionHolder;
  final Duration _proactiveRefreshWindow;
  final DateTime Function() _clock;
  Future<void>? _inFlightRefresh;

  static const String _authorizationHeader = 'Authorization';
  static const Set<int> _sessionInvalidationStatusCodes = <int>{
    400,
    401,
    403,
  };

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.headers.containsKey(_authorizationHeader)) {
      handler.next(options);
      return;
    }

    var session = _sessionHolder.value;
    if (session != null &&
        session.accessToken.isNotEmpty &&
        _shouldRefreshProactively(session.expiresAt, options)) {
      try {
        await _refreshSessionSingleFlight();
        session = _sessionHolder.value ?? session;
      } on Object {
        // Same best-effort as AuthInterceptor: send current token; 401 path
        // may still recover after a successful refresh there.
      }
    }

    session = _sessionHolder.value;
    if (session != null && session.accessToken.isNotEmpty) {
      options.headers[_authorizationHeader] = 'Bearer ${session.accessToken}';
    }
    handler.next(options);
  }

  bool _shouldRefreshProactively(DateTime expiresAt, RequestOptions options) {
    if (options.data is FormData) {
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
    final cutoff = expiresAt.subtract(window);
    return !now.isBefore(cutoff);
  }

  Future<void> _refreshSessionSingleFlight() async {
    final inFlight = _inFlightRefresh;
    if (inFlight != null) {
      await inFlight;
      return;
    }
    final op = _performRefresh();
    _inFlightRefresh = op;
    try {
      await op;
    } finally {
      _inFlightRefresh = null;
    }
  }

  Future<void> _performRefresh() async {
    final current = _sessionHolder.value;
    if (current == null) {
      return;
    }
    try {
      final refreshed = await _refreshAuthApi.refreshSession(
        currentSession: current,
      );
      _sessionHolder.value = refreshed;
    } on DioException catch (error) {
      if (_shouldInvalidateSession(error.response?.statusCode)) {
        _sessionHolder.value = null;
      }
      rethrow;
    }
  }

  bool _shouldInvalidateSession(int? statusCode) {
    return statusCode != null &&
        _sessionInvalidationStatusCodes.contains(statusCode);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final request = err.requestOptions;
    if (response?.statusCode != 401 ||
        request.data is FormData ||
        request.extra[AuthRequestOptions.disableAuthRetry] == true ||
        request.extra[AuthRequestOptions.retryAttempted] == true) {
      handler.next(err);
      return;
    }

    try {
      await _refreshSessionSingleFlight();
      final refreshedAccessToken = _sessionHolder.value?.accessToken;
      if (refreshedAccessToken == null || refreshedAccessToken.isEmpty) {
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
}
