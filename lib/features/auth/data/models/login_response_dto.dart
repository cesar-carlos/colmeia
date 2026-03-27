import 'package:colmeia/features/auth/data/models/auth_session_model.dart';

/// Canonical JSON key aliases for login/refresh payloads (snake_case + camelCase).
abstract final class LoginResponseJsonKeys {
  static const List<String> userId = <String>['userId', 'user_id', 'id'];
  static const List<String> email = <String>['email'];
  static const List<String> accessToken = <String>[
    'accessToken',
    'access_token',
    'token',
  ];
  static const List<String> refreshToken = <String>[
    'refreshToken',
    'refresh_token',
  ];
  static const List<String> expiresAt = <String>[
    'expiresAt',
    'expires_at',
    'accessTokenExpiresAt',
  ];
}

class LoginResponseDto {
  const LoginResponseDto({
    required this.userId,
    required this.email,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      userId: _readNonEmptyString(json, LoginResponseJsonKeys.userId, 'userId'),
      email: _readNonEmptyString(json, LoginResponseJsonKeys.email, 'email'),
      accessToken: _readNonEmptyString(
        json,
        LoginResponseJsonKeys.accessToken,
        'accessToken',
      ),
      refreshToken: _readNonEmptyString(
        json,
        LoginResponseJsonKeys.refreshToken,
        'refreshToken',
      ),
      expiresAt: _readExpiresAt(json, LoginResponseJsonKeys.expiresAt),
    );
  }

  static String _readNonEmptyString(
    Map<String, dynamic> json,
    List<String> keys,
    String logicalName,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    throw FormatException(
      'Login response missing non-empty string for $logicalName '
      '(tried: ${keys.join(', ')})',
    );
  }

  static DateTime _readExpiresAt(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value);
      }
    }
    return DateTime.now().add(const Duration(hours: 8));
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
