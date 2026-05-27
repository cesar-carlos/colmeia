import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/client_agents/data/validation/client_agents_id_validators.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  group('requireNonEmptyId', () {
    test('returns the trimmed value when input is not blank', () {
      final result = requireNonEmptyId<Unit>(
        '  hello  ',
        technicalMessage: 'technical',
        userMessage: 'user',
      );

      expect(result.trimmed, 'hello');
      expect(result.failure, isNull);
    });

    test('returns a failure with both messages when input is null', () {
      final result = requireNonEmptyId<Unit>(
        null,
        technicalMessage: 'tech',
        userMessage: 'usr',
      );

      expect(result.trimmed, '');
      final failure = result.failure;
      expect(failure, isNotNull);
      final inner = failure!.exceptionOrNull()!;
      expect(inner, isA<ValidationFailure>());
      expect((inner as ValidationFailure).message, 'tech');
      expect(inner.displayMessage, 'usr');
    });

    test('returns a failure when input is only whitespace', () {
      final result = requireNonEmptyId<Unit>(
        '   ',
        technicalMessage: 'tech',
        userMessage: 'usr',
      );

      expect(result.failure, isNotNull);
    });
  });

  group('requireAgentId', () {
    test('uses the canonical agent-id error messages on blank input', () {
      final result = requireAgentId<Unit>('');
      final failure = result.failure!.exceptionOrNull();
      expect(failure, isA<ValidationFailure>());
      expect((failure! as ValidationFailure).message, 'Agent id is empty');
      expect(failure.displayMessage, 'Invalid agent identifier.');
    });
  });

  group('requireRequestId', () {
    test('uses the canonical request-id error messages on blank input', () {
      final result = requireRequestId<Unit>('   ');
      final failure = result.failure!.exceptionOrNull();
      expect(failure, isA<ValidationFailure>());
      expect((failure! as ValidationFailure).message, 'Request id is empty');
      expect(failure.displayMessage, 'Invalid request identifier.');
    });
  });

  group('requireClientAccessToken', () {
    test('uses the canonical access-token error messages on blank input', () {
      final result = requireClientAccessToken<Unit>(null);
      final failure = result.failure!.exceptionOrNull();
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure! as ValidationFailure).message,
        'Client access token is empty',
      );
      expect(failure.displayMessage, 'Invalid access link.');
    });
  });
}
