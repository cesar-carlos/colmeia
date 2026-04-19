import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';

class AgentQueryPlan {
  const AgentQueryPlan({
    required this.queryKey,
    required this.strategy,
    required this.consideredApprovedAgentCount,
    required this.plannedTargets,
    required this.missingClientTokenTargets,
    required this.bridgeTimeoutMs,
    this.raceMaxSources,
    this.skippedDueToHubPresenceTargets = const <AgentQueryTarget>[],
  });

  final AgentQueryKey queryKey;
  final AgentQueryExecutionStrategy strategy;
  final int consideredApprovedAgentCount;
  final List<AgentQueryTarget> plannedTargets;
  final List<AgentQueryTarget> missingClientTokenTargets;
  final int bridgeTimeoutMs;
  final int? raceMaxSources;

  /// Approved agents that DO have a stored client_token but were
  /// excluded because the hub-presence policy marked them as
  /// offline at planning time. Surfaced separately from
  /// [missingClientTokenTargets] so the executor can carry the
  /// distinction into `AgentQueryExecutionReport` and the
  /// presentation layer can render an actionable banner.
  final List<AgentQueryTarget> skippedDueToHubPresenceTargets;

  bool get skippedOnlyDueToMissingClientTokens =>
      plannedTargets.isEmpty && missingClientTokenTargets.isNotEmpty;

  /// Planned targets are empty, no missing-token rows, but at least one agent
  /// was considered (e.g. filtered out solely by hub presence rules).
  bool get skippedOnlyDueToHubPresenceRules =>
      plannedTargets.isEmpty &&
      missingClientTokenTargets.isEmpty &&
      consideredApprovedAgentCount > 0;
}
