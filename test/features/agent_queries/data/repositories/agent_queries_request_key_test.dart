import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_request_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentQueriesRequestKey.build', () {
    test('changes when relayMode changes', () {
      const unary = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        useRelay: true,
      );
      const streaming = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        useRelay: true,
        relayMode: AgentSqlRelayMode.streaming,
      );

      final a = AgentQueriesRequestKey.build(unary);
      final b = AgentQueriesRequestKey.build(streaming);

      check(a).not((it) => it.equals(b));
    });

    test('changes when preferDbStreaming changes', () {
      const baseline = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        executeOptions: AgentSqlExecuteOptions(),
      );
      const preferStreaming = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        executeOptions: AgentSqlExecuteOptions(preferDbStreaming: true),
      );

      final a = AgentQueriesRequestKey.build(baseline);
      final b = AgentQueriesRequestKey.build(preferStreaming);

      check(a).not((it) => it.equals(b));
    });
  });

  group('AgentQueriesRequestKey.buildBatch', () {
    test('changes when maxParallelReadOnlyBatchItems changes', () {
      const baseline = AgentSqlExecuteBatchRequest(
        agentId: 'agent-1',
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
        ],
        options: AgentSqlExecuteBatchOptions(transaction: false),
      );
      const parallel = AgentSqlExecuteBatchRequest(
        agentId: 'agent-1',
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
        ],
        options: AgentSqlExecuteBatchOptions(
          transaction: false,
          maxParallelReadOnlyBatchItems: 4,
        ),
      );

      final a = AgentQueriesRequestKey.buildBatch(baseline);
      final b = AgentQueriesRequestKey.buildBatch(parallel);

      check(a).not((it) => it.equals(b));
    });
  });
}
