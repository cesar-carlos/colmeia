import 'package:colmeia/features/auth/data/models/login_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginResponseDto', () {
    test('should parse camelCase payload', () {
      final dto = LoginResponseDto.fromJson(<String, dynamic>{
        'userId': 'u1',
        'email': 'a@b.com',
        'accessToken': 'at',
        'refreshToken': 'rt',
        'expiresAt': '2030-01-01T00:00:00.000Z',
      });

      expect(dto.userId, 'u1');
      expect(dto.email, 'a@b.com');
      expect(dto.accessToken, 'at');
      expect(dto.refreshToken, 'rt');
      expect(dto.expiresAt.year, 2030);
    });

    test('should parse snake_case aliases', () {
      final dto = LoginResponseDto.fromJson(<String, dynamic>{
        'user_id': 'u2',
        'email': 'x@y.com',
        'access_token': 'at2',
        'refresh_token': 'rt2',
        'expires_at': '2031-06-15T12:00:00.000Z',
      });

      expect(dto.userId, 'u2');
      expect(dto.accessToken, 'at2');
      expect(dto.refreshToken, 'rt2');
      expect(dto.expiresAt.month, 6);
    });

    test('should throw FormatException when required string keys missing', () {
      expect(
        () => LoginResponseDto.fromJson(<String, dynamic>{
          'email': 'a@b.com',
          'accessToken': 'at',
          'refreshToken': 'rt',
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('userId'),
          ),
        ),
      );
    });

    test('should default expiresAt when expiry keys absent', () {
      final before = DateTime.now();
      final dto = LoginResponseDto.fromJson(<String, dynamic>{
        'userId': 'u1',
        'email': 'a@b.com',
        'accessToken': 'at',
        'refreshToken': 'rt',
      });
      final after = DateTime.now().add(const Duration(hours: 9));

      expect(dto.expiresAt.isAfter(before), isTrue);
      expect(dto.expiresAt.isBefore(after), isTrue);
    });
  });
}
