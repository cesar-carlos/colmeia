import 'package:colmeia/features/auth/data/models/auth_session_model.dart';
import 'package:colmeia/features/auth/data/models/auth_token_expiry_decoder.dart';
import 'package:colmeia/features/auth/data/models/client_auth_json_reader.dart';
import 'package:colmeia/features/auth/domain/entities/client_account_status.dart';

class ClientAuthTokensDto {
  const ClientAuthTokensDto({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.success,
  });

  factory ClientAuthTokensDto.fromJson(Map<String, dynamic> json) {
    return ClientAuthTokensDto(
      accessToken: readRequiredString(
        json,
        const <String>['accessToken', 'access_token', 'token'],
        logicalName: 'accessToken',
      ),
      refreshToken: readRequiredString(
        json,
        const <String>['refreshToken', 'refresh_token'],
        logicalName: 'refreshToken',
      ),
      expiresAt: _readExpiresAt(json),
      success: json['success'] as bool?,
    );
  }

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final bool? success;

  AuthSessionModel toSessionModel({
    required String userId,
    required String email,
    String? role,
    ClientAccountStatus accountStatus = ClientAccountStatus.unknown,
  }) {
    return AuthSessionModel(
      userId: userId,
      email: email,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      role: role,
      accountStatus: accountStatus,
    );
  }

  static DateTime _readExpiresAt(Map<String, dynamic> json) {
    final rawExpiry = readOptionalString(
      json,
      const <String>['expiresAt', 'expires_at', 'accessTokenExpiresAt'],
    );
    if (rawExpiry != null) {
      return DateTime.parse(rawExpiry);
    }

    final accessToken = readRequiredString(
      json,
      const <String>['accessToken', 'access_token', 'token'],
      logicalName: 'accessToken',
    );
    return deriveTokenExpiry(accessToken: accessToken);
  }
}
