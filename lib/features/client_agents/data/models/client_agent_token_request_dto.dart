import 'package:colmeia/features/client_agents/domain/entities/client_agent_token_constraints.dart';

/// Wire body for `PUT /client/me/agents/{agentId}/client-token`.
///
/// Send `clientToken: null` (or an empty/whitespace string, normalized to
/// `null`) to clear the stored token. The hub caps the token at 512 chars.
class ClientAgentTokenRequestDto {
  const ClientAgentTokenRequestDto({required this.clientToken});

  /// Maximum length accepted by the server (DB column
  /// `client_agent_accesses.client_token`).
  static const int maxTokenLength = ClientAgentTokenConstraints.maxLength;

  /// Raw input. Use [normalized] when serializing or validating; this preserves
  /// the original value for diagnostics.
  final String? clientToken;

  /// Whitespace-only or empty strings are normalized to `null` so callers do
  /// not need to special-case "clear the token" vs. "save an empty token".
  String? get normalized {
    final raw = clientToken;
    if (raw == null) {
      return null;
    }
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Returns a validation message when the payload would be rejected by the
  /// server, or `null` when it is safe to send.
  String? validationError() {
    final value = normalized;
    if (value == null) {
      return null;
    }
    if (value.length > maxTokenLength) {
      return 'clientToken must not exceed $maxTokenLength characters';
    }
    return null;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{'clientToken': normalized};
  }
}
