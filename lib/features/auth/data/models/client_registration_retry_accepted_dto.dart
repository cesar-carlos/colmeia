import 'package:colmeia/shared/data/json/wrapped_json_reader.dart';

class ClientRegistrationRetryAcceptedDto {
  const ClientRegistrationRetryAcceptedDto({
    required this.message,
  });

  factory ClientRegistrationRetryAcceptedDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final payload = readWrappedPayload(
      json,
      wrapperKeys: const <String>['data'],
    );

    return ClientRegistrationRetryAcceptedDto(
      message: readRequiredString(
        payload,
        const <String>['message'],
        logicalName: 'message',
      ),
    );
  }

  final String message;
}
