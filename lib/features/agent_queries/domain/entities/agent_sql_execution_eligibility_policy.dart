import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';

/// Pure rules for when agent SQL may run given a resolved connection status.
class AgentSqlExecutionEligibilityPolicy {
  const AgentSqlExecutionEligibilityPolicy();

  /// No cached hub presence for this user — do not block SQL (cold start).
  bool allowWhenPresenceSnapshotUnavailable() => true;

  /// With a presence snapshot, only agents resolved as online may run SQL.
  bool sqlAllowedForStatus(AgentConnectionStatus status) =>
      status == AgentConnectionStatus.online;
}
