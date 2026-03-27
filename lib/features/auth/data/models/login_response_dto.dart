import 'package:colmeia/features/auth/data/models/auth_session_model.dart';

class LoginResponseDto {
  const LoginResponseDto({
    required this.userId,
    required this.email,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    String stringFrom(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
      throw FormatException('Missing key for any of: ${keys.join(', ')}');
    }

    DateTime expiresAtFrom(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is String && value.isNotEmpty) {
          return DateTime.parse(value);
        }
      }
      return DateTime.now().add(const Duration(hours: 8));
    }

    return LoginResponseDto(
      userId: stringFrom(<String>['userId', 'user_id', 'id']),
      email: stringFrom(<String>['email']),
      accessToken: stringFrom(<String>['accessToken', 'access_token', 'token']),
      refreshToken: stringFrom(<String>[
        'refreshToken',
        'refresh_token',
      ]),
      expiresAt: expiresAtFrom(<String>[
        'expiresAt',
        'expires_at',
        'accessTokenExpiresAt',
      ]),
    );
  }

  final String userId;
  final String email;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  AuthSessionModel toModel() {
    return AuthSessionModel(
      userId: userId,
      email: email,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }
}
