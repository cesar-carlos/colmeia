import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/shared/identity/client_account_status.dart';

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

  /// Convenience overload that uses [DateTime.now]. Prefer the
  /// explicit-clock variants below from controllers / interceptors so
  /// the comparison stays testable without `withClock`.
  bool get isExpired => isExpiredAt(DateTime.now());

  /// `true` when [now] is at or past [expiresAt]. The boundary is
  /// inclusive because the server considers the same instant invalid
  /// (`exp` is exclusive in the JWT spec, but the bridge treats
  /// equality as expired in practice).
  bool isExpiredAt(DateTime now) {
    return !now.isBefore(expiresAt);
  }

  /// `true` when [expiresAt] is within [window] of [now] (inclusive).
  /// Used by the auth interceptor to refresh proactively before a
  /// request is sent, avoiding the round-trip cost of the 401 →
  /// refresh → retry pattern when the access token is about to
  /// expire mid-request.
  ///
  /// Defensive: `window <= 0` collapses to [isExpiredAt] semantics —
  /// only frames that are already past `expiresAt` qualify.
  bool isExpiringWithin(Duration window, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    if (window <= Duration.zero) {
      return isExpiredAt(reference);
    }
    final cutoff = expiresAt.subtract(window);
    return !reference.isBefore(cutoff);
  }
}
