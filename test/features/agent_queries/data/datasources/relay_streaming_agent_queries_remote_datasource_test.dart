// Test-only: sequential `controller.add(...)` calls drive the
// dispatcher through distinct chunk-arrival phases; cascades would
// obscure the protocol shape these tests are pinning.
// ignore_for_file: cascade_invocations

import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:colmeia/features/agent_queries/data/datasources/relay_streaming_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRelayDispatcher extends Mock implements RelayCommandDispatcher {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(Duration.zero);
    registerFallbackValue(RelayPayloadFrameCompression.auto);
  });

  group('RelayStreamingAgentQueriesRemoteDataSource', () {
    test('forwards each chunk emitted by the dispatcher untouched', () async {
      final dispatcher = _MockRelayDispatcher();
      final controller = StreamController<Map<String, dynamic>>();
      addTearDown(controller.close);

      when(
        () => dispatcher.sendStreaming(
          agentId: any(named: 'agentId'),
          body: any(named: 'body'),
          clientRequestId: any(named: 'clientRequestId'),
          timeout: any(named: 'timeout'),
          compression: any(named: 'compression'),
        ),
      ).thenAnswer((_) => controller.stream);

      final datasource = RelayStreamingAgentQueriesRemoteDataSource(
        dispatcher: dispatcher,
      );

      final received = <Map<String, dynamic>>[];
      final sub = datasource
          .streamSqlExecute(
            const AgentSqlExecuteRequest(
              agentId: 'agent-1',
              sql: 'SELECT * FROM big_table',
            ),
          )
          .listen(received.add);

      controller.add(<String, dynamic>{'row': 0, 'value': 'a'});
      controller.add(<String, dynamic>{'row': 1, 'value': 'b'});
      controller.add(<String, dynamic>{'row': 2, 'value': 'c'});
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      check(received.length).equals(3);
      check(received[0]['row']).equals(0);
      check(received[2]['value']).equals('c');
    });

    test('forwards bridgeTimeoutMs + 5s as the relay timeout', () async {
      final dispatcher = _MockRelayDispatcher();
      Duration? capturedTimeout;
      when(
        () => dispatcher.sendStreaming(
          agentId: any(named: 'agentId'),
          body: any(named: 'body'),
          clientRequestId: any(named: 'clientRequestId'),
          timeout: any(named: 'timeout'),
          compression: any(named: 'compression'),
        ),
      ).thenAnswer((invocation) {
        capturedTimeout = invocation.namedArguments[#timeout] as Duration?;
        return const Stream<Map<String, dynamic>>.empty();
      });

      final datasource = RelayStreamingAgentQueriesRemoteDataSource(
        dispatcher: dispatcher,
      );
      await datasource
          .streamSqlExecute(
            const AgentSqlExecuteRequest(
              agentId: 'agent-1',
              sql: 'SELECT 1',
              bridgeTimeoutMs: 12000,
            ),
          )
          .toList();

      check(capturedTimeout).equals(const Duration(milliseconds: 17000));
    });

    test(
      'uses the default 15s + 5s buffer when bridgeTimeoutMs is null',
      () async {
        final dispatcher = _MockRelayDispatcher();
        Duration? capturedTimeout;
        when(
          () => dispatcher.sendStreaming(
            agentId: any(named: 'agentId'),
            body: any(named: 'body'),
            clientRequestId: any(named: 'clientRequestId'),
            timeout: any(named: 'timeout'),
            compression: any(named: 'compression'),
          ),
        ).thenAnswer((invocation) {
          capturedTimeout = invocation.namedArguments[#timeout] as Duration?;
          return const Stream<Map<String, dynamic>>.empty();
        });

        final datasource = RelayStreamingAgentQueriesRemoteDataSource(
          dispatcher: dispatcher,
        );
        await datasource
            .streamSqlExecute(
              const AgentSqlExecuteRequest(
                agentId: 'agent-1',
                sql: 'SELECT 1',
              ),
            )
            .toList();

        check(capturedTimeout).equals(const Duration(milliseconds: 20000));
      },
    );

    test('passes the configured compression hint to the dispatcher', () async {
      final dispatcher = _MockRelayDispatcher();
      RelayPayloadFrameCompression? capturedCompression;
      when(
        () => dispatcher.sendStreaming(
          agentId: any(named: 'agentId'),
          body: any(named: 'body'),
          clientRequestId: any(named: 'clientRequestId'),
          timeout: any(named: 'timeout'),
          compression: any(named: 'compression'),
        ),
      ).thenAnswer((invocation) {
        capturedCompression =
            invocation.namedArguments[#compression]
                as RelayPayloadFrameCompression?;
        return const Stream<Map<String, dynamic>>.empty();
      });

      final datasource = RelayStreamingAgentQueriesRemoteDataSource(
        dispatcher: dispatcher,
        compression: RelayPayloadFrameCompression.always,
      );
      await datasource
          .streamSqlExecute(
            const AgentSqlExecuteRequest(
              agentId: 'agent-1',
              sql: 'SELECT 1',
            ),
          )
          .toList();

      check(capturedCompression).equals(RelayPayloadFrameCompression.always);
    });

    test(
      'builds the shared sql.execute body and correlates it with '
      'clientRequestId',
      () async {
        final dispatcher = _MockRelayDispatcher();
        final captured = <Map<String, Object?>>[];
        String? capturedAgentId;
        String? capturedClientRequestId;
        when(
          () => dispatcher.sendStreaming(
            agentId: any(named: 'agentId'),
            body: any(named: 'body'),
            clientRequestId: any(named: 'clientRequestId'),
            timeout: any(named: 'timeout'),
            compression: any(named: 'compression'),
          ),
        ).thenAnswer((invocation) {
          capturedAgentId = invocation.namedArguments[#agentId] as String?;
          capturedClientRequestId =
              invocation.namedArguments[#clientRequestId] as String?;
          captured.add(
            (invocation.namedArguments[#body] as Map<dynamic, dynamic>).map(
              (k, v) => MapEntry(k.toString(), v as Object?),
            ),
          );
          return const Stream<Map<String, dynamic>>.empty();
        });

        final datasource = RelayStreamingAgentQueriesRemoteDataSource(
          dispatcher: dispatcher,
        );
        await datasource
            .streamSqlExecute(
              const AgentSqlExecuteRequest(
                agentId: 'agent-1',
                sql: '''
                  SELECT *
                    FROM Cliente
                   WHERE ativo = :ativo
                ''',
                namedParams: <String, Object?>{'ativo': true},
                clientToken: 'token',
                useRelay: true,
                payloadFrameCompression: RelayPayloadFrameCompression.always,
              ),
            )
            .toList();

        check(capturedAgentId).equals('agent-1');
        check(captured.length).equals(1);
        final body = captured.single;
        check(body['agentId']).equals('agent-1');
        check(body['payloadFrameCompression']).equals('always');
        check(body.containsKey('useRelay')).isFalse();
        final command = body['command']! as Map<dynamic, dynamic>;
        check(command['id']).equals(capturedClientRequestId);
        check(command['method']).equals('sql.execute');
        final params = command['params']! as Map<dynamic, dynamic>;
        check(params['sql']).equals(
          'SELECT * FROM Cliente WHERE ativo = :ativo',
        );
        check(params['client_token']).equals('token');
        final namedParams = params['params']! as Map<dynamic, dynamic>;
        check(namedParams['ativo']).equals(true);
      },
    );

    test('propagates RelayDispatchException as a stream error', () async {
      final dispatcher = _MockRelayDispatcher();
      final controller = StreamController<Map<String, dynamic>>();
      addTearDown(controller.close);

      when(
        () => dispatcher.sendStreaming(
          agentId: any(named: 'agentId'),
          body: any(named: 'body'),
          clientRequestId: any(named: 'clientRequestId'),
          timeout: any(named: 'timeout'),
          compression: any(named: 'compression'),
        ),
      ).thenAnswer((_) => controller.stream);

      final datasource = RelayStreamingAgentQueriesRemoteDataSource(
        dispatcher: dispatcher,
      );
      final errors = <Object>[];
      final sub = datasource
          .streamSqlExecute(
            const AgentSqlExecuteRequest(
              agentId: 'agent-1',
              sql: 'SELECT 1',
            ),
          )
          .listen((_) {}, onError: errors.add);
      addTearDown(sub.cancel);

      controller.addError(
        const RelayStreamTerminated(
          message: 'aborted by hub',
          terminalStatus: 'aborted',
          conversationId: 'conv-1',
          clientRequestId: 'rpc-1',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      check(errors.length).equals(1);
      check(errors.single).isA<RelayStreamTerminated>();
    });
  });
}
