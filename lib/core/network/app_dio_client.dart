import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/network/auth_interceptor.dart';
import 'package:dio/dio.dart';

abstract final class AppDioClient {
  static const String _defaultApiNamespacePath = '/api/v1';
  static const Set<String> _sensitiveQueryKeys = <String>{
    'token',
    'accesstoken',
    'refreshtoken',
    'authorization',
    'password',
    'currentpassword',
    'newpassword',
  };

  static BaseOptions createBaseOptions() {
    final options = BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      headers: <String, Object>{
        Headers.acceptHeader: Headers.jsonContentType,
      },
    );
    if (AppEnvironment.apiBaseUrl.isNotEmpty) {
      options.baseUrl = normalizeBaseUrl(AppEnvironment.apiBaseUrl);
    } else if (!AppEnvironment.useFakeBackend) {
      AppLogger.warning(
        'API_BASE_URL is empty while USE_FAKE_BACKEND is false; '
        'relative HTTP calls may fail until a base URL is configured.',
        context: const <String, Object?>{
          'component': 'AppDioClient',
        },
      );
    }
    return options;
  }

  static Dio create({
    AuthInterceptor? authInterceptor,
  }) {
    final dio = Dio(createBaseOptions());
    _addLoggingInterceptor(dio);
    if (authInterceptor != null) {
      dio.interceptors.add(authInterceptor);
    }
    return dio;
  }

  /// Header propagated by the hub when `HUB_INSTANCE_ID` is configured
  /// (`plug_server/docs/client_agent_business_rules.md` §3.4). Captured
  /// here purely for observability — sticky-session quirks become much
  /// easier to debug when the log line tells you which replica answered
  /// each call.
  static const String _hubInstanceIdHeader = 'X-Hub-Instance-Id';

  static void _addLoggingInterceptor(Dio dio) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.debug(
            'HTTP request',
            context: <String, Object?>{
              'method': options.method,
              'path': options.uri.path,
              'query': _sanitizeQueryParameters(options.uri.queryParametersAll),
            },
          );
          handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.info(
            'HTTP response',
            context: <String, Object?>{
              'method': response.requestOptions.method,
              'path': response.requestOptions.uri.path,
              'statusCode': response.statusCode,
              'hubInstanceId': ?_extractHubInstanceId(response.headers.map),
            },
          );
          handler.next(response);
        },
        onError: (error, handler) {
          AppLogger.warning(
            'HTTP request failed',
            context: <String, Object?>{
              'method': error.requestOptions.method,
              'path': error.requestOptions.uri.path,
              'statusCode': error.response?.statusCode,
              'hubInstanceId': ?_extractHubInstanceId(
                error.response?.headers.map,
              ),
            },
            error: error,
            stackTrace: error.stackTrace,
          );
          handler.next(error);
        },
      ),
    );
  }

  static String? _extractHubInstanceId(Map<String, List<String>>? headers) {
    if (headers == null) {
      return null;
    }
    final lower = _hubInstanceIdHeader.toLowerCase();
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == lower) {
        for (final value in entry.value) {
          final trimmed = value.trim();
          if (trimmed.isNotEmpty) {
            return trimmed;
          }
        }
      }
    }
    return null;
  }

  static Map<String, Object?>? _sanitizeQueryParameters(
    Map<String, List<String>> queryParameters,
  ) {
    if (queryParameters.isEmpty) {
      return null;
    }

    return queryParameters.map<String, Object?>((key, values) {
      final normalizedKey = key.trim().toLowerCase();
      final sanitizedValue = _sensitiveQueryKeys.contains(normalizedKey)
          ? const <String>['***']
          : values;
      return MapEntry<String, Object?>(key, sanitizedValue);
    });
  }

  static String normalizeBaseUrl(String rawBaseUrl) {
    final trimmed = rawBaseUrl.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final uri = Uri.parse(trimmed);
    final normalizedPath = switch (uri.path) {
      '' || '/' => _defaultApiNamespacePath,
      final path when path.endsWith('/') => path.substring(0, path.length - 1),
      final path => path,
    };

    return uri.replace(path: normalizedPath).toString();
  }
}
