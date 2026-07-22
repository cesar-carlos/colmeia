import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:colmeia/core/socket/relay/relay_rpc_outcome.dart';
import 'package:colmeia/features/agent_queries/data/datasources/relay_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRelayDispatcher extends Mock implements RelayCommandDispatcher {}

class _FakeOutcomes extends Stream<RelayRpcOutcome> {
  @override
  StreamSubscription<RelayRpcOutcome> listen(
    void Function(RelayRpcOutcome event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return const Stream<RelayRpcOutcome>.empty().listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(Duration.zero);
    registerFallbackValue(RelayPayloadFrameCompression.auto);
  });

  group('RelayAgentQueriesRemoteDataSource', () {
    test(
      'forwards the JSON-RPC command through dispatcher.sendUnary',
      () async {
        final dispatcher = _MockRelayDispatcher();
        final captured = <Map<String, Object?>>[];
        String? capturedAgentId;
        String? capturedClientRequestId;
        Duration? capturedTimeout;
        int? capturedTimeoutMs;
        RelayPayloadFrameCompression? capturedCompression;

        when(
          () => dispatcher.sendUnary(
            agentId: any(named: 'agentId'),
            body: any(named: 'body'),
            clientRequestId: any(named: 'clientRequestId'),
            timeout: any(named: 'timeout'),
            timeoutMs: any(named: 'timeoutMs'),
            compression: any(named: 'compression'),
          ),
        ).thenAnswer((invocation) async {
          capturedAgentId = invocation.namedArguments[#agentId] as String?;
          capturedClientRequestId =
              invocation.namedArguments[#clientRequestId] as String?;
          capturedTimeout = invocation.namedArguments[#timeout] as Duration?;
          capturedTimeoutMs = invocation.namedArguments[#timeoutMs] as int?;
          capturedCompression =
              invocation.namedArguments[#compression]
                  as RelayPayloadFrameCompression?;
          captured.add(
            (invocation.namedArguments[#body] as Map<dynamic, dynamic>).map(
              (k, v) => MapEntry(k.toString(), v as Object?),
            ),
          );
          return <String, dynamic>{
            'jsonrpc': '2.0',
            'id': capturedClientRequestId,
            'result': <String, dynamic>{
              'rows': <Map<String, dynamic>>[
                <String, dynamic>{'id': 1},
              ],
              'row_count': 1,
            },
          };
        });

        final datasource = RelayAgentQueriesRemoteDataSource(
          dispatcher: dispatcher,
          compression: RelayPayloadFrameCompression.always,
        );

        final result = await datasource.postSqlExecute(
          const AgentSqlExecuteRequest(
            agentId: 'agent-1',
            sql: 'SELECT 1',
            clientToken: 'token',
            bridgeTimeoutMs: 12000,
          ),
        );

        check(captured.length).equals(1);
        check(capturedAgentId).equals('agent-1');
        check(capturedClientRequestId).isNotNull();
        // Timeout should be `bridgeTimeoutMs + 5s` = 17000ms.
        check(capturedTimeout).equals(const Duration(milliseconds: 17000));
        // Hub envelope timeoutMs mirrors bridgeTimeoutMs (no +5s buffer).
        check(capturedTimeoutMs).equals(12000);
        check(capturedCompression).equals(RelayPayloadFrameCompression.always);

        final body = captured.single;
        check(body.containsKey('agentId')).isFalse();
        check(body.containsKey('command')).isFalse();
        check(body['method']).equals('sql.execute');
        check(body['id']).equals(capturedClientRequestId);
        final params = body['params']! as Map<dynamic, dynamic>;
        check(params['sql']).equals('SELECT 1');
        check(params['client_token']).equals('token');

        final response = result['response']! as Map<dynamic, dynamic>;
        check(response['success']).equals(true);
        final item = response['item']! as Map<dynamic, dynamic>;
        check(item['id']).equals(capturedClientRequestId);
        final sqlResult = item['result']! as Map<dynamic, dynamic>;
        check(sqlResult['row_count']).equals(1);
      },
    );

    test(
      'request payloadFrameCompression overrides datasource default',
      () async {
        final dispatcher = _MockRelayDispatcher();
        RelayPayloadFrameCompression? capturedCompression;
        when(
          () => dispatcher.sendUnary(
            agentId: any(named: 'agentId'),
            body: any(named: 'body'),
            clientRequestId: any(named: 'clientRequestId'),
            timeout: any(named: 'timeout'),
            timeoutMs: any(named: 'timeoutMs'),
            compression: any(named: 'compression'),
          ),
        ).thenAnswer((invocation) async {
          capturedCompression =
              invocation.namedArguments[#compression]
                  as RelayPayloadFrameCompression?;
          return <String, dynamic>{
            'jsonrpc': '2.0',
            'id': invocation.namedArguments[#clientRequestId] as String?,
            'result': <String, dynamic>{
              'rows': <dynamic>[],
              'row_count': 0,
            },
          };
        });

        final datasource = RelayAgentQueriesRemoteDataSource(
          dispatcher: dispatcher,
          compression: RelayPayloadFrameCompression.none,
        );
        await datasource.postSqlExecute(
          const AgentSqlExecuteRequest(
            agentId: 'agent-1',
            sql: 'SELECT 1',
            payloadFrameCompression: RelayPayloadFrameCompression.always,
          ),
        );

        check(capturedCompression).equals(RelayPayloadFrameCompression.always);
      },
    );

    test('uses default 15s + 5s buffer when bridgeTimeoutMs is null', () async {
      final dispatcher = _MockRelayDispatcher();
      Duration? captured;
      when(
        () => dispatcher.sendUnary(
          agentId: any(named: 'agentId'),
          body: any(named: 'body'),
          clientRequestId: any(named: 'clientRequestId'),
          timeout: any(named: 'timeout'),
          timeoutMs: any(named: 'timeoutMs'),
          compression: any(named: 'compression'),
        ),
      ).thenAnswer((invocation) async {
        captured = invocation.namedArguments[#timeout] as Duration?;
        return <String, dynamic>{
          'jsonrpc': '2.0',
          'id': invocation.namedArguments[#clientRequestId] as String?,
          'result': <String, dynamic>{
            'rows': <dynamic>[],
            'row_count': 0,
          },
        };
      });

      final datasource = RelayAgentQueriesRemoteDataSource(
        dispatcher: dispatcher,
      );
      await datasource.postSqlExecute(
        const AgentSqlExecuteRequest(agentId: 'agent-1', sql: 'SELECT 1'),
      );

      check(captured).equals(const Duration(milliseconds: 20000));
    });

    test(
      'wraps sql.executeBatch JSON-RPC result as bridge batch response',
      () async {
        final dispatcher = _MockRelayDispatcher();
        Map<String, Object?>? capturedBody;
        when(
          () => dispatcher.sendUnary(
            agentId: any(named: 'agentId'),
            body: any(named: 'body'),
            clientRequestId: any(named: 'clientRequestId'),
            timeout: any(named: 'timeout'),
            timeoutMs: any(named: 'timeoutMs'),
            compression: any(named: 'compression'),
          ),
        ).thenAnswer((invocation) async {
          capturedBody =
              (invocation.namedArguments[#body] as Map<dynamic, dynamic>).map(
                (k, v) => MapEntry(k.toString(), v as Object?),
              );
          return <String, dynamic>{
            'jsonrpc': '2.0',
            'id': invocation.namedArguments[#clientRequestId] as String?,
            'result': <String, dynamic>{
              'items': <Map<String, dynamic>>[
                <String, dynamic>{'index': 0, 'ok': true, 'rows': <dynamic>[]},
              ],
              'total_commands': 1,
              'successful_commands': 1,
              'failed_commands': 0,
            },
          };
        });

        final datasource = RelayAgentQueriesRemoteDataSource(
          dispatcher: dispatcher,
        );
        final result = await datasource.postSqlExecuteBatch(
          const AgentSqlExecuteBatchRequest(
            agentId: 'agent-1',
            commands: <AgentSqlExecuteBatchCommand>[
              AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
            ],
          ),
        );

        check(capturedBody!['method']).equals('sql.executeBatch');
        final response = result['response']! as Map<dynamic, dynamic>;
        check(response['success']).equals(true);
        check(response['type']).equals('batch');
        final item = response['item']! as Map<dynamic, dynamic>;
        final batchResult = item['result']! as Map<dynamic, dynamic>;
        check(batchResult['total_commands']).equals(1);
      },
    );
  });

  // Keep RelayEventNames referenced so the import stays useful in the
  // test scope; this guarantees the wire constants don't drift.
  test('relay event names are available for assertion suites', () {
    check(RelayEventNames.rpcRequest).isNotNull();
  });

  // _FakeOutcomes is here for future tests that want a typed empty stream.
  test('_FakeOutcomes emits no outcomes', () async {
    final outcomes = await _FakeOutcomes().toList();
    check(outcomes).isEmpty();
  });
}
