import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_failure_codes.dart';
import 'package:colmeia/features/agent_queries/data/repositories/circuit_breaker_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  const request = AgentSqlExecuteRequest(
    agentId: 'agent-1',
    sql: 'SELECT 1',
  );

  test(
    'should open breaker when socket or relay transport failures repeat',
    () async {
      final delegate = _SequenceAgentQueriesRepository();
      final breaker = CircuitBreakerAgentQueriesRepository(
        delegate: delegate,
        failureThreshold: 2,
        cooldownPeriod: const Duration(minutes: 1),
      );
      delegate
        ..enqueue(_networkFailureWithTransportCode('disconnected'))
        ..enqueue(_networkFailureWithTransportCode('conversation_lost'));

      final first = await breaker.executeSql(request);
      final second = await breaker.executeSql(request);
      final third = await breaker.executeSql(request);

      check(first.isError()).isTrue();
      check(second.isError()).isTrue();
      check(third.isError()).isTrue();
      check(delegate.callCount).equals(2);
      check(breaker.stateFor('agent-1')).equals('open');
      check(
        third.exceptionOrNull()?.message,
      ).isNotNull().contains('Circuit breaker open');
    },
  );

  test(
    'should ignore non-overload network failures when deciding breaker state',
    () async {
      final delegate = _SequenceAgentQueriesRepository();
      final breaker = CircuitBreakerAgentQueriesRepository(
        delegate: delegate,
        failureThreshold: 1,
      );
      delegate.enqueue(
        const Failure<AgentSqlExecutionResult, AppFailure>(
          NetworkFailure(
            message: 'rate limited',
            userMessage: 'Rate limited',
            context: <String, Object?>{
              AgentQueriesFailureContext.transportCodeField: 'rate_limited',
            },
            retryAfter: Duration(seconds: 10),
          ),
        ),
      );

      final result = await breaker.executeSql(request);

      check(result.isError()).isTrue();
      check(delegate.callCount).equals(1);
      check(breaker.stateFor('agent-1')).equals('closed');
      check(breaker.consecutiveFailuresFor('agent-1')).equals(0);
    },
  );

  test(
    'should isolate breaker state per agentId so one agent does not block others',
    () async {
      final delegate = _SequenceAgentQueriesRepository();
      final breaker = CircuitBreakerAgentQueriesRepository(
        delegate: delegate,
        failureThreshold: 2,
        cooldownPeriod: const Duration(minutes: 1),
      );
      delegate
        ..enqueue(_networkFailureWithTransportCode('disconnected'))
        ..enqueue(_networkFailureWithTransportCode('disconnected'))
        ..enqueue(
          const Success<AgentSqlExecutionResult, AppFailure>(
            AgentSqlExecutionResult(
              rows: <Map<String, dynamic>>[],
              rowCount: 0,
            ),
          ),
        );

      const requestA = AgentSqlExecuteRequest(
        agentId: 'agent-A',
        sql: 'SELECT 1',
      );
      const requestB = AgentSqlExecuteRequest(
        agentId: 'agent-B',
        sql: 'SELECT 1',
      );

      await breaker.executeSql(requestA);
      await breaker.executeSql(requestA);

      check(breaker.stateFor('agent-A')).equals('open');
      check(breaker.stateFor('agent-B')).equals('closed');

      final resultForB = await breaker.executeSql(requestB);

      check(resultForB.isSuccess()).isTrue();
      check(breaker.stateFor('agent-A')).equals('open');
      check(breaker.stateFor('agent-B')).equals('closed');
    },
  );
}

Failure<AgentSqlExecutionResult, AppFailure> _networkFailureWithTransportCode(
  String code,
) {
  return Failure<AgentSqlExecutionResult, AppFailure>(
    NetworkFailure(
      message: 'Transport failure: $code',
      userMessage: 'Nao foi possivel conectar ao servidor.',
      context: <String, Object?>{
        AgentQueriesFailureContext.transportField: 'socket',
        AgentQueriesFailureContext.transportCodeField: code,
      },
    ),
  );
}

final class _SequenceAgentQueriesRepository implements AgentQueriesRepository {
  final List<AppResult<AgentSqlExecutionResult>> _results =
      <AppResult<AgentSqlExecutionResult>>[];

  int callCount = 0;

  void enqueue(AppResult<AgentSqlExecutionResult> result) {
    _results.add(result);
  }

  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    callCount++;
    return _results.removeAt(0);
  }

  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    throw UnimplementedError();
  }
}
