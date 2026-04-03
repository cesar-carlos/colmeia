import 'package:colmeia/features/auth/data/models/client_auth_json_reader.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_submission.dart';

class ClientRegisterResponseDto {
  const ClientRegisterResponseDto({
    required this.status,
    this.message,
    this.approvalToken,
  });

  factory ClientRegisterResponseDto.fromJson(Map<String, dynamic> json) {
    final payload = readWrappedPayload(
      json,
      wrapperKeys: const <String>['data', 'registration'],
    );
    final userPayload =
        readNestedMap(payload, const <String>['user', 'client']) ?? payload;
    final rawStatus =
        readOptionalString(userPayload, const <String>['status']) ??
        readOptionalString(payload, const <String>['status']) ??
        ClientRegistrationStatus.pending.wireValue;

    return ClientRegisterResponseDto(
      status: ClientRegistrationStatusParsing.fromRaw(rawStatus),
      message: readOptionalString(payload, const <String>['message']),
      approvalToken: readOptionalString(
        payload,
        const <String>['approvalToken', 'approval_token', 'token'],
      ),
    );
  }

  final ClientRegistrationStatus status;
  final String? message;
  final String? approvalToken;

  ClientRegistrationSubmission toEntity() {
    return ClientRegistrationSubmission(
      status: status,
      message: message,
      approvalToken: approvalToken,
    );
  }
}
