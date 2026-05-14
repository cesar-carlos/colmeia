import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/repositories/coalescing_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_bridge_pagination.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  const baseRequest = AgentSqlExecuteRequest(
    agentId: 'agent-1',
    sql: 'SELECT 1',
    clientToken: 'token-1',
  );

  test(
    'should coalesce simultaneous identical requests and clean up afterwards',
    () async {
      final delegate = _QueueAgentQueriesRepository();
      final coalescing = CoalescingAgentQueriesRepository(delegate: delegate);
      final firstCompleter = Completer<AppResult<AgentSqlExecutionResult>>();
      final secondCompleter = Completer<AppResult<AgentSqlExecutionResult>>();
      delegate
        ..enqueue((_) => firstCompleter.future)
        ..enqueue((_) => secondCompleter.future);

      final firstFuture = coalescing.executeSql(baseRequest);
      final secondFuture = coalescing.executeSql(baseRequest);

      check(delegate.callCount).equals(1);
      check(coalescing.coalescedCount).equals(1);

      firstCompleter.complete(_successResult(rowCount: 1));
      final firstResult = await firstFuture;
      final secondResult = await secondFuture;
      check(firstResult.getOrNull()?.rowCount).equals(1);
      check(secondResult.getOrNull()?.rowCount).equals(1);

      final thirdFuture = coalescing.executeSql(baseRequest);
      check(delegate.callCount).equals(2);

      secondCompleter.complete(_successResult(rowCount: 2));
      final thirdResult = await thirdFuture;
      check(thirdResult.getOrNull()?.rowCount).equals(2);
    },
  );

  test(
    'should not coalesce requests with different pagination or options',
    () async {
      final delegate = _QueueAgentQueriesRepository();
      final coalescing = CoalescingAgentQueriesRepository(delegate: delegate);
      delegate
        ..enqueue((_) async => _successResult(rowCount: 1))
        ..enqueue((_) async => _successResult(rowCount: 2))
        ..enqueue((_) async => _successResult(rowCount: 3));

      final pageOne = coalescing.executeSql(
        const AgentSqlExecuteRequest(
          agentId: 'agent-1',
          sql: 'SELECT 1',
          pagination: AgentSqlPagePagination(page: 1, pageSize: 10),
        ),
      );
      final pageTwo = coalescing.executeSql(
        const AgentSqlExecuteRequest(
          agentId: 'agent-1',
          sql: 'SELECT 1',
          pagination: AgentSqlPagePagination(page: 2, pageSize: 10),
        ),
      );
      final bounded = coalescing.executeSql(
        const AgentSqlExecuteRequest(
          agentId: 'agent-1',
          sql: 'SELECT 1',
          executeOptions: AgentSqlExecuteOptions(maxRows: 5),
        ),
      );

      check(delegate.callCount).equals(3);
      check((await pageOne).getOrNull()?.rowCount).equals(1);
      check((await pageTwo).getOrNull()?.rowCount).equals(2);
      check((await bounded).getOrNull()?.rowCount).equals(3);
    },
  );

  test(
    'should coalesce simultaneous identical batch requests',
    () async {
      final delegate = _QueueAgentQueriesRepository();
      final coalescing = CoalescingAgentQueriesRepository(delegate: delegate);
      final firstCompleter =
          Completer<AppResult<AgentSqlBatchExecutionResult>>();
      final secondCompleter =
          Completer<AppResult<AgentSqlBatchExecutionResult>>();
      delegate
        ..enqueueBatch((_) => firstCompleter.future)
        ..enqueueBatch((_) => secondCompleter.future);

      const request = AgentSqlExecuteBatchRequest(
        agentId: 'agent-1',
        clientToken: 'token-1',
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(
            sql: 'SELECT :value',
            namedParams: <String, Object?>{'value': 1},
            executionOrder: 0,
          ),
          AgentSqlExecuteBatchCommand(sql: 'SELECT 2', executionOrder: 1),
        ],
        options: AgentSqlExecuteBatchOptions(maxRows: 10),
      );

      final firstFuture = coalescing.executeSqlBatch(request);
      final secondFuture = coalescing.executeSqlBatch(request);

      check(delegate.batchCallCount).equals(1);
      check(coalescing.coalescedCount).equals(1);

      firstCompleter.complete(_successBatchResult(totalCommands: 2));
      final firstResult = await firstFuture;
      final secondResult = await secondFuture;
      check(firstResult.getOrNull()?.totalCommands).equals(2);
      check(secondResult.getOrNull()?.totalCommands).equals(2);

      final thirdFuture = coalescing.executeSqlBatch(request);
      check(delegate.batchCallCount).equals(2);

      secondCompleter.complete(_successBatchResult(totalCommands: 3));
      final thirdResult = await thirdFuture;
      check(thirdResult.getOrNull()?.totalCommands).equals(3);
    },
  );
}

AppResult<AgentSqlExecutionResult> _successResult({required int rowCount}) {
  return Success<AgentSqlExecutionResult, AppFailure>(
    AgentSqlExecutionResult(
      rows: <Map<String, dynamic>>[
        <String, dynamic>{'value': rowCount},
      ],
      rowCount: rowCount,
    ),
  );
}

AppResult<AgentSqlBatchExecutionResult> _successBatchResult({
  required int totalCommands,
}) {
  return Success<AgentSqlBatchExecutionResult, AppFailure>(
    AgentSqlBatchExecutionResult(
      items: <AgentSqlBatchExecutionItem>[
        for (var i = 0; i < totalCommands; i++)
          AgentSqlBatchExecutionItem(
            index: i,
            ok: true,
            rows: const <Map<String, dynamic>>[],
            rowCount: 0,
          ),
      ],
      totalCommands: totalCommands,
      successfulCommands: totalCommands,
      failedCommands: 0,
    ),
  );
}

typedef _AgentQueryHandler =
    Future<AppResult<AgentSqlExecutionResult>> Function(
      AgentSqlExecuteRequest request,
    );

typedef _AgentBatchQueryHandler =
    Future<AppResult<AgentSqlBatchExecutionResult>> Function(
      AgentSqlExecuteBatchRequest request,
    );

final class _QueueAgentQueriesRepository implements AgentQueriesRepository {
  final List<_AgentQueryHandler> _handlers = <_AgentQueryHandler>[];
  final List<_AgentBatchQueryHandler> _batchHandlers =
      <_AgentBatchQueryHandler>[];

  int callCount = 0;
  int batchCallCount = 0;

  void enqueue(_AgentQueryHandler handler) {
    _handlers.add(handler);
  }

  void enqueueBatch(_AgentBatchQueryHandler handler) {
    _batchHandlers.add(handler);
  }

  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request,
  ) {
    callCount++;
    return _handlers.removeAt(0)(request);
  }

  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request,
  ) async {
    batchCallCount++;
    return _batchHandlers.removeAt(0)(request);
  }
}
