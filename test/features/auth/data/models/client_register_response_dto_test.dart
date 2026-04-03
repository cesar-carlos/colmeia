import 'package:checks/checks.dart';
import 'package:colmeia/features/auth/data/models/client_register_response_dto.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClientRegisterResponseDto', () {
    test('should parse pending registration response', () {
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
      check(submission.approvalToken).equals('token-123');
      check(submission.canPollStatus).isTrue();
    });

    test('should default status to pending when body is empty', () {
      final dto = ClientRegisterResponseDto.fromJson(const <String, dynamic>{});

      check(dto.status).equals(ClientRegistrationStatus.pending);
    });
  });
}
