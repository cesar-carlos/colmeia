import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';

class AgentQueryTargetResolution {
  const AgentQueryTargetResolution({
    required this.consideredApprovedTargets,
    required this.missingClientTokenTargets,
    required this.consideredApprovedAgentCount,
    this.selectedAgentIds,
    this.hubPresenceOnlineAgentIdsSnapshot,
    this.skippedDueToHubPresenceTargets = const <AgentQueryTarget>[],
    this.sqlEligibleConsideredTargetCount,
  });

  final List<AgentQueryTarget> consideredApprovedTargets;
  final List<AgentQueryTarget> missingClientTokenTargets;
  final int consideredApprovedAgentCount;
  final Set<String>? selectedAgentIds;

  /// Non-null when hub/cache presence was available for this resolution.
  /// `null` means cold start / no snapshot — downstream SQL gating stays off.
  final Set<String>? hubPresenceOnlineAgentIdsSnapshot;

  /// Approved agents with a local client token that were excluded from the
  /// runnable plan because presence rules treat them as not consultable.
  final List<AgentQueryTarget> skippedDueToHubPresenceTargets;

  /// Considered targets with a client token that pass SQL presence rules
  /// (aligned with the agent query plan builder token + online filter). Null
  /// on early-exit resolutions where this was not computed.
  final int? sqlEligibleConsideredTargetCount;

  bool get hasTargets => consideredApprovedTargets.isNotEmpty;
}
