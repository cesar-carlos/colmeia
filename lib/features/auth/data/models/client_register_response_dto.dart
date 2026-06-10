import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_submission.dart';
import 'package:colmeia/shared/data/json/wrapped_json_reader.dart';

class ClientRegisterResponseDto {
  const ClientRegisterResponseDto({
    required this.status,
    this.message,
    this.pollToken,
    this.duplicate = false,
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
      pollToken: _resolvePollToken(payload),
      duplicate: _resolveDuplicate(payload),
    );
  }

  final ClientRegistrationStatus status;
  final String? message;
  final String? pollToken;
  final bool duplicate;

  static String? _resolvePollToken(Map<String, dynamic> payload) {
    return readOptionalString(
          payload,
          const <String>[
            'registrationPollToken',
            'registration_poll_token',
          ],
        ) ??
        readOptionalString(
          payload,
          const <String>['approvalToken', 'approval_token', 'token'],
        );
  }

  static bool _resolveDuplicate(Map<String, dynamic> payload) {
    final raw = payload['duplicate'] ?? payload['isDuplicate'];
    if (raw is bool) {
      return raw;
    }
    if (raw is String) {
      return raw.toLowerCase() == 'true';
    }
    return false;
  }

  ClientRegistrationSubmission toEntity() {
    return ClientRegistrationSubmission(
      status: status,
      message: message,
      pollToken: pollToken,
      duplicate: duplicate,
    );
  }
}
