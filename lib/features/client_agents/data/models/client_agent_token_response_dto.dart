/// Wire response for `GET /client/me/agents/{agentId}/client-token`.
///
/// The hub returns `clientToken: null` when no token is currently stored.
class ClientAgentTokenResponseDto {
  const ClientAgentTokenResponseDto({
    required this.agentId,
    required this.clientToken,
  });

  factory ClientAgentTokenResponseDto.fromJson(Map<String, dynamic> json) {
    final rawAgentId = json['agentId'];
    final rawToken = json['clientToken'];
    return ClientAgentTokenResponseDto(
      agentId: rawAgentId is String ? rawAgentId : '',
      clientToken: rawToken is String ? rawToken : null,
    );
  }

  final String agentId;

  /// `null` (or empty after normalization) means no token is stored on the
  /// server. The hub also normalizes empty strings to `null` server-side.
  final String? clientToken;

  /// True when the server currently has a non-empty token stored for this
  /// (client, agent) pair.
  bool get hasClientToken {
    final token = clientToken;
    if (token == null) {
      return false;
    }
    return token.trim().isNotEmpty;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'agentId': agentId,
      'clientToken': clientToken,
    };
  }
}
