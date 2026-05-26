import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';
import 'package:colmeia/shared/data/json/wrapped_json_reader.dart';

class ClientRegistrationStatusResponseDto {
  const ClientRegistrationStatusResponseDto({
    required this.status,
  });

  factory ClientRegistrationStatusResponseDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final payload = readWrappedPayload(
      json,
      wrapperKeys: const <String>['data', 'registration'],
    );
    return ClientRegistrationStatusResponseDto(
      status: ClientRegistrationStatusParsing.fromRaw(
        readOptionalString(payload, const <String>['status']),
      ),
    );
  }

  final ClientRegistrationStatus status;
}
