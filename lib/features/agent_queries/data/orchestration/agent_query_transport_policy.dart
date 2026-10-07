import 'package:colmeia/core/config/agent_query_transport_policy_mode.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';

/// Centralises when Colmeia prefers relay vs legacy `agents:command` / REST.
///
/// Repositories may still set [AgentSqlExecuteRequest.useRelay] explicitly;
/// this policy only adjusts requests that left the flag at the default `false`
/// when [AgentQueryTransportPolicyMode] is not [AgentQueryTransportPolicyMode.legacy].
class AgentQueryTransportPolicy {
  const AgentQueryTransportPolicy({required this.mode});

  final AgentQueryTransportPolicyMode mode;

  AgentSqlExecuteRequest apply(AgentSqlExecuteRequest request) {
    if (request.useRelay) {
      return request;
    }
    switch (mode) {
      case AgentQueryTransportPolicyMode.legacy:
        return request;
      case AgentQueryTransportPolicyMode.preferRelay:
        return request.copyWith(useRelay: true);
      case AgentQueryTransportPolicyMode.autoByShape:
        if (request.relayMode == AgentSqlRelayMode.streaming) {
          return request.copyWith(useRelay: true);
        }
        if (request.pagination != null) {
          return request;
        }
        return request;
    }
  }

  AgentSqlExecuteBatchRequest applyBatch(
    AgentSqlExecuteBatchRequest request, {
    bool dashboardBatch = false,
  }) {
    if (request.useRelay) {
      return request;
    }
    final shouldUseRelay = switch (mode) {
      AgentQueryTransportPolicyMode.legacy => dashboardBatch,
      AgentQueryTransportPolicyMode.preferRelay => true,
      AgentQueryTransportPolicyMode.autoByShape => dashboardBatch,
    };
    if (!shouldUseRelay) {
      return request;
    }
    return request.copyWith(useRelay: true);
  }
}
