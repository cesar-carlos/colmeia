import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
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
