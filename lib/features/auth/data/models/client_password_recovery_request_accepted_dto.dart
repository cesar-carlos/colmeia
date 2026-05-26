import 'package:colmeia/shared/data/json/wrapped_json_reader.dart';

class ClientPasswordRecoveryRequestAcceptedDto {
  const ClientPasswordRecoveryRequestAcceptedDto({
    required this.message,
  });

  factory ClientPasswordRecoveryRequestAcceptedDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final payload = readWrappedPayload(
      json,
      wrapperKeys: const <String>['data'],
    );

    return ClientPasswordRecoveryRequestAcceptedDto(
      message: readRequiredString(
        payload,
        const <String>['message'],
        logicalName: 'message',
      ),
    );
  }

  final String message;
}
