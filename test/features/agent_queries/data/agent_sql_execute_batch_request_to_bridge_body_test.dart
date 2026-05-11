import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execute_batch_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const builder = AgentSqlExecuteBatchRequestToBridgeBody();

  group('AgentSqlExecuteBatchRequestToBridgeBody.build', () {
    test('builds canonical sql.executeBatch payload', () {
      const request = AgentSqlExecuteBatchRequest(
        agentId: '  agent-1  ',
        clientToken: ' token-1 ',
        bridgeTimeoutMs: 30000,
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(
            sql: 'SELECT 1',
            namedParams: <String, Object?>{'a': 1},
            executionOrder: 0,
          ),
          AgentSqlExecuteBatchCommand(
            sql: 'SELECT 2',
            namedParams: <String, Object?>{'b': 'x'},
            executionOrder: 1,
          ),
        ],
        options: AgentSqlExecuteBatchOptions(
          sqlTimeoutMs: 25000,
          maxRows: 100,
          transaction: false,
        ),
      );

      final body = builder.build(request: request, rpcId: 'rpc-batch-1');

      check(body['agentId']).equals('agent-1');
      check(body['timeoutMs']).equals(30000);

      final command = body['command']! as Map<String, Object?>;
      check(command['jsonrpc']).equals('2.0');
      check(command['method']).equals('sql.executeBatch');
      check(command['id']).equals('rpc-batch-1');
      check(command['api_version']).equals(kColmeiaAgentBatchApiVersion);

      final params = command['params']! as Map<String, Object?>;
      check(params['client_token']).equals('token-1');

      final commands = params['commands']! as List<Object?>;
      check(commands.length).equals(2);
      final first = commands.first! as Map<String, Object?>;
      check(first['sql']).equals('SELECT 1');
      final firstParams = first['params']! as Map<String, Object?>;
      check(firstParams['a']).equals(1);
      check(first['execution_order']).equals(0);

      final options = params['options']! as Map<String, Object?>;
      check(options['timeout_ms']).equals(25000);
      check(options['max_rows']).equals(100);
      check(options['transaction']).equals(false);
    });

    test('normalizes multiline SQL per command', () {
      const request = AgentSqlExecuteBatchRequest(
        agentId: 'agent-1',
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(
            sql: '''
              SELECT
                *
              FROM Cliente
            ''',
          ),
        ],
      );

      final body = builder.build(request: request, rpcId: 'rpc-batch-2');
      final command = body['command']! as Map<String, Object?>;
      final params = command['params']! as Map<String, Object?>;
      final commands = params['commands']! as List<Object?>;
      final first = commands.first! as Map<String, Object?>;
      check(first['sql']).equals('SELECT * FROM Cliente');
    });
  });
}
