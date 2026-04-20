import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';

/// Source-of-truth for "something changed about the presence/profile of
/// agent X". Sealed so consumers do exhaustive `switch`.
///
/// PR-M (Phase 2) introduces two flavors:
///
/// - [AgentPresenceCatalogUpdated] — the hub broadcast a catalog/profile
///   change for an agent the current client has access to. Triggered by
///   the `client:agent.profile.updated` socket event (PayloadFrame).
/// - [AgentPresenceHint] — heuristic inferred from the outcome of a
///   `agents:command` (or relay) RPC: success ⇒ online, offline error ⇒
///   offline. Used to anticipate UI feedback before the next catalog refresh.
///
/// `agentId` is always present because the UI always needs to know
/// **which** card to rebuild. `observedAt` is UTC and is used for
/// deduplication and ordering when two events for the same agent arrive
/// in quick succession.
sealed class AgentPresenceEvent {
  const AgentPresenceEvent({
    required this.agentId,
    required this.observedAt,
  });

  final String agentId;

  /// UTC. Use to dedupe by window and to break ties between sources.
  final DateTime observedAt;
}

/// Hub notified that the catalog/profile of [agentId] changed
/// (`client:agent.profile.updated`). Presence may have changed alongside
/// the profile: the rule of thumb is to refresh via REST and let the
/// server return the current `isHubConnected`.
final class AgentPresenceCatalogUpdated extends AgentPresenceEvent {
  const AgentPresenceCatalogUpdated({
    required super.agentId,
    required super.observedAt,
    this.changedFields = const <String>{},
    this.profileVersion,
    this.source,
  });

  /// Empty when the hub did not send (defensive). When it contains only
  /// pure-profile keys (e.g. `phone`, `address`), the consumer may decide
  /// **not** to repull presence, only profile.
  final Set<String> changedFields;

  /// Monotonic integer exposed by the hub. Use to discard out-of-order
  /// notifications without relying on wall-clock alone.
  final int? profileVersion;

  /// `http`, `socket`, `pull_sync`. Informational only — does not change
  /// the UI reaction.
  final String? source;
}

/// Heuristic inferred from a single command outcome. Does NOT replace the
/// catalog refresh: it accelerates the visual feedback and feeds the
/// in-memory presence cache used by `loadOnlineAgentIds`.
final class AgentPresenceHint extends AgentPresenceEvent {
  const AgentPresenceHint({
    required super.agentId,
    required super.observedAt,
    required this.online,
    required this.source,
  });

  final bool online;

  /// Origin of the hint, for logging/observability:
  /// `agents:command_success` | `agents:command_error_offline`.
  /// Future: `relay:rpc_success`, `polling_rest`.
  final String source;
}

/// Convenience for mapping a hint to the existing
/// [AgentConnectionStatus] without forcing the UI to do the switch.
AgentConnectionStatus connectionStatusFromHint(AgentPresenceHint hint) {
  return hint.online
      ? AgentConnectionStatus.online
      : AgentConnectionStatus.offline;
}
