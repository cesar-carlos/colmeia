import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/domain/entities/client_account_status.dart';

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.email,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.role,
    this.accountStatus = ClientAccountStatus.unknown,
  });

  final String userId;
  final EmailAddress email;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String? role;
  final ClientAccountStatus accountStatus;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
