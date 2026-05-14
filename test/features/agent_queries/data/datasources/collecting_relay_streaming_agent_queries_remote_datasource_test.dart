import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_streaming_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/collecting_relay_streaming_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStreamingDatasource extends Mock
    implements AgentQueriesStreamingRemoteDataSource {}

class _MockRemoteDatasource extends Mock
    implements AgentQueriesRemoteDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const AgentSqlExecuteRequest(agentId: 'a', sql: 'SELECT 1'),
    );
    registerFallbackValue(
      const AgentSqlExecuteBatchRequest(
        agentId: 'a',
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
        ],
      ),
    );
  });

  group('CollectingRelayStreamingAgentQueriesRemoteDataSource', () {
    test(
      'collects chunks from streamSqlExecute into the unary bridge envelope',
      () async {
        final delegate = _MockStreamingDatasource();
        when(() => delegate.streamSqlExecute(any())).thenAnswer(
          (_) =>
              Stream<Map<String, dynamic>>.fromIterable(<Map<String, dynamic>>[
                <String, dynamic>{
                  'stream_id': 's1',
                  'request_id': 'r1',
                  'chunk_index': 0,
                  'rows': <Object?>[
                    <String, Object?>{'k': 'v1'},
                  ],
                },
                <String, dynamic>{
                  'stream_id': 's1',
                  'request_id': 'r1',
                  'chunk_index': 1,
                  'rows': <Object?>[
                    <String, Object?>{'k': 'v2'},
                  ],
                },
                <String, dynamic>{
                  'stream_id': 's1',
                  'request_id': 'r1',
                  'total_rows': 2,
                  'execution_id': 'exec-1',
                },
              ]),
        );

        final adapter = CollectingRelayStreamingAgentQueriesRemoteDataSource(
          streamingDelegate: delegate,
        );

        final envelope = await adapter.postSqlExecute(
          const AgentSqlExecuteRequest(
            agentId: 'agent-1',
            sql: 'SELECT * FROM tbl',
          ),
        );
        final item =
            (envelope['response']! as Map)['item']! as Map<String, dynamic>;
        check(item['success']).equals(true);
        final result = item['result']! as Map<String, dynamic>;
        check((result['rows']! as List).length).equals(2);
        check(result['row_count']).equals(2);
        check(result['execution_id']).equals('exec-1');
      },
    );

    test('serializes postSqlExecute for the same agent id', () async {
      final delegate = _MockStreamingDatasource();
      final firstStreamStarted = Completer<void>();
      var streamSqlExecuteCalls = 0;
      when(() => delegate.streamSqlExecute(any())).thenAnswer((_) {
        streamSqlExecuteCalls++;
        final id = streamSqlExecuteCalls;
        final controller = StreamController<Map<String, dynamic>>();
        unawaited(
          (() async {
            if (id == 1) {
              firstStreamStarted.complete();
              await Future<void>.delayed(const Duration(milliseconds: 60));
            } else {
              await firstStreamStarted.future;
              await Future<void>.delayed(const Duration(milliseconds: 5));
            }
            controller.add(<String, dynamic>{
              'request_id': 'r$id',
              'total_rows': 0,
            });
            await controller.close();
          })(),
        );
        return controller.stream;
      });

      final adapter = CollectingRelayStreamingAgentQueriesRemoteDataSource(
        streamingDelegate: delegate,
      );

      const agentReq = AgentSqlExecuteRequest(agentId: 'same-agent', sql: 'q');
      final first = adapter.postSqlExecute(agentReq);
      await firstStreamStarted.future;
      check(streamSqlExecuteCalls).equals(1);

      final second = adapter.postSqlExecute(
        const AgentSqlExecuteRequest(agentId: 'same-agent', sql: 'q2'),
      );
      await Future<void>.delayed(Duration.zero);
      check(streamSqlExecuteCalls).equals(1);

      await first;
      await Future<void>.delayed(Duration.zero);
      check(streamSqlExecuteCalls).equals(2);
      await second;
    });

    test('serializes equivalent trimmed agent ids', () async {
      final delegate = _MockStreamingDatasource();
      final firstStreamStarted = Completer<void>();
      var streamSqlExecuteCalls = 0;
      when(() => delegate.streamSqlExecute(any())).thenAnswer((_) {
        streamSqlExecuteCalls++;
        final id = streamSqlExecuteCalls;
        final controller = StreamController<Map<String, dynamic>>();
        unawaited(
          (() async {
            if (id == 1) {
              firstStreamStarted.complete();
              await Future<void>.delayed(const Duration(milliseconds: 60));
            } else {
              await firstStreamStarted.future;
            }
            controller.add(<String, dynamic>{
              'request_id': 'trimmed-$id',
              'total_rows': 0,
            });
            await controller.close();
          })(),
        );
        return controller.stream;
      });

      final adapter = CollectingRelayStreamingAgentQueriesRemoteDataSource(
        streamingDelegate: delegate,
      );

      final first = adapter.postSqlExecute(
        const AgentSqlExecuteRequest(agentId: 'agent-trim', sql: 'q'),
      );
      await firstStreamStarted.future;

      final second = adapter.postSqlExecute(
        const AgentSqlExecuteRequest(agentId: ' agent-trim ', sql: 'q2'),
      );
      await Future<void>.delayed(Duration.zero);

      check(streamSqlExecuteCalls).equals(1);
      await first;
      await Future<void>.delayed(Duration.zero);
      check(streamSqlExecuteCalls).equals(2);
      await second;
    });

    test(
      'completed tails do not block later calls for the same agent',
      () async {
        final delegate = _MockStreamingDatasource();
        var streamSqlExecuteCalls = 0;
        when(() => delegate.streamSqlExecute(any())).thenAnswer((_) {
          streamSqlExecuteCalls++;
          return Stream<Map<String, dynamic>>.fromIterable(
            <Map<String, dynamic>>[
              <String, dynamic>{
                'request_id': 'later-$streamSqlExecuteCalls',
                'total_rows': 0,
              },
            ],
          );
        });

        final adapter = CollectingRelayStreamingAgentQueriesRemoteDataSource(
          streamingDelegate: delegate,
        );

        await adapter.postSqlExecute(
          const AgentSqlExecuteRequest(agentId: 'agent-cleanup', sql: 'q1'),
        );
        await adapter.postSqlExecute(
          const AgentSqlExecuteRequest(agentId: 'agent-cleanup', sql: 'q2'),
        );

        check(streamSqlExecuteCalls).equals(2);
      },
    );

    test('propagates stream errors as Future errors', () async {
      final delegate = _MockStreamingDatasource();
      when(() => delegate.streamSqlExecute(any())).thenAnswer(
        (_) => Stream<Map<String, dynamic>>.error(
          const FormatException('boom'),
        ),
      );

      final adapter = CollectingRelayStreamingAgentQueriesRemoteDataSource(
        streamingDelegate: delegate,
      );

      await expectLater(
        () => adapter.postSqlExecute(
          const AgentSqlExecuteRequest(agentId: 'a', sql: 'SELECT 1'),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'delegates sql.executeBatch to the configured batch datasource',
      () async {
        final streaming = _MockStreamingDatasource();
        final batch = _MockRemoteDatasource();
        when(
          () => batch.postSqlExecuteBatch(any()),
        ).thenAnswer(
          (_) async => <String, dynamic>{'response': 'batch-from-relay'},
        );

        final adapter = CollectingRelayStreamingAgentQueriesRemoteDataSource(
          streamingDelegate: streaming,
          batchDelegate: batch,
        );

        final response = await adapter.postSqlExecuteBatch(
          const AgentSqlExecuteBatchRequest(
            agentId: 'agent-1',
            commands: <AgentSqlExecuteBatchCommand>[
              AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
            ],
          ),
        );

        check(response['response']).equals('batch-from-relay');
        verify(() => batch.postSqlExecuteBatch(any())).called(1);
        verifyNever(() => streaming.streamSqlExecute(any()));
      },
    );
  });
}
