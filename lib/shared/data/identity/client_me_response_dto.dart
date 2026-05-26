import 'package:colmeia/shared/data/identity/client_auth_user_dto.dart';
import 'package:colmeia/shared/data/json/wrapped_json_reader.dart';

class ClientMeResponseDto {
  const ClientMeResponseDto({
    required this.user,
  });

  factory ClientMeResponseDto.fromJson(Map<String, dynamic> json) {
    final payload = readWrappedPayload(
      json,
      wrapperKeys: const <String>['data', 'profile'],
    );
    final userPayload =
        readNestedMap(payload, const <String>['user', 'client']) ?? payload;

    return ClientMeResponseDto(
      user: ClientAuthUserDto.fromJson(userPayload),
    );
  }

  final ClientAuthUserDto user;
}
