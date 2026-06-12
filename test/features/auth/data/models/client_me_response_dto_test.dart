import 'package:checks/checks.dart';
import 'package:colmeia/features/auth/data/models/client_me_response_dto.dart';
import 'package:colmeia/shared/identity/client_account_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClientMeResponseDto', () {
    test('should parse nested user profile', () {
      final dto = ClientMeResponseDto.fromJson(<String, dynamic>{
        'user': <String, dynamic>{
          'id': 'client-1',
          'email': 'client@example.com',
          'role': 'client',
          'status': 'active',
          'name': 'Camila',
          'lastName': 'Oliveira',
          'celular': '+5511999999999',
        },
      });

      check(dto.user.id).equals('client-1');
      check(dto.user.displayName).equals('Camila Oliveira');
      check(dto.user.accountStatus).equals(ClientAccountStatus.active);
    });
  });
}
