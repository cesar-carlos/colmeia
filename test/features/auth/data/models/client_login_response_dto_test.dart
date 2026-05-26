import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:colmeia/features/auth/data/models/client_login_response_dto.dart';
import 'package:colmeia/shared/identity/client_account_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClientLoginResponseDto', () {
    test('should parse nested user and token payload', () {
      final dto = ClientLoginResponseDto.fromJson(<String, dynamic>{
        'accessToken': _jwtWithExpiry(2_209_075_200),
        'refreshToken': 'refresh-token',
        'success': true,
        'user': <String, dynamic>{
          'id': 'client-1',
          'email': 'client@example.com',
          'role': 'client',
          'status': 'active',
          'name': 'Camila',
          'lastName': 'Oliveira',
          'mobile': '+5511999999999',
        },
      });

      check(dto.user.id).equals('client-1');
      check(dto.user.displayName).equals('Camila Oliveira');

      final session = dto.toSessionModel();
      check(session.userId).equals('client-1');
      check(session.email).equals('client@example.com');
      check(session.role).equals('client');
      check(session.accountStatus).equals(ClientAccountStatus.active);
      check(session.accessToken).isNotEmpty();
    });

    test('should read wrapped payload and fallback to token alias', () {
      final dto = ClientLoginResponseDto.fromJson(<String, dynamic>{
        'data': <String, dynamic>{
          'token': _jwtWithExpiry(2_209_075_200),
          'refreshToken': 'refresh-token',
          'client': <String, dynamic>{
            'sub': 'client-2',
            'email': 'client2@example.com',
            'status': 'pending',
          },
        },
      });

      check(dto.user.id).equals('client-2');
      check(dto.user.accountStatus).equals(ClientAccountStatus.pending);
      check(dto.tokens.refreshToken).equals('refresh-token');
    });
  });
}

String _jwtWithExpiry(int exp) {
  final payload = base64Url.encode(utf8.encode('{"exp":$exp}'));
  return 'header.${base64Url.normalize(payload)}.signature';
}
