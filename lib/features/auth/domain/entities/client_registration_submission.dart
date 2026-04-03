import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';

class ClientRegistrationSubmission {
  const ClientRegistrationSubmission({
    required this.status,
    this.message,
    this.approvalToken,
  });

  final ClientRegistrationStatus status;
  final String? message;
  final String? approvalToken;

  bool get canPollStatus => approvalToken?.trim().isNotEmpty ?? false;
}
