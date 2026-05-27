import 'package:colmeia/features/client_agents/data/models/client_agent_profile_dto.dart';
import 'package:colmeia/features/client_agents/data/models/online_agent_dto.dart';
import 'package:colmeia/features/client_agents/data/models/online_agents_response_dto.dart';

/// Builds a synthetic [OnlineAgentsResponseDto] from a list of profile
/// rows that already carry the `is_hub_connected` flag (e.g. responses
/// from `GET /client/me/agents` and `GET /client/me/agents/{id}`).
///
/// Returns `null` when none of the profiles report a presence flag, so
/// callers can short-circuit the local cache write. Always uses a single
/// timestamp ([stamp]) for both `connectedAt` and `lastSeenAt` so the
/// resulting DTO mirrors what the dedicated `/api/v1/agents` endpoint
/// would have produced.
///
/// Extracted out of `ClientAgentsRepositoryImpl` so the
/// filter-then-persist concern is decoupled from the side-effecting
/// local cache write and can be unit-tested as a pure function.
OnlineAgentsResponseDto? synthesizeOnlineAgentsDtoFromProfiles({
  required Iterable<ClientAgentProfileDto> profiles,
  required DateTime stamp,
}) {
  final hasAnyFlag = profiles.any((p) => p.isHubConnected != null);
  if (!hasAnyFlag) {
    return null;
  }
  final online = <OnlineAgentDto>[
    for (final p in profiles)
      if (p.isHubConnected == true)
        OnlineAgentDto(
          agentId: p.agentId,
          connectedAt: stamp,
          lastSeenAt: stamp,
        ),
  ];
  return OnlineAgentsResponseDto(agents: online, count: online.length);
}
