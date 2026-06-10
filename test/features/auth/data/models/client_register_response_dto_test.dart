import 'package:checks/checks.dart';
import 'package:colmeia/features/auth/data/models/client_register_response_dto.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClientRegisterResponseDto', () {
    test('should parse pending registration response with approval token', () {
      final dto = ClientRegisterResponseDto.fromJson(<String, dynamic>{
        'message': 'Registration pending approval',
        'approvalToken': 'token-123',
        'user': <String, dynamic>{
          'status': 'pending',
        },
      });

      final submission = dto.toEntity();
      check(submission.status).equals(ClientRegistrationStatus.pending);
      check(submission.message).equals('Registration pending approval');
      check(submission.pollToken).equals('token-123');
      check(submission.canPollStatus).isTrue();
    });

    test(
      'should prefer registrationPollToken over approvalToken in production',
      () {
        final dto = ClientRegisterResponseDto.fromJson(<String, dynamic>{
          'message': 'Client registration pending owner approval',
          'registrationPollToken': 'poll-prod-abc',
          'client': <String, dynamic>{
            'status': 'pending',
          },
        });

        final submission = dto.toEntity();
        check(submission.pollToken).equals('poll-prod-abc');
        check(submission.canPollStatus).isTrue();
      },
    );

    test(
      'should parse production-shaped response without approvalToken',
      () {
        final dto = ClientRegisterResponseDto.fromJson(<String, dynamic>{
          'message': 'Client registration pending owner approval',
          'registration_poll_token': 'poll-only-token',
          'client': <String, dynamic>{
            'status': 'pending',
          },
        });

        final submission = dto.toEntity();
        check(submission.pollToken).equals('poll-only-token');
        check(submission.canPollStatus).isTrue();
      },
    );

    test('should parse duplicate 202 response without poll token', () {
      final dto = ClientRegisterResponseDto.fromJson(<String, dynamic>{
        'message': 'If eligible, your registration request will be processed.',
        'duplicate': true,
      });

      final submission = dto.toEntity();
      check(submission.message).isNotNull().which((m) => m.contains('eligible'));
      check(submission.pollToken).isNull();
      check(submission.canPollStatus).isFalse();
      check(submission.duplicate).isTrue();
    });

    test('should default status to pending when body is empty', () {
      final dto = ClientRegisterResponseDto.fromJson(const <String, dynamic>{});

      check(dto.status).equals(ClientRegistrationStatus.pending);
    });
  });
}
