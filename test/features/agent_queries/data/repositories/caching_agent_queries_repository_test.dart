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
}

AgentSqlExecuteRequest _request(String sql) {
  return AgentSqlExecuteRequest(
    agentId: 'agent-1',
    sql: sql,
    clientToken: 'token-1',
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

final class _SequenceAgentQueriesRepository implements AgentQueriesRepository {
  final List<AppResult<AgentSqlExecutionResult>> _results =
      <AppResult<AgentSqlExecutionResult>>[];

  int callCount = 0;

  void enqueue(AppResult<AgentSqlExecutionResult> result) {
    _results.add(result);
  }

  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request,
  ) async {
    callCount++;
    return _results.removeAt(0);
  }

  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request,
  ) async {
    throw UnimplementedError();
  }
}
