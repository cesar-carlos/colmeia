import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execute_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_outbound_compression.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_bridge_pagination.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const builder = AgentSqlExecuteRequestToBridgeBody();

  group('AgentSqlExecuteRequestToBridgeBody.build', () {
    test('builds the canonical payload for a minimal request', () {
      const request = AgentSqlExecuteRequest(
        agentId: '  agent-123  ',
        sql: 'SELECT 1',
      );
      final body = builder.build(request: request, rpcId: 'rpc-fixed-1');

      check(body['agentId']).equals('agent-123');
      check(body.containsKey('timeoutMs')).isFalse();
      check(body.containsKey('pagination')).isFalse();

      final command = body['command']! as Map<String, Object?>;
      check(command['jsonrpc']).equals('2.0');
      check(command['method']).equals('sql.execute');
      check(command['id']).equals('rpc-fixed-1');
      final meta = command['meta']! as Map<String, Object?>;
      check(meta.containsKey('trace_id')).isTrue();
      check((meta['trace_id']! as String).length).equals(36);

      final params = command['params']! as Map<String, Object?>;
      check(params['sql']).equals('SELECT 1');
      check(params.containsKey('params')).isFalse();
      check(params.containsKey('client_token')).isFalse();
      check(params.containsKey('options')).isFalse();
    });

    test('normalizes multiline SQL into a single trimmed line', () {
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: '''
          SELECT
            *
          FROM tbl
          WHERE x = 1
        ''',
      );
      final body = builder.build(request: request, rpcId: 'rpc-2');
      final command = body['command']! as Map<String, Object?>;
      final params = command['params']! as Map<String, Object?>;
      check(params['sql']).equals('SELECT * FROM tbl WHERE x = 1');
    });

    test(
      'includes timeoutMs and pagination at the body level when present',
      () {
        const request = AgentSqlExecuteRequest(
          agentId: 'agent-1',
          sql: 'SELECT 1',
          bridgeTimeoutMs: 20000,
          pagination: AgentSqlPagePagination(page: 2, pageSize: 50),
        );
        final body = builder.build(request: request, rpcId: 'rpc-3');
        check(body['timeoutMs']).equals(20000);
        final pagination = body['pagination']! as Map<String, Object?>;
        check(pagination['page']).equals(2);
        check(pagination['pageSize']).equals(50);
        check(pagination['page_size']).equals(50);
      },
    );

    test('drops empty client token but keeps trimmed valid token', () {
      const empty = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        clientToken: '   ',
      );
      final emptyBody = builder.build(request: empty, rpcId: 'rpc-4');
      final emptyParams =
          (emptyBody['command']! as Map<String, Object?>)['params']!
              as Map<String, Object?>;
      check(emptyParams.containsKey('client_token')).isFalse();

      const filled = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        clientToken: '  token-abc  ',
      );
      final filledBody = builder.build(request: filled, rpcId: 'rpc-5');
      final filledParams =
          (filledBody['command']! as Map<String, Object?>)['params']!
              as Map<String, Object?>;
      check(filledParams['client_token']).equals('token-abc');
    });

    test('emits options when executeOptions are provided', () {
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        executeOptions: AgentSqlExecuteOptions(
          executionMode: AgentSqlExecutionMode.preserve,
          maxRows: 1000,
          preferDbStreaming: true,
        ),
      );
      final body = builder.build(request: request, rpcId: 'rpc-6');
      final params =
          (body['command']! as Map<String, Object?>)['params']!
              as Map<String, Object?>;
      final options = params['options']! as Map<String, Object?>;
      check(options['execution_mode']).equals('preserve');
      check(options['max_rows']).equals(1000);
      check(options['prefer_db_streaming']).equals(true);
    });

    test('emits namedParams when provided', () {
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT * FROM tbl WHERE x = :x',
        namedParams: <String, Object?>{'x': 7},
      );
      final body = builder.build(request: request, rpcId: 'rpc-7');
      final params =
          (body['command']! as Map<String, Object?>)['params']!
              as Map<String, Object?>;
      final inner = params['params']! as Map<String, Object?>;
      check(inner['x']).equals(7);
      check(inner.length).equals(1);
    });

    test('useRelay flag never leaks into the bridge body', () {
      // useRelay is a routing concern (PR-L+ part 1) consumed by the
      // hybrid datasource; the wire body must stay byte-for-byte identical
      // to a request without the flag (except volatile `meta.trace_id`).
      const baseline = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
      );
      const withRelay = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        useRelay: true,
        relayMode: AgentSqlRelayMode.streaming,
      );
      final baselineBody = builder.build(request: baseline, rpcId: 'rpc-r');
      final relayBody = builder.build(request: withRelay, rpcId: 'rpc-r');
      String normalizeForCompare(Map<String, Object?> body) {
        final copy = Map<String, Object?>.from(body);
        final cmd = Map<String, Object?>.from(copy['command']! as Map);
        final meta = cmd['meta'];
        if (meta is Map) {
          final m = Map<String, Object?>.from(meta.cast<String, Object?>())
            ..remove('trace_id');
          if (m.isEmpty) {
            cmd.remove('meta');
          } else {
            cmd['meta'] = m;
          }
        }
        copy['command'] = cmd;
        return copy.toString();
      }

      check(normalizeForCompare(relayBody)).equals(
        normalizeForCompare(baselineBody),
      );
      check(relayBody.containsKey('useRelay')).isFalse();
      check(relayBody.containsKey('relayMode')).isFalse();
    });

    test('emits api_version by default (kColmeiaAgentApiVersion)', () {
      check(kColmeiaAgentApiVersion).equals('2.10');
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
      );
      final body = builder.build(request: request, rpcId: 'rpc-api-default');
      final command = body['command']! as Map<String, Object?>;
      check(command['api_version']).equals(kColmeiaAgentApiVersion);
    });

    test('honors a custom api_version value', () {
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        apiVersion: '2.8',
      );
      final body = builder.build(request: request, rpcId: 'rpc-api-custom');
      final command = body['command']! as Map<String, Object?>;
      check(command['api_version']).equals('2.8');
    });

    test('omits api_version when explicitly cleared', () {
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        apiVersion: '',
      );
      final body = builder.build(request: request, rpcId: 'rpc-api-empty');
      final command = body['command']! as Map<String, Object?>;
      check(command.containsKey('api_version')).isFalse();
    });

    test('emits meta.trace_id and meta.outbound_compression when provided', () {
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        outboundCompression: AgentOutboundCompression.gzip,
      );
      final body = builder.build(request: request, rpcId: 'rpc-meta-1');
      final command = body['command']! as Map<String, Object?>;
      final meta = command['meta']! as Map<String, Object?>;
      check(meta.containsKey('trace_id')).isTrue();
      check((meta['trace_id']! as String).length).equals(36);
      check(meta['outbound_compression']).equals('gzip');
    });

    test('emits meta.trace_id when outboundCompression is null', () {
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
      );
      final body = builder.build(request: request, rpcId: 'rpc-meta-2');
      final command = body['command']! as Map<String, Object?>;
      final meta = command['meta']! as Map<String, Object?>;
      check(meta.containsKey('trace_id')).isTrue();
      check((meta['trace_id']! as String).length).equals(36);
      check(meta.containsKey('outbound_compression')).isFalse();
    });

    test('emits payloadFrameCompression at body level when provided', () {
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        payloadFrameCompression: RelayPayloadFrameCompression.always,
      );
      final body = builder.build(request: request, rpcId: 'rpc-pfc-1');
      check(body['payloadFrameCompression']).equals('always');
    });

    test('omits payloadFrameCompression when null', () {
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
      );
      final body = builder.build(request: request, rpcId: 'rpc-pfc-2');
      check(body.containsKey('payloadFrameCompression')).isFalse();
    });
  });

  group('AgentSqlExecuteRequestToBridgeBody.buildRelayCommand', () {
    test('builds the JSON-RPC command without REST envelope fields', () {
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: '''
          SELECT *
            FROM Cliente
           WHERE ativo = :ativo
        ''',
        namedParams: <String, Object?>{'ativo': true},
        clientToken: ' token-1 ',
        payloadFrameCompression: RelayPayloadFrameCompression.always,
      );

      final command = builder.buildRelayCommand(
        request: request,
        rpcId: 'rpc-relay-1',
      );

      check(command.containsKey('agentId')).isFalse();
      check(command.containsKey('command')).isFalse();
      check(command.containsKey('payloadFrameCompression')).isFalse();
      check(command['jsonrpc']).equals('2.0');
      check(command['method']).equals('sql.execute');
      check(command['id']).equals('rpc-relay-1');
      final meta = command['meta']! as Map<String, Object?>;
      check(meta.containsKey('trace_id')).isTrue();
      check((meta['trace_id']! as String).length).equals(36);
      final params = command['params']! as Map<String, Object?>;
      check(params['sql']).equals(
        'SELECT * FROM Cliente WHERE ativo = :ativo',
      );
      check(params['client_token']).equals('token-1');
      final namedParams = params['params']! as Map<String, Object?>;
      check(namedParams['ativo']).equals(true);
    });

    test('buildRelayCommand uses explicit trace_id when provided', () {
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
      );
      const tid = '11111111-1111-1111-1111-111111111111';
      final command = builder.buildRelayCommand(
        request: request,
        rpcId: 'rpc-relay-trace',
        traceId: tid,
      );
      final meta = command['meta']! as Map<String, Object?>;
      check(meta['trace_id']).equals(tid);
    });

    test('merges page pagination into params.options for relay', () {
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT CodCliente FROM Cliente ORDER BY CodCliente',
        pagination: AgentSqlPagePagination(page: 1, pageSize: 10),
      );

      final command = builder.buildRelayCommand(
        request: request,
        rpcId: 'rpc-relay-page',
      );

      check(command.containsKey('pagination')).isFalse();
      final params = command['params']! as Map<String, Object?>;
      final options = params['options']! as Map<String, Object?>;
      check(options['page']).equals(1);
      check(options['page_size']).equals(10);
    });

    test('merges cursor pagination into params.options for relay', () {
      final request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT CodCliente FROM Cliente ORDER BY CodCliente',
        pagination: AgentSqlCursorPagination(cursor: 'cursor-token'),
      );

      final command = builder.buildRelayCommand(
        request: request,
        rpcId: 'rpc-relay-cursor',
      );

      check(command.containsKey('pagination')).isFalse();
      final params = command['params']! as Map<String, Object?>;
      final options = params['options']! as Map<String, Object?>;
      check(options['cursor']).equals('cursor-token');
    });

    test('merges executeOptions and pagination into relay options', () {
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1 ORDER BY 1',
        executeOptions: AgentSqlExecuteOptions(maxRows: 500),
        pagination: AgentSqlPagePagination(page: 2, pageSize: 50),
      );

      final command = builder.buildRelayCommand(
        request: request,
        rpcId: 'rpc-relay-merge',
      );

      final params = command['params']! as Map<String, Object?>;
      final options = params['options']! as Map<String, Object?>;
      check(options['max_rows']).equals(500);
      check(options['page']).equals(2);
      check(options['page_size']).equals(50);
    });

    test('REST build keeps pagination at body level, not in relay options', () {
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1 ORDER BY 1',
        pagination: AgentSqlPagePagination(page: 1, pageSize: 10),
      );

      final restBody = builder.build(request: request, rpcId: 'rpc-rest');
      final relayCommand = builder.buildRelayCommand(
        request: request,
        rpcId: 'rpc-rest',
      );

      check(restBody.containsKey('pagination')).isTrue();
      final restParams =
          (restBody['command']! as Map<String, Object?>)['params']!
              as Map<String, Object?>;
      check(restParams.containsKey('options')).isFalse();

      final relayParams = relayCommand['params']! as Map<String, Object?>;
      final relayOptions = relayParams['options']! as Map<String, Object?>;
      check(relayOptions['page']).equals(1);
      check(relayOptions['page_size']).equals(10);
    });
  });
}
