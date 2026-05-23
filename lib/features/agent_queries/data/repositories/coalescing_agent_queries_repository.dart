import 'dart:async';

import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_request_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';

/// Deduplicates identical requests that are in-flight simultaneously.
///
/// When multiple callers issue the same SQL query (same agentId, sql, params,
/// options) at nearly the same time, this decorator ensures only ONE request
/// is sent to the hub, and all callers share the same Future result.
///
/// When [AgentQueriesCancelScope] is provided, coalescing is scoped to the
/// same [AgentQueriesCancelScope.traceId] so distinct UI loads never share work.
class CoalescingAgentQueriesRepository implements AgentQueriesRepository {
  CoalescingAgentQueriesRepository({
    required AgentQueriesRepository delegate,
  }) : _delegate = delegate;

  final AgentQueriesRepository _delegate;

  final Map<String, Future<AppResult<AgentSqlExecutionResult>>> _inflight =
      <String, Future<AppResult<AgentSqlExecutionResult>>>{};
  final Map<String, Future<AppResult<AgentSqlBatchExecutionResult>>>
  _batchInflight = <String, Future<AppResult<AgentSqlBatchExecutionResult>>>{};

  int _coalescedCount = 0;

  /// Visible for testing and observability.
  int get coalescedCount => _coalescedCount;

  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final key = _buildSqlKey(request, cancelScope);

    final existing = _inflight[key];
    if (existing != null) {
      _coalescedCount++;
      AppLogger.debug(
        'Coalescing duplicate in-flight request',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          'coalescedCount': _coalescedCount,
          if (cancelScope != null) 'traceId': cancelScope.traceId,
        },
      );
      return existing;
    }

    final future = _delegate.executeSql(request, cancelScope: cancelScope);
    _inflight[key] = future;
    unawaited(_removeInflightWhenComplete(key, future));

    return future;
  }

  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final key = _buildBatchKey(request, cancelScope);

    final existing = _batchInflight[key];
    if (existing != null) {
      _coalescedCount++;
      AppLogger.debug(
        'Coalescing duplicate in-flight batch request',
        context: <String, Object?>{
          'operation': 'executeAgentSqlBatch',
          'agentId': request.trimmedAgentId,
          'coalescedCount': _coalescedCount,
          if (cancelScope != null) 'traceId': cancelScope.traceId,
        },
      );
      return existing;
    }

    final future = _delegate.executeSqlBatch(request, cancelScope: cancelScope);
    _batchInflight[key] = future;
    unawaited(_removeBatchInflightWhenComplete(key, future));

    return future;
  }

  static String _buildSqlKey(
    AgentSqlExecuteRequest request,
    AgentQueriesCancelScope? cancelScope,
  ) {
    final base = AgentQueriesRequestKey.build(request);
    final traceId = cancelScope?.traceId;
    if (traceId == null) {
      return base;
    }
    return '$traceId|$base';
  }

  static String _buildBatchKey(
    AgentSqlExecuteBatchRequest request,
    AgentQueriesCancelScope? cancelScope,
  ) {
    final base = AgentQueriesRequestKey.buildBatch(request);
    final traceId = cancelScope?.traceId;
    if (traceId == null) {
      return base;
    }
    return '$traceId|$base';
  }

  Future<void> _removeInflightWhenComplete(
    String key,
    Future<AppResult<AgentSqlExecutionResult>> future,
  ) async {
    try {
      await future;
    } on Object {
      // The delegate contract returns failures as AppResult. If an unexpected
      // exception escapes, cleanup must still happen and the original future
      // must keep surfacing that exception to its caller.
    } finally {
      final current = _inflight[key];
      if (identical(current, future)) {
        _inflight.remove(key)?.ignore();
      }
    }
  }

  Future<void> _removeBatchInflightWhenComplete(
    String key,
    Future<AppResult<AgentSqlBatchExecutionResult>> future,
  ) async {
    try {
      await future;
    } on Object {
      // Keep cleanup symmetric with single-query coalescing.
    } finally {
      final current = _batchInflight[key];
      if (identical(current, future)) {
        _batchInflight.remove(key)?.ignore();
      }
    }
  }
}
