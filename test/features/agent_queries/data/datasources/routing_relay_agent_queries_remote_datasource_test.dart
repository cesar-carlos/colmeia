import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/routing_relay_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemoteDatasource extends Mock
    implements AgentQueriesRemoteDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const AgentSqlExecuteRequest(agentId: 'agent-1', sql: 'SELECT 1'),
    );
    registerFallbackValue(
      const AgentSqlExecuteBatchRequest(
        agentId: 'agent-1',
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
        ],
      ),
    );
  });

  group('RoutingRelayAgentQueriesRemoteDataSource', () {
    test('routes sql.execute to unary by default', () async {
      final unary = _MockRemoteDatasource();
      final streaming = _MockRemoteDatasource();
      when(() => unary.postSqlExecute(any())).thenAnswer(
        (_) async => <String, dynamic>{'route': 'unary'},
      );

      final datasource = RoutingRelayAgentQueriesRemoteDataSource(
        unaryDelegate: unary,
        streamingDelegate: streaming,
      );
      final result = await datasource.postSqlExecute(
        const AgentSqlExecuteRequest(
          agentId: 'agent-1',
          sql: 'SELECT 1',
          useRelay: true,
        ),
      );

      check(result['route']).equals('unary');
      verify(() => unary.postSqlExecute(any())).called(1);
      verifyNever(() => streaming.postSqlExecute(any()));
    });

    test(
      'routes sql.execute to streaming when relayMode asks for it',
      () async {
        final unary = _MockRemoteDatasource();
        final streaming = _MockRemoteDatasource();
        when(() => streaming.postSqlExecute(any())).thenAnswer(
          (_) async => <String, dynamic>{'route': 'streaming'},
        );

        final datasource = RoutingRelayAgentQueriesRemoteDataSource(
          unaryDelegate: unary,
          streamingDelegate: streaming,
        );
        final result = await datasource.postSqlExecute(
          const AgentSqlExecuteRequest(
            agentId: 'agent-1',
            sql: 'SELECT 1',
            useRelay: true,
            relayMode: AgentSqlRelayMode.streaming,
          ),
        );

        check(result['route']).equals('streaming');
        verify(() => streaming.postSqlExecute(any())).called(1);
        verifyNever(() => unary.postSqlExecute(any()));
      },
    );

    test('routes sql.executeBatch through unary relay', () async {
      final unary = _MockRemoteDatasource();
      final streaming = _MockRemoteDatasource();
      when(() => unary.postSqlExecuteBatch(any())).thenAnswer(
        (_) async => <String, dynamic>{'route': 'batch-unary'},
      );

      final datasource = RoutingRelayAgentQueriesRemoteDataSource(
        unaryDelegate: unary,
        streamingDelegate: streaming,
      );
      final result = await datasource.postSqlExecuteBatch(
        const AgentSqlExecuteBatchRequest(
          agentId: 'agent-1',
          commands: <AgentSqlExecuteBatchCommand>[
            AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
          ],
          useRelay: true,
        ),
      );

      check(result['route']).equals('batch-unary');
      verify(() => unary.postSqlExecuteBatch(any())).called(1);
      verifyNever(() => streaming.postSqlExecuteBatch(any()));
    });
  });
}
