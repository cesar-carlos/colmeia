import 'package:colmeia/features/auth/data/models/client_auth_json_reader.dart';
import 'package:colmeia/features/auth/data/models/client_auth_user_dto.dart';

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
