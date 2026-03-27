import 'dart:convert';

import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';

class AuthSessionModel {
  const AuthSessionModel({
    required this.userId,
    required this.email,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      userId: json['userId'] as String,
      email: json['email'] as String,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
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

  AuthSession toEntity() {
    return AuthSession(
      userId: userId,
      email: EmailAddress(email),
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'userId': userId,
      'email': email,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  String encode() => jsonEncode(toJson());
}
