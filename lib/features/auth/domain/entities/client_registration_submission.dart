import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';

class ClientRegistrationSubmission {
  const ClientRegistrationSubmission({
    required this.status,
    this.message,
    this.pollToken,
    this.duplicate = false,
  });

  final ClientRegistrationStatus status;
  final String? message;

  /// Token for polling registration status via
  /// `GET /client-auth/registration/status?token=...`.
  ///
  /// Production responses expose `registrationPollToken`; dev/test may also
  /// include `approvalToken`, which is mapped here when no poll token exists.
  final String? pollToken;

  /// True when the server accepted a duplicate submission (HTTP 202) without
  /// returning a new poll token.
  final bool duplicate;

  bool get canPollStatus => pollToken?.trim().isNotEmpty ?? false;
}
