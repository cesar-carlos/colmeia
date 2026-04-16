import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_eligibility_evaluation.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_eligibility_policy.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_sql_execution_eligibility_port.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:colmeia/features/client_agents/domain/services/agent_connection_status_resolver.dart';

class AgentSqlExecutionEligibilityChecker
    implements AgentSqlExecutionEligibilityPort {
  AgentSqlExecutionEligibilityChecker({
    required ClientAgentsRepository clientAgentsRepository,
    AgentSqlExecutionEligibilityPolicy policy =
        const AgentSqlExecutionEligibilityPolicy(),
    Duration onlineAgentIdsCacheTtl = const Duration(seconds: 2),
  }) : _clientAgentsRepository = clientAgentsRepository,
       _policy = policy,
       _onlineAgentIdsCacheTtl = onlineAgentIdsCacheTtl;

  final ClientAgentsRepository _clientAgentsRepository;
  final AgentSqlExecutionEligibilityPolicy _policy;
  final Duration _onlineAgentIdsCacheTtl;

  final Map<String, ({Set<String>? ids, DateTime at})> _onlineAgentIdsCache =
      <String, ({Set<String>? ids, DateTime at})>{};

  @override
  Future<AgentSqlExecutionEligibilityEvaluation> evaluate({
    required String userId,
    required String agentId,
    bool? isHubConnected,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
  }) async {
    final onlineIds = hubPresenceOnlineAgentIdsSnapshot ??
        await _loadOnlineAgentIdsCached(userId);
    if (onlineIds == null) {
      if (_policy.allowWhenPresenceSnapshotUnavailable()) {
        return const AgentSqlExecutionEligibilityEvaluation.allowed();
      }
      return const AgentSqlExecutionEligibilityEvaluation.denied(
        'Agent presence snapshot unavailable.',
      );
    }

    final status = resolveAgentConnectionStatus(
      agentId: agentId,
      isHubConnected: isHubConnected,
      onlineAgentIds: onlineIds,
    );
    if (_policy.sqlAllowedForStatus(status)) {
      return const AgentSqlExecutionEligibilityEvaluation.allowed();
    }
    return AgentSqlExecutionEligibilityEvaluation.denied(
      'Agent is not online for SQL execution (status=${status.name}).',
    );
  }

  Future<Set<String>?> _loadOnlineAgentIdsCached(String userId) async {
    final now = DateTime.now();
    final hit = _onlineAgentIdsCache[userId];
    if (hit != null && now.difference(hit.at) <= _onlineAgentIdsCacheTtl) {
      return hit.ids;
    }
    final ids = await _clientAgentsRepository.loadOnlineAgentIds(
      userId: userId,
    );
    _onlineAgentIdsCache[userId] = (ids: ids, at: now);
    return ids;
  }
}
