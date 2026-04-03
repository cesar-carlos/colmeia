import 'package:colmeia/features/auth/data/models/client_auth_json_reader.dart';
import 'package:colmeia/features/auth/domain/entities/client_password_recovery_status.dart';

class ClientPasswordRecoveryStatusResponseDto {
  const ClientPasswordRecoveryStatusResponseDto({
    required this.status,
  });

  factory ClientPasswordRecoveryStatusResponseDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final payload = readWrappedPayload(
      json,
      wrapperKeys: const <String>['data'],
    );

    return ClientPasswordRecoveryStatusResponseDto(
      status: ClientPasswordRecoveryStatusParsing.fromRaw(
        readOptionalString(payload, const <String>['status']),
      ),
    );
  }

  final ClientPasswordRecoveryStatus status;
}
