import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapToAppFailure', () {
    test('should preserve existing app failure', () {
      const failure = SessionFailure(
        message: 'Stored session has expired',
        userMessage: 'Sua sessao expirou.',
      );

      check(mapToAppFailure(failure)).equals(failure);
    });

    test('should map validation exception to validation failure', () {
      final failure = mapToAppFailure(
        _captureValidationError(),
      );

      check(failure).isA<ValidationFailure>();
      check(failure.displayMessage).contains('email');
    });

    test('should map unknown exceptions to clear client message', () {
      final failure = mapToAppFailure(
        StateError('boom'),
      );

      check(failure).isA<UnknownFailure>();
      check(failure.displayMessage).equals(
        'Ocorreu um erro inesperado. Tente novamente.',
      );
    });

    test('should prefer API message from Dio response body', () {
      final failure = mapToAppFailure(
        DioException(
          requestOptions: RequestOptions(path: '/client-auth/login'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/client-auth/login'),
            statusCode: 403,
            data: <String, dynamic>{
              'message': 'Sua conta esta pendente de aprovacao.',
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      check(failure).isA<NetworkFailure>();
      check(failure.displayMessage).equals(
        'Sua conta esta pendente de aprovacao.',
      );
    });

    test('should join validation errors from Dio response body', () {
      final failure = mapToAppFailure(
        DioException(
          requestOptions: RequestOptions(path: '/client-auth/register'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/client-auth/register'),
            statusCode: 400,
            data: <String, dynamic>{
              'errors': <String, dynamic>{
                'email': <String>['must be a valid email'],
                'password': <String>['must contain uppercase'],
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      check(failure.displayMessage).equals(
        'email: must be a valid email\npassword: must contain uppercase',
      );
    });
  });
}

Object _captureValidationError() {
  try {
    EmailAddress('invalid-email');
  } on Object catch (error) {
    return error;
  }

  throw StateError('Expected validation error');
}
