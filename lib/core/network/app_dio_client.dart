import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:dio/dio.dart';

abstract final class AppDioClient {
  static Dio create() {
    final baseOptions = BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      headers: <String, Object>{
        Headers.acceptHeader: Headers.jsonContentType,
      },
    );
    if (AppEnvironment.apiBaseUrl.isNotEmpty) {
      baseOptions.baseUrl = AppEnvironment.apiBaseUrl;
    }

    final dio = Dio(
      baseOptions,
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.debug(
            'HTTP request',
            context: <String, Object?>{
              'method': options.method,
              'path': options.uri.path,
              'query': options.uri.query,
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
            },
            error: error,
            stackTrace: error.stackTrace,
          );
          handler.next(error);
        },
      ),
    );

    return dio;
  }
}
