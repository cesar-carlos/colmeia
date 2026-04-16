import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_eligibility_evaluation.dart';

/// Decides whether `sql.execute` is allowed for an agent under hub presence rules.
// ignore: one_member_abstracts — small DI-facing port; kept as interface for tests/mocks.
abstract interface class AgentSqlExecutionEligibilityPort {
  Future<AgentSqlExecutionEligibilityEvaluation> evaluate({
    required String userId,
    required String agentId,

    /// Explicit hub flag from the fast approved-agent catalog row when known;
    /// reserved for alignment with `resolveAgentConnectionStatus` (often null).
    bool? isHubConnected,

    /// When non-null, skips loading online ids and uses this snapshot instead.
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
  });
}
