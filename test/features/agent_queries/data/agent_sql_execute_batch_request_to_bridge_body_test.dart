import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
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
          maxParallelReadOnlyBatchItems: 4,
        ),
      );

      final body = builder.build(request: request, rpcId: 'rpc-batch-1');

      check(body['agentId']).equals('agent-1');
      check(body['timeoutMs']).equals(30000);

      final command = body['command']! as Map<String, Object?>;
      check(command['jsonrpc']).equals('2.0');
      check(command['method']).equals('sql.executeBatch');
      check(command['id']).equals('rpc-batch-1');
      final meta = command['meta']! as Map<String, Object?>;
      check(meta.containsKey('trace_id')).isTrue();
      check((meta['trace_id']! as String).length).equals(36);
      check(kColmeiaAgentBatchApiVersion).equals('2.10');
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
      check(options['max_parallel_read_only_batch_items']).equals(4);
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

    test('emits payloadFrameCompression at body level when provided', () {
      const request = AgentSqlExecuteBatchRequest(
        agentId: 'agent-1',
        payloadFrameCompression: RelayPayloadFrameCompression.always,
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
        ],
      );

      final body = builder.build(request: request, rpcId: 'rpc-batch-pfc');

      check(body['payloadFrameCompression']).equals('always');
    });
  });

  group('AgentSqlExecuteBatchRequestToBridgeBody.buildRelayCommand', () {
    test('builds the JSON-RPC command without REST envelope fields', () {
      const request = AgentSqlExecuteBatchRequest(
        agentId: 'agent-1',
        clientToken: ' token-1 ',
        payloadFrameCompression: RelayPayloadFrameCompression.always,
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(
            sql: '''
              SELECT
                *
              FROM Cliente
            ''',
            namedParams: <String, Object?>{'ativo': true},
          ),
        ],
      );

      final command = builder.buildRelayCommand(
        request: request,
        rpcId: 'rpc-relay-batch-1',
      );

      check(command.containsKey('agentId')).isFalse();
      check(command.containsKey('command')).isFalse();
      check(command.containsKey('payloadFrameCompression')).isFalse();
      check(command['jsonrpc']).equals('2.0');
      check(command['method']).equals('sql.executeBatch');
      check(command['id']).equals('rpc-relay-batch-1');
      final meta = command['meta']! as Map<String, Object?>;
      check(meta.containsKey('trace_id')).isTrue();
      check((meta['trace_id']! as String).length).equals(36);
      final params = command['params']! as Map<String, Object?>;
      check(params['client_token']).equals('token-1');
      final commands = params['commands']! as List<Object?>;
      final first = commands.single! as Map<String, Object?>;
      check(first['sql']).equals('SELECT * FROM Cliente');
      final namedParams = first['params']! as Map<String, Object?>;
      check(namedParams['ativo']).equals(true);
    });

    test('buildRelayCommand uses explicit trace_id when provided', () {
      const request = AgentSqlExecuteBatchRequest(
        agentId: 'agent-1',
        clientToken: 't',
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
        ],
      );
      const tid = '22222222-2222-2222-2222-222222222222';
      final command = builder.buildRelayCommand(
        request: request,
        rpcId: 'rpc-batch-trace',
        traceId: tid,
      );
      final meta = command['meta']! as Map<String, Object?>;
      check(meta['trace_id']).equals(tid);
    });
  });
}
