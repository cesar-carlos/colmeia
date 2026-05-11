import 'package:dio/dio.dart';

/// HTTP 5xx or transport timeouts typically returned when the hub / bridge is
/// overloaded or temporarily unavailable.
bool isTransientHubDioException(DioException exception) {
  final status = exception.response?.statusCode;
  if (status != null && status >= 500 && status < 600) {
    return true;
  }
  return switch (exception.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError => true,
    _ => false,
  };
}
