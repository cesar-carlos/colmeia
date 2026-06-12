import 'package:colmeia/features/auth/data/models/auth_session_model.dart';
import 'package:colmeia/features/auth/data/models/client_auth_tokens_dto.dart';
import 'package:colmeia/features/auth/data/models/client_auth_user_dto.dart';
import 'package:colmeia/shared/data/json/wrapped_json_reader.dart';

class ClientLoginResponseDto {
  const ClientLoginResponseDto({
    required this.tokens,
    required this.user,
  });

  factory ClientLoginResponseDto.fromJson(Map<String, dynamic> json) {
    final payload = readWrappedPayload(json);
    final userPayload =
        readNestedMap(payload, const <String>['user', 'client']) ?? payload;

    return ClientLoginResponseDto(
      tokens: ClientAuthTokensDto.fromJson(payload),
      user: ClientAuthUserDto.fromJson(userPayload),
    );
  }

  final ClientAuthTokensDto tokens;
  final ClientAuthUserDto user;

  AuthSessionModel toSessionModel() {
    return tokens.toSessionModel(
      userId: user.id,
      email: user.email,
      role: user.role,
      accountStatus: user.accountStatus,
    );
  }
}
