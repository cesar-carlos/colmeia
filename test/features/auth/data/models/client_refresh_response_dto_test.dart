import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:colmeia/features/auth/data/models/client_refresh_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClientRefreshResponseDto', () {
    test('should parse tokens and derive expiry from jwt payload', () {
      final dto = ClientRefreshResponseDto.fromJson(<String, dynamic>{
        'accessToken': _jwtWithExpiry(2_209_075_200),
        'refreshToken': 'refresh-token',
      });

      check(dto.tokens.accessToken).isNotEmpty();
      check(dto.tokens.refreshToken).equals('refresh-token');
      check(dto.tokens.expiresAt.year).equals(2040);
    });
  });
}

String _jwtWithExpiry(int exp) {
  final payload = base64Url.encode(utf8.encode('{"exp":$exp}'));
  return 'header.${base64Url.normalize(payload)}.signature';
}
