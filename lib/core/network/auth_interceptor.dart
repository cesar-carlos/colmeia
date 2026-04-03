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
  }) : _dio = dio,
       _sessionAccessor = sessionAccessor,
       _refreshCoordinator = refreshCoordinator;

  final Dio _dio;
  final AuthSessionAccessor _sessionAccessor;
  final AuthRefreshCoordinator _refreshCoordinator;
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

    final session = await _sessionAccessor.read();
    if (session != null && session.accessToken.isNotEmpty) {
      options.headers[_authorizationHeader] = 'Bearer ${session.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
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
