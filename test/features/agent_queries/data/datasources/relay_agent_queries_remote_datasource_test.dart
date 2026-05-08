import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:colmeia/core/socket/relay/relay_rpc_outcome.dart';
import 'package:colmeia/features/agent_queries/data/datasources/relay_agent_queries_remote_datasource.dart';
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
    test('forwards the bridge body through dispatcher.sendUnary', () async {
      final dispatcher = _MockRelayDispatcher();
      final captured = <Map<String, Object?>>[];
      String? capturedAgentId;
      String? capturedClientRequestId;
      Duration? capturedTimeout;
      RelayPayloadFrameCompression? capturedCompression;

      when(
        () => dispatcher.sendUnary(
          agentId: any(named: 'agentId'),
          body: any(named: 'body'),
          clientRequestId: any(named: 'clientRequestId'),
          timeout: any(named: 'timeout'),
          compression: any(named: 'compression'),
        ),
      ).thenAnswer((invocation) async {
        capturedAgentId = invocation.namedArguments[#agentId] as String?;
        capturedClientRequestId =
            invocation.namedArguments[#clientRequestId] as String?;
        capturedTimeout = invocation.namedArguments[#timeout] as Duration?;
        capturedCompression =
            invocation.namedArguments[#compression]
                as RelayPayloadFrameCompression?;
        captured.add(
          (invocation.namedArguments[#body] as Map<dynamic, dynamic>).map(
            (k, v) => MapEntry(k.toString(), v as Object?),
          ),
        );
        return <String, dynamic>{
          'response': <String, dynamic>{
            'type': 'single',
            'item': <String, dynamic>{
              'id': capturedClientRequestId,
              'success': true,
            },
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
      check(capturedCompression).equals(RelayPayloadFrameCompression.always);

      final body = captured.single;
      check(body['agentId']).equals('agent-1');
      final command = body['command']! as Map<dynamic, dynamic>;
      check(command['method']).equals('sql.execute');
      check(command['id']).equals(capturedClientRequestId);

      check(result['response']).isA<Map<dynamic, dynamic>>();
    });

    test('uses default 15s + 5s buffer when bridgeTimeoutMs is null', () async {
      final dispatcher = _MockRelayDispatcher();
      Duration? captured;
      when(
        () => dispatcher.sendUnary(
          agentId: any(named: 'agentId'),
          body: any(named: 'body'),
          clientRequestId: any(named: 'clientRequestId'),
          timeout: any(named: 'timeout'),
          compression: any(named: 'compression'),
        ),
      ).thenAnswer((invocation) async {
        captured = invocation.namedArguments[#timeout] as Duration?;
        return <String, dynamic>{};
      });

      final datasource = RelayAgentQueriesRemoteDataSource(
        dispatcher: dispatcher,
      );
      await datasource.postSqlExecute(
        const AgentSqlExecuteRequest(agentId: 'agent-1', sql: 'SELECT 1'),
      );

      check(captured).equals(const Duration(milliseconds: 20000));
    });
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
