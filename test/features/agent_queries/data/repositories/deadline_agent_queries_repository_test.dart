import 'dart:async';
import 'dart:math';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/repositories/adaptive_timeout_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/data/repositories/deadline_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/data/repositories/retrying_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_deadline.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

class _Delegate implements AgentQueriesRepository {
  _Delegate(this.run);
  final Future<AppResult<AgentSqlExecutionResult>> Function(
    AgentSqlExecuteRequest,
    AgentQueriesCancelScope?,
  )
  run;
  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) => run(request, cancelScope);
  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    await run(
      const AgentSqlExecuteRequest(agentId: 'a', sql: 'SELECT 1'),
      cancelScope,
    );
    return const Failure(NetworkFailure(message: 'batch'));
  }
}

void main() {
  const request = AgentSqlExecuteRequest(
    agentId: 'a',
    sql: 'SELECT 1',
    totalTimeoutMs: 30,
  );
  const success = Success<AgentSqlExecutionResult, AppFailure>(
    AgentSqlExecutionResult(rows: [], rowCount: 0),
  );
  test(
    'should enforce deadline and ignore a late successful response',
    () async {
      final pending = Completer<AppResult<AgentSqlExecutionResult>>();
      AgentQueriesCancelScope? child;
      final repo = DeadlineAgentQueriesRepository(
        delegate: _Delegate((_, scope) {
          child = scope;
          return pending.future;
        }),
      );
      final result = await repo.executeSql(request);
      expect(result.exceptionOrNull()?.context['deadlineExceeded'], true);
      expect(child!.isCancelled, true);
      pending.complete(success);
      await Future<void>.delayed(Duration.zero);
    },
  );
  test(
    'should distinguish user cancellation and leave the parent independent',
    () async {
      final parent = AgentQueriesCancelScope();
      final pending = Completer<AppResult<AgentSqlExecutionResult>>();
      final repo = DeadlineAgentQueriesRepository(
        delegate: _Delegate((_, scope) => pending.future),
      );
      final result = repo.executeSql(request, cancelScope: parent);
      parent.cancelAll();
      expect(
        (await result).exceptionOrNull(),
        isA<OperationCancelledFailure>(),
      );
      pending.complete(success);
    },
  );
  test('should clamp an adaptive attempt to the remaining budget', () async {
    int? attemptTimeout;
    final repo = DeadlineAgentQueriesRepository(
      delegate: AdaptiveTimeoutAgentQueriesRepository(
        delegate: _Delegate((req, _) async {
          attemptTimeout = req.bridgeTimeoutMs;
          return success;
        }),
      ),
    );
    expect(
      (await repo.executeSql(request.copyWith(bridgeTimeoutMs: 1000)))
          .isSuccess(),
      true,
    );
    expect(attemptTimeout, inInclusiveRange(1, 30));
  });
  test('should cancel backoff without starting another attempt', () async {
    var attempts = 0;
    final repo = DeadlineAgentQueriesRepository(
      delegate: RetryingAgentQueriesRepository(
        delegate: _Delegate((_, scope) async {
          attempts++;
          return const Failure(NetworkFailure(message: 'transient'));
        }),
        initialRetryDelay: const Duration(seconds: 10),
        random: Random(123),
      ),
    );
    final result = await repo.executeSql(request);
    expect(result.isError(), true);
    expect(attempts, 1);
  });
  test('should enforce the same deadline for batch requests', () async {
    final pending = Completer<AppResult<AgentSqlExecutionResult>>();
    final repo = DeadlineAgentQueriesRepository(
      delegate: _Delegate((_, scope) => pending.future),
    );
    final result = await repo.executeSqlBatch(
      const AgentSqlExecuteBatchRequest(
        agentId: 'a',
        commands: [AgentSqlExecuteBatchCommand(sql: 'SELECT 1')],
        totalTimeoutMs: 20,
      ),
    );
    expect(result.exceptionOrNull()?.context['deadlineExceeded'], true);
    pending.complete(success);
  });
  test('an expired parent deadline cannot start an attempt', () async {
    var attempts = 0;
    final scope = AgentQueriesCancelScope(
      deadline: AgentQueryDeadline(Duration.zero),
    );
    final repo = DeadlineAgentQueriesRepository(
      delegate: _Delegate((_, _) async {
        attempts++;
        return success;
      }),
    );
    final result = await repo.executeSql(request, cancelScope: scope);
    expect(result.exceptionOrNull()?.context['deadlineExceeded'], true);
    expect(attempts, 0);
    expect(scope.isCancelled, false);
  });
}
