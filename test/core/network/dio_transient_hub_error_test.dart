import 'package:colmeia/core/network/dio_transient_hub_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isTransientHubDioException', () {
    test('is true for HTTP 503', () {
      final e = DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 503,
        ),
        type: DioExceptionType.badResponse,
      );
      expect(isTransientHubDioException(e), isTrue);
    });

    test('is false for HTTP 404', () {
      final e = DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 404,
        ),
        type: DioExceptionType.badResponse,
      );
      expect(isTransientHubDioException(e), isFalse);
    });

    test('is true for connection timeout', () {
      final e = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionTimeout,
      );
      expect(isTransientHubDioException(e), isTrue);
    });
  });
}
