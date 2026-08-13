import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

final class _FakeAgentQueriesRepository implements AgentQueriesRepository {
  const _FakeAgentQueriesRepository(this.result);

  final AppResult<AgentSqlExecutionResult> result;

  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    return result;
  }

  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  const request = AgentSqlExecuteRequest(agentId: 'agent-1', sql: 'SELECT 1');
  const executionResult = AgentSqlExecutionResult(
    rows: <Map<String, dynamic>>[
      <String, dynamic>{'value': 42},
    ],
    rowCount: 1,
  );

  test('maps successful execution result', () async {
    const repository = _FakeAgentQueriesRepository(
      Success<AgentSqlExecutionResult, AppFailure>(executionResult),
    );

    final result = await AgentSqlRepositoryExecution.execute<int>(
      agentQueriesRepository: repository,
      request: request,
      operation: 'testOperation',
      agentId: 'agent-1',
      mapExecution: (executionResult) =>
          executionResult.rows.single['value'] as int,
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrThrow()).equals(42);
  });

  test('propagates failure from executeSql', () async {
    const failure = NetworkFailure(message: 'network down');
    const repository = _FakeAgentQueriesRepository(
      Failure<AgentSqlExecutionResult, AppFailure>(failure),
    );

    final result = await AgentSqlRepositoryExecution.execute<int>(
      agentQueriesRepository: repository,
      request: request,
      operation: 'testOperation',
      agentId: 'agent-1',
      mapExecution: (_) => 1,
    );

    check(result.isError()).isTrue();
    result.fold(
      (_) => fail('expected failure'),
      (actualFailure) => expect(actualFailure, same(failure)),
    );
  });

  test('converts FormatException to UnknownFailure', () {
    final result = AgentSqlRepositoryExecution.mapExecutionResult<int>(
      executionResult,
      operation: 'testOperation',
      agentId: 'agent-1',
      mapExecution: (_) => throw const FormatException('bad row'),
    );

    check(result.isError()).isTrue();
    result.fold(
      (_) => fail('expected failure'),
      (failure) {
        check(failure).isA<UnknownFailure>();
        check(failure.message).equals('bad row');
        check(failure.context['operation']).equals('testOperation');
        check(failure.context['agentId']).equals('agent-1');
        check(failure.context['rowCount']).equals(1);
        check(
          failure.context['firstRowKeys'],
        ).isA<List<String>>().deepEquals(<String>['value']);
      },
    );
  });

  test('converts ArgumentError to UnknownFailure', () {
    final result = AgentSqlRepositoryExecution.mapExecutionResult<int>(
      executionResult,
      operation: 'testOperation',
      agentId: 'agent-1',
      mapExecution: (_) => throw ArgumentError.value('x', 'field', 'bad'),
    );

    check(result.isError()).isTrue();
    result.fold(
      (_) => fail('expected failure'),
      (failure) {
        check(failure).isA<UnknownFailure>();
        check(failure.message).contains('Invalid argument');
        check(failure.context['operation']).equals('testOperation');
        check(failure.context['agentId']).equals('agent-1');
      },
    );
  });

  test('rethrows unexpected errors', () {
    expect(
      () => AgentSqlRepositoryExecution.mapExecutionResult<int>(
        executionResult,
        operation: 'testOperation',
        agentId: 'agent-1',
        mapExecution: (_) => throw StateError('boom'),
      ),
      throwsA(isA<StateError>()),
    );
  });
}
