import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_streaming_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/collecting_relay_streaming_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStreamingDatasource extends Mock
    implements AgentQueriesStreamingRemoteDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const AgentSqlExecuteRequest(agentId: 'a', sql: 'SELECT 1'),
    );
  });

  group('CollectingRelayStreamingAgentQueriesRemoteDataSource', () {
    test(
      'collects chunks from streamSqlExecute into the unary bridge envelope',
      () async {
        final delegate = _MockStreamingDatasource();
        when(() => delegate.streamSqlExecute(any())).thenAnswer(
          (_) => Stream<Map<String, dynamic>>.fromIterable(<
            Map<String, dynamic>
          >[
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
  });
}
