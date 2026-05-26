import 'package:colmeia/features/auth/data/models/client_auth_tokens_dto.dart';
import 'package:colmeia/shared/data/json/wrapped_json_reader.dart';

class ClientRefreshResponseDto {
  const ClientRefreshResponseDto({
    required this.tokens,
  });

  factory ClientRefreshResponseDto.fromJson(Map<String, dynamic> json) {
    return ClientRefreshResponseDto(
      tokens: ClientAuthTokensDto.fromJson(readWrappedPayload(json)),
    );
  }

  final ClientAuthTokensDto tokens;
}
