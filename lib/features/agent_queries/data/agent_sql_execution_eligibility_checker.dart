import 'dart:async';

import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_eligibility_evaluation.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_eligibility_policy.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_sql_execution_eligibility_port.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:colmeia/features/client_agents/domain/services/agent_connection_status_resolver.dart';

class AgentSqlExecutionEligibilityChecker
    implements AgentSqlExecutionEligibilityPort {
  AgentSqlExecutionEligibilityChecker({
    required this._clientAgentsRepository,
    this._policy = const AgentSqlExecutionEligibilityPolicy(),
    this._onlineAgentIdsCacheTtl = const Duration(seconds: 2),
  });

  final ClientAgentsRepository _clientAgentsRepository;
  final AgentSqlExecutionEligibilityPolicy _policy;
  final Duration _onlineAgentIdsCacheTtl;

  final Map<String, ({Set<String>? ids, DateTime at})> _onlineAgentIdsCache =
      <String, ({Set<String>? ids, DateTime at})>{};
  final Map<(String, String), Future<AgentSqlExecutionEligibilityEvaluation>>
  _pendingPresenceChecks = {};

  @override
  Future<AgentSqlExecutionEligibilityEvaluation> evaluate({
    required String userId,
    required String agentId,
    bool? isHubConnected,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
  }) async {
    final onlineIds =
        hubPresenceOnlineAgentIdsSnapshot ??
        await _loadOnlineAgentIdsCached(userId);
    if (onlineIds == null && isHubConnected == null) {
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
    // Presence caches can contain only a page of agents or an old offline flag.
    // Confirm a negative decision using the client-scoped, network-only probe.
    final key = (userId, agentId);
    final pending = _pendingPresenceChecks[key];
    if (pending != null) return pending;
    final check = _confirmPresence(userId: userId, agentId: agentId);
    unawaited(_pendingPresenceChecks[key] = check);
    try {
      return await check;
    } finally {
      if (identical(_pendingPresenceChecks[key], check)) {
        unawaited(_pendingPresenceChecks.remove(key));
      }
    }
  }

  Future<AgentSqlExecutionEligibilityEvaluation> _confirmPresence({
    required String userId,
    required String agentId,
  }) async {
    final result = await _clientAgentsRepository.probeApprovedAgentLink(
      userId: userId,
      agentId: agentId,
    );
    return result.fold((probe) {
      final agent = probe.agent;
      if (agent == null || agent.agentId != agentId) {
        return const AgentSqlExecutionEligibilityEvaluation.denied(
          'Agent is not linked to the requesting account.',
        );
      }
      final status = agent.connectionStatus;
      if (_policy.sqlAllowedForStatus(status) ||
          (status == AgentConnectionStatus.unknown &&
              _policy.allowWhenPresenceSnapshotUnavailable())) {
        _onlineAgentIdsCache.remove(userId);
        return const AgentSqlExecutionEligibilityEvaluation.allowed();
      }
      return AgentSqlExecutionEligibilityEvaluation.denied(
        'Agent is not online for SQL execution (status=${status.name}).',
      );
    }, AgentSqlExecutionEligibilityEvaluation.failed);
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
