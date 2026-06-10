import 'package:checks/checks.dart';
import 'package:colmeia/features/auth/data/models/client_registration_status_response_dto.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClientRegistrationStatusResponseDto', () {
    test('should parse approved status', () {
      final dto = ClientRegistrationStatusResponseDto.fromJson(
        const <String, dynamic>{
          'status': 'approved',
        },
      );

      check(dto.status).equals(ClientRegistrationStatus.approved);
    });

    test('should parse blocked status', () {
      final dto = ClientRegistrationStatusResponseDto.fromJson(
        const <String, dynamic>{
          'status': 'blocked',
        },
      );

      check(dto.status).equals(ClientRegistrationStatus.blocked);
    });

    test('should parse wrapped pending status', () {
      final dto = ClientRegistrationStatusResponseDto.fromJson(
        const <String, dynamic>{
          'data': <String, dynamic>{
            'status': 'pending',
          },
        },
      );

      check(dto.status).equals(ClientRegistrationStatus.pending);
    });
  });
}
