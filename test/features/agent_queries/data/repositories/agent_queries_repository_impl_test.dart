import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_bridge_pagination.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAgentQueriesRemoteDataSource extends Mock
    implements AgentQueriesRemoteDataSource {}

void main() {
  late _MockAgentQueriesRemoteDataSource remoteDataSource;
  late AgentQueriesRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const AgentSqlExecuteRequest(
        agentId: 'fallback-agent',
        sql: 'SELECT 1',
      ),
    );
  });

  setUp(() {
    remoteDataSource = _MockAgentQueriesRemoteDataSource();
    repository = AgentQueriesRepositoryImpl(remoteDataSource);
  });

  test(
    'should return validation failure when preserve mode is combined '
    'with pagination',
    () async {
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT * FROM table ORDER BY id',
        pagination: AgentSqlPagePagination(page: 1, pageSize: 20),
        executeOptions: AgentSqlExecuteOptions(
          executionMode: AgentSqlExecutionMode.preserve,
        ),
      );

      final result = await repository.executeSql(request);

      check(result.isError()).isTrue();
      check(result.exceptionOrNull()).isA<ValidationFailure>();
      check(result.exceptionOrNull()?.displayMessage).equals(
        'Os parametros da consulta do agente sao invalidos.',
      );
      verifyNever(() => remoteDataSource.postSqlExecute(any()));
    },
  );

  test(
    'should preserve rpc error details when bridge returns item error',
    () async {
      when(
        () => remoteDataSource.postSqlExecute(any()),
      ).thenAnswer(
        (_) async => <String, dynamic>{
          'response': <String, dynamic>{
            'success': false,
            'item': <String, dynamic>{
              'success': false,
              'error': <String, dynamic>{
                'code': -32008,
                'message': 'SQL timeout',
                'data': <String, dynamic>{
                  'reason': 'timeout',
                  'category': 'transport',
                  'retryable': true,
                  'user_message': 'Tempo esgotado para consultar o agente.',
                  'technical_message': 'bridge timeout waiting rpc:response',
                  'correlation_id': 'corr-123',
                  'timestamp': '2026-04-08T21:15:00Z',
                },
              },
            },
          },
        },
      );

      final result = await repository.executeSql(
        const AgentSqlExecuteRequest(
          agentId: 'agent-1',
          sql: 'SELECT 1',
        ),
      );

      check(result.isError()).isTrue();
      final failure = result.exceptionOrNull();
      check(failure).isA<RpcFailure>();
      final rpcFailure = failure! as RpcFailure;
      check(rpcFailure.displayMessage).equals(
        'Tempo esgotado para consultar o agente.',
      );
      check(rpcFailure.isTransient).isTrue();
      check(rpcFailure.rpcCode).equals(-32008);
      check(rpcFailure.reason).equals('timeout');
      check(rpcFailure.category).equals('transport');
      check(rpcFailure.technicalMessage).equals(
        'bridge timeout waiting rpc:response',
      );
      check(rpcFailure.correlationId).equals('corr-123');
      check(
        rpcFailure.timestamp,
      ).equals(DateTime.parse('2026-04-08T21:15:00Z'));
    },
  );
}
