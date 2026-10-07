import 'package:colmeia/features/agent_queries/data/agent_sql_execute_batch_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execute_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local unary deadline is copied and never becomes a protocol field', () {
    const request = AgentSqlExecuteRequest(
      agentId: 'a',
      sql: 'SELECT 1',
      bridgeTimeoutMs: 500,
      totalTimeoutMs: 1500,
    );
    expect(request.copyWith(useRelay: true).totalTimeoutMs, 1500);
    expect(request.copyWith(totalTimeoutMs: 2000).totalTimeoutMs, 2000);
    final body = const AgentSqlExecuteRequestToBridgeBody().build(
      request: request,
      rpcId: 'r',
    );
    expect(body['timeoutMs'], 500);
    expect(body.containsKey('totalTimeoutMs'), false);
    expect(body.containsKey('total_timeout_ms'), false);
    expect((body['command']! as Map).containsKey('totalTimeoutMs'), false);
  });

  test('local batch deadline is copied and never becomes a protocol field', () {
    const request = AgentSqlExecuteBatchRequest(
      agentId: 'a',
      commands: [AgentSqlExecuteBatchCommand(sql: 'SELECT 1')],
      bridgeTimeoutMs: 500,
      totalTimeoutMs: 1500,
    );
    expect(request.copyWith(useRelay: true).totalTimeoutMs, 1500);
    expect(request.copyWith(totalTimeoutMs: 2000).totalTimeoutMs, 2000);
    final body = const AgentSqlExecuteBatchRequestToBridgeBody().build(
      request: request,
      rpcId: 'r',
    );
    expect(body['timeoutMs'], 500);
    expect(body.containsKey('totalTimeoutMs'), false);
    expect(body.containsKey('total_timeout_ms'), false);
    expect((body['command']! as Map).containsKey('totalTimeoutMs'), false);
  });

  for (final invalid in [0, -1]) {
    test('rejects non-positive local deadlines: $invalid', () {
      expect(
        AgentSqlExecuteRequest(
          agentId: 'a',
          sql: 'SELECT 1',
          totalTimeoutMs: invalid,
        ).validationError(),
        isNotNull,
      );
      expect(
        AgentSqlExecuteBatchRequest(
          agentId: 'a',
          commands: const [AgentSqlExecuteBatchCommand(sql: 'SELECT 1')],
          totalTimeoutMs: invalid,
        ).validationError(),
        isNotNull,
      );
    });
  }
}
