import 'package:colmeia/core/config/agent_query_transport_policy_mode.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_transport_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sql = 'SELECT 1';
  const agentId = 'agent-1';

  group('AgentQueryTransportPolicy', () {
    test('legacy leaves useRelay false', () {
      const policy = AgentQueryTransportPolicy(
        mode: AgentQueryTransportPolicyMode.legacy,
      );
      const request = AgentSqlExecuteRequest(agentId: agentId, sql: sql);

      expect(policy.apply(request).useRelay, isFalse);
    });

    test('preferRelay sets useRelay true', () {
      const policy = AgentQueryTransportPolicy(
        mode: AgentQueryTransportPolicyMode.preferRelay,
      );
      const request = AgentSqlExecuteRequest(agentId: agentId, sql: sql);

      expect(policy.apply(request).useRelay, isTrue);
    });

    test('autoByShape enables relay only for streaming mode', () {
      const policy = AgentQueryTransportPolicy(
        mode: AgentQueryTransportPolicyMode.autoByShape,
      );
      const unary = AgentSqlExecuteRequest(agentId: agentId, sql: sql);
      const streaming = AgentSqlExecuteRequest(
        agentId: agentId,
        sql: sql,
        relayMode: AgentSqlRelayMode.streaming,
      );

      expect(policy.apply(unary).useRelay, isFalse);
      expect(policy.apply(streaming).useRelay, isTrue);
    });

    test('applyBatch legacy leaves non-dashboard batch on base transport', () {
      const policy = AgentQueryTransportPolicy(
        mode: AgentQueryTransportPolicyMode.legacy,
      );
      const batch = AgentSqlExecuteBatchRequest(
        agentId: agentId,
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(sql: sql),
        ],
      );

      expect(policy.applyBatch(batch).useRelay, isFalse);
      expect(
        policy.applyBatch(batch, dashboardBatch: true).useRelay,
        isTrue,
      );
    });

    test('applyBatch preferRelay sets useRelay on batch', () {
      const policy = AgentQueryTransportPolicy(
        mode: AgentQueryTransportPolicyMode.preferRelay,
      );
      const batch = AgentSqlExecuteBatchRequest(
        agentId: agentId,
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(sql: sql),
        ],
      );

      expect(policy.applyBatch(batch).useRelay, isTrue);
    });
  });

  group('parseAgentQueryTransportPolicyMode', () {
    test('parses aliases', () {
      expect(
        parseAgentQueryTransportPolicyMode('auto'),
        AgentQueryTransportPolicyMode.autoByShape,
      );
      expect(
        parseAgentQueryTransportPolicyMode('prefer_relay'),
        AgentQueryTransportPolicyMode.preferRelay,
      );
      expect(
        parseAgentQueryTransportPolicyMode('unknown'),
        AgentQueryTransportPolicyMode.legacy,
      );
    });
  });
}
