import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_bridge_pagination.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  const baseRequest = AgentSqlExecuteRequest(
    agentId: 'agent-1',
    sql: 'SELECT 1',
    clientToken: 'token-1',
  );

  test('should cache identical successful requests inside ttl', () async {
    final delegate = _SequenceAgentQueriesRepository();
    final caching = CachingAgentQueriesRepository(delegate: delegate);
    delegate.enqueue(_successResult(rowCount: 1));

    final first = await caching.executeSql(baseRequest);
    final second = await caching.executeSql(baseRequest);

    check(first.getOrNull()?.rowCount).equals(1);
    check(second.getOrNull()?.rowCount).equals(1);
    check(delegate.callCount).equals(1);
    check(caching.cacheHits).equals(1);
    check(caching.cacheMisses).equals(1);
  });

  test('should not cache empty successful responses', () async {
    final delegate = _SequenceAgentQueriesRepository();
    final caching = CachingAgentQueriesRepository(delegate: delegate);
    delegate
      ..enqueue(_successResult(rowCount: 0))
      ..enqueue(_successResult(rowCount: 2));

    final first = await caching.executeSql(baseRequest);
    final second = await caching.executeSql(baseRequest);

    check(first.getOrNull()?.rowCount).equals(0);
    check(second.getOrNull()?.rowCount).equals(2);
    check(delegate.callCount).equals(2);
    check(caching.cacheHits).equals(0);
    check(caching.cacheMisses).equals(2);
    check(caching.cacheSize).equals(1);
  });

  test('should keep paginated requests in separate cache entries', () async {
    final delegate = _SequenceAgentQueriesRepository();
    final caching = CachingAgentQueriesRepository(delegate: delegate);
    delegate
      ..enqueue(_successResult(rowCount: 1))
      ..enqueue(_successResult(rowCount: 2));

    final pageOne = await caching.executeSql(
      const AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        pagination: AgentSqlPagePagination(page: 1, pageSize: 10),
      ),
    );
    final pageTwo = await caching.executeSql(
      const AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        pagination: AgentSqlPagePagination(page: 2, pageSize: 10),
      ),
    );

    check(pageOne.getOrNull()?.rowCount).equals(1);
    check(pageTwo.getOrNull()?.rowCount).equals(2);
    check(delegate.callCount).equals(2);
    check(caching.cacheSize).equals(2);
  });

  test('should keep execute options in separate cache entries', () async {
    final delegate = _SequenceAgentQueriesRepository();
    final caching = CachingAgentQueriesRepository(delegate: delegate);
    delegate
      ..enqueue(_successResult(rowCount: 5))
      ..enqueue(_successResult(rowCount: 10));

    final bounded = await caching.executeSql(
      const AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        executeOptions: AgentSqlExecuteOptions(maxRows: 5),
      ),
    );
    final unbounded = await caching.executeSql(
      const AgentSqlExecuteRequest(agentId: 'agent-1', sql: 'SELECT 1'),
    );

    check(bounded.getOrNull()?.rowCount).equals(5);
    check(unbounded.getOrNull()?.rowCount).equals(10);
    check(delegate.callCount).equals(2);
    check(caching.cacheSize).equals(2);
  });

  test('should start ttl when the successful response is cached', () async {
    final delegate = _SequenceAgentQueriesRepository(
      delay: const Duration(milliseconds: 80),
    );
    final caching = CachingAgentQueriesRepository(
      delegate: delegate,
      cacheTtl: const Duration(milliseconds: 50),
    );
    delegate.enqueue(_successResult(rowCount: 7));

    final first = await caching.executeSql(baseRequest);
    final second = await caching.executeSql(baseRequest);

    check(first.getOrNull()?.rowCount).equals(7);
    check(second.getOrNull()?.rowCount).equals(7);
    check(delegate.callCount).equals(1);
    check(caching.cacheHits).equals(1);
  });

  test(
    'should evict oldest entry when configured max size is exceeded',
    () async {
      final delegate = _SequenceAgentQueriesRepository();
      final caching = CachingAgentQueriesRepository(
        delegate: delegate,
        maxCacheSize: 2,
      );
      delegate
        ..enqueue(_successResult(rowCount: 1))
        ..enqueue(_successResult(rowCount: 2))
        ..enqueue(_successResult(rowCount: 3))
        ..enqueue(_successResult(rowCount: 4));

      await caching.executeSql(_request('SELECT 1'));
      await caching.executeSql(_request('SELECT 2'));
      await caching.executeSql(_request('SELECT 3'));
      final evictedReload = await caching.executeSql(_request('SELECT 1'));

      check(evictedReload.getOrNull()?.rowCount).equals(4);
      check(delegate.callCount).equals(4);
      check(caching.cacheSize).equals(2);
    },
  );

  test('should cache identical successful batch requests inside ttl', () async {
    final delegate = _SequenceAgentQueriesRepository();
    final caching = CachingAgentQueriesRepository(delegate: delegate);
    delegate.enqueueBatch(_successBatchResult());

    const batchRequest = AgentSqlExecuteBatchRequest(
      agentId: 'agent-1',
      commands: <AgentSqlExecuteBatchCommand>[
        AgentSqlExecuteBatchCommand(sql: 'SELECT 1', executionOrder: 0),
      ],
      clientToken: 'token-1',
    );

    final first = await caching.executeSqlBatch(batchRequest);
    final second = await caching.executeSqlBatch(batchRequest);

    check(first.getOrNull()?.successfulCommands).equals(1);
    check(second.getOrNull()?.successfulCommands).equals(1);
    check(delegate.batchCallCount).equals(1);
    check(caching.batchCacheHits).equals(1);
    check(caching.batchCacheMisses).equals(1);
  });

  test('should not cache failed batch responses', () async {
    final delegate = _SequenceAgentQueriesRepository();
    final caching = CachingAgentQueriesRepository(delegate: delegate);
    delegate
      ..enqueueBatch(
        const Failure<AgentSqlBatchExecutionResult, AppFailure>(
          UnknownFailure(message: 'batch failed'),
        ),
      )
      ..enqueueBatch(_successBatchResult());

    const batchRequest = AgentSqlExecuteBatchRequest(
      agentId: 'agent-1',
      commands: <AgentSqlExecuteBatchCommand>[
        AgentSqlExecuteBatchCommand(sql: 'SELECT 1', executionOrder: 0),
      ],
    );

    final first = await caching.executeSqlBatch(batchRequest);
    final second = await caching.executeSqlBatch(batchRequest);

    check(first.isError()).isTrue();
    check(second.isSuccess()).isTrue();
    check(delegate.batchCallCount).equals(2);
    check(caching.batchCacheMisses).equals(2);
    check(caching.batchCacheHits).equals(0);
  });

  test(
    'evicts oldest across sql and batch when combined size exceeds max',
    () async {
      final delegate = _SequenceAgentQueriesRepository();
      final caching = CachingAgentQueriesRepository(
        delegate: delegate,
        maxCacheSize: 2,
      );
      delegate
        ..enqueue(_successResult(rowCount: 1))
        ..enqueueBatch(_successBatchResult())
        ..enqueue(_successResult(rowCount: 2))
        ..enqueue(_successResult(rowCount: 3));

      await caching.executeSql(_request('SELECT a'));
      await caching.executeSqlBatch(
        const AgentSqlExecuteBatchRequest(
          agentId: 'agent-1',
          commands: <AgentSqlExecuteBatchCommand>[
            AgentSqlExecuteBatchCommand(sql: 'BATCH', executionOrder: 0),
          ],
        ),
      );
      check(caching.cacheSize).equals(2);

      await caching.executeSql(_request('SELECT b'));
      check(caching.cacheSize).equals(2);
      check(delegate.callCount).equals(2);
      check(delegate.batchCallCount).equals(1);

      final reloadedA = await caching.executeSql(_request('SELECT a'));
      check(reloadedA.getOrNull()?.rowCount).equals(3);
      check(delegate.callCount).equals(3);
    },
  );
}

AgentSqlExecuteRequest _request(String sql) {
  return AgentSqlExecuteRequest(
    agentId: 'agent-1',
    sql: sql,
    clientToken: 'token-1',
  );
}

AppResult<AgentSqlExecutionResult> _successResult({required int rowCount}) {
  final rows = rowCount <= 0
      ? const <Map<String, dynamic>>[]
      : <Map<String, dynamic>>[
          <String, dynamic>{'value': rowCount},
        ];
  return Success<AgentSqlExecutionResult, AppFailure>(
    AgentSqlExecutionResult(
      rows: rows,
      rowCount: rowCount,
    ),
  );
}

final class _SequenceAgentQueriesRepository implements AgentQueriesRepository {
  _SequenceAgentQueriesRepository({this.delay = Duration.zero});

  final Duration delay;
  final List<AppResult<AgentSqlExecutionResult>> _results =
      <AppResult<AgentSqlExecutionResult>>[];
  final List<AppResult<AgentSqlBatchExecutionResult>> _batchResults =
      <AppResult<AgentSqlBatchExecutionResult>>[];

  int callCount = 0;
  int batchCallCount = 0;

  void enqueue(AppResult<AgentSqlExecutionResult> result) {
    _results.add(result);
  }

  void enqueueBatch(AppResult<AgentSqlBatchExecutionResult> result) {
    _batchResults.add(result);
  }

  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    callCount++;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return _results.removeAt(0);
  }

  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    batchCallCount++;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return _batchResults.removeAt(0);
  }
}

AppResult<AgentSqlBatchExecutionResult> _successBatchResult() {
  return const Success<AgentSqlBatchExecutionResult, AppFailure>(
    AgentSqlBatchExecutionResult(
      items: <AgentSqlBatchExecutionItem>[
        AgentSqlBatchExecutionItem(
          index: 0,
          ok: true,
          rows: <Map<String, dynamic>>[
            <String, dynamic>{'n': 1},
          ],
          rowCount: 1,
        ),
      ],
      totalCommands: 1,
      successfulCommands: 1,
      failedCommands: 0,
    ),
  );
}
