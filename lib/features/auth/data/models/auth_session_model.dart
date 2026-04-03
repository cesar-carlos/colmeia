import 'dart:convert';

import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/domain/entities/client_account_status.dart';

class AuthSessionModel {
  const AuthSessionModel({
    required this.userId,
    required this.email,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.role,
    this.accountStatus = ClientAccountStatus.unknown,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      userId: json['userId'] as String,
      email: json['email'] as String,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      role: json['role'] as String?,
      accountStatus: ClientAccountStatusParsing.fromRaw(
        json['accountStatus'] as String?,
      ),
    );
  }

  factory AuthSessionModel.decode(String raw) {
    return AuthSessionModel.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  final String userId;
  final String email;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String? role;
  final ClientAccountStatus accountStatus;

  AuthSession toEntity() {
    return AuthSession(
      userId: userId,
      email: EmailAddress(email),
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      role: role,
      accountStatus: accountStatus,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'userId': userId,
      'email': email,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
      'role': role,
      'accountStatus': accountStatus.wireValue,
    };
  }

  String encode() => jsonEncode(toJson());
}
