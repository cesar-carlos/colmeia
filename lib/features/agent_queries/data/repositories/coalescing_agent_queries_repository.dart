import 'dart:convert';

import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:crypto/crypto.dart';

/// Deduplicates identical requests that are in-flight simultaneously.
///
/// When multiple callers issue the same SQL query (same agentId, sql, params,
/// options) at nearly the same time, this decorator ensures only ONE request
/// is sent to the hub, and all callers share the same Future result.
///
/// Benefits:
/// - Reduces hub load during parallel widget builds or refresh storms
/// - Improves perceived latency (second caller gets cached Future instantly)
/// - Prevents race conditions where the same data is fetched multiple times
///
/// The deduplication key includes clientToken to prevent cross-user leakage
/// in shared contexts (though in practice each user session has its own
/// repository instance via DI scoping).
class CoalescingAgentQueriesRepository implements AgentQueriesRepository {
  CoalescingAgentQueriesRepository({
    required AgentQueriesRepository delegate,
  }) : _delegate = delegate;

  final AgentQueriesRepository _delegate;

  final Map<String, Future<AppResult<AgentSqlExecutionResult>>> _inflight =
      <String, Future<AppResult<AgentSqlExecutionResult>>>{};

  int _coalescedCount = 0;

  /// Visible for testing and observability.
  /// Returns the number of requests that were coalesced (deduplicated).
  int get coalescedCount => _coalescedCount;

  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request,
  ) async {
    final key = _buildKey(request);

    final existing = _inflight[key];
    if (existing != null) {
      _coalescedCount++;
      AppLogger.debug(
        'Coalescing duplicate in-flight request',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          'coalescedCount': _coalescedCount,
        },
      );
      return existing;
    }

    final future = _delegate.executeSql(request);
    _inflight[key] = future;

    return future;
  }

  String _buildKey(AgentSqlExecuteRequest request) {
    final components = <String>[
      request.agentId,
      request.sql,
      jsonEncode(request.namedParams),
      request.clientToken ?? '',
      request.bridgeTimeoutMs?.toString() ?? '',
      request.executeOptions?.executionMode?.name ?? '',
      request.useRelay.toString(),
    ];
    final combined = components.join('|');
    return md5.convert(utf8.encode(combined)).toString();
  }
}
