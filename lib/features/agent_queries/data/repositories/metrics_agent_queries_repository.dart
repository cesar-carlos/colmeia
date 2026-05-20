import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';

/// Records latency and success/failure metrics for SQL query execution.
///
/// Tracks:
/// - Request duration (success and failure)
/// - Success vs failure counts
/// - Failure breakdown by type (NetworkFailure, RpcFailure, etc.)
/// - HTTP status codes for NetworkFailure
/// - RPC error codes for RpcFailure
///
/// Metrics are stored in-memory and can be:
/// - Logged periodically for debugging
/// - Exported to observability platforms (Sentry, Firebase Analytics, etc.)
/// - Used to drive adaptive timeout policies
/// - Displayed in developer/debug screens
class MetricsAgentQueriesRepository implements AgentQueriesRepository {
  MetricsAgentQueriesRepository({
    required AgentQueriesRepository delegate,
    Duration metricsLogInterval = const Duration(minutes: 5),
    bool enablePeriodicLogging = true,
  }) : _delegate = delegate,
       _metricsLogInterval = metricsLogInterval {
    if (enablePeriodicLogging) {
      _schedulePeriodicLog();
    }
  }

  CachingAgentQueriesRepository? _sqlCache;

  CachingAgentQueriesRepository? get sqlCache => _sqlCache;

  /// Wired after the outer [CachingAgentQueriesRepository] is constructed so
  /// periodic logs can include SQL cache counters without a DI cycle.
  set sqlCache(CachingAgentQueriesRepository cache) => _sqlCache = cache;

  final AgentQueriesRepository _delegate;
  final Duration _metricsLogInterval;

  final List<_MetricEntry> _metrics = <_MetricEntry>[];
  DateTime? _lastLoggedAt;

  int _successCount = 0;
  int _failureCount = 0;
  Duration _totalSuccessDuration = Duration.zero;
  Duration _totalFailureDuration = Duration.zero;

  /// Visible for testing and observability.
  int get successCount => _successCount;

  /// Visible for testing and observability.
  int get failureCount => _failureCount;

  /// Visible for testing and observability.
  Duration get averageSuccessDuration => _successCount == 0
      ? Duration.zero
      : Duration(
          milliseconds: _totalSuccessDuration.inMilliseconds ~/ _successCount,
        );

  /// Visible for testing and observability.
  Duration get averageFailureDuration => _failureCount == 0
      ? Duration.zero
      : Duration(
          milliseconds: _totalFailureDuration.inMilliseconds ~/ _failureCount,
        );

  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request,
  ) async {
    final stopwatch = Stopwatch()..start();
    final result = await _delegate.executeSql(request);
    stopwatch.stop();

    _recordMetric(
      operation: 'sql.execute',
      agentId: request.trimmedAgentId,
      duration: stopwatch.elapsed,
      success: result.isSuccess(),
      failure: result.isError() ? result.exceptionOrNull() : null,
      useRelay: request.useRelay,
      relayMode: request.useRelay ? request.relayMode.name : null,
      preferDbStreaming: request.executeOptions?.preferDbStreaming,
      apiVersion: request.apiVersion,
      rowCount: result.getOrNull()?.rowCount,
    );

    _maybeLogMetrics();

    return result;
  }

  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request,
  ) async {
    final stopwatch = Stopwatch()..start();
    final result = await _delegate.executeSqlBatch(request);
    stopwatch.stop();

    _recordMetric(
      operation: 'sql.executeBatch',
      agentId: request.trimmedAgentId,
      duration: stopwatch.elapsed,
      success: result.isSuccess(),
      failure: result.isError() ? result.exceptionOrNull() : null,
      useRelay: request.useRelay,
      relayMode: request.useRelay ? 'unary' : null,
      apiVersion: request.apiVersion,
      maxParallelReadOnlyBatchItems:
          request.options?.maxParallelReadOnlyBatchItems,
      totalCommands: result.getOrNull()?.totalCommands,
      successfulCommands: result.getOrNull()?.successfulCommands,
      failedCommands: result.getOrNull()?.failedCommands,
      rowCount: _batchRowCount(result.getOrNull()),
    );
    _maybeLogMetrics();
    return result;
  }

  void _recordMetric({
    required String operation,
    required String agentId,
    required Duration duration,
    required bool success,
    AppFailure? failure,
    bool useRelay = false,
    String? relayMode,
    bool? preferDbStreaming,
    String? apiVersion,
    int? maxParallelReadOnlyBatchItems,
    int? totalCommands,
    int? successfulCommands,
    int? failedCommands,
    int? rowCount,
  }) {
    final entry = _MetricEntry(
      operation: operation,
      agentId: agentId,
      duration: duration,
      success: success,
      failure: failure,
      recordedAt: DateTime.now(),
      useRelay: useRelay,
      relayMode: relayMode,
      preferDbStreaming: preferDbStreaming,
      apiVersion: apiVersion,
      maxParallelReadOnlyBatchItems: maxParallelReadOnlyBatchItems,
      totalCommands: totalCommands,
      successfulCommands: successfulCommands,
      failedCommands: failedCommands,
      rowCount: rowCount,
    );

    _metrics.add(entry);

    if (success) {
      _successCount++;
      _totalSuccessDuration += duration;
    } else {
      _failureCount++;
      _totalFailureDuration += duration;
    }

    if (_metrics.length > 1000) {
      _metrics.removeAt(0);
    }
  }

  void _schedulePeriodicLog() {
    Future<void>.delayed(_metricsLogInterval, () {
      _maybeLogMetrics(force: true);
      _schedulePeriodicLog();
    });
  }

  void _maybeLogMetrics({bool force = false}) {
    final now = DateTime.now();
    if (!force &&
        _lastLoggedAt != null &&
        now.difference(_lastLoggedAt!) < _metricsLogInterval) {
      return;
    }

    if (_successCount + _failureCount == 0) {
      return;
    }

    final failuresByType = <String, int>{};
    final statusCodes = <int, int>{};
    final rpcCodes = <int, int>{};
    final countsByOperation = <String, int>{};
    final countsByRoute = <String, int>{};
    final countsByRelayMode = <String, int>{};
    final durationByRoute = <String, Duration>{};

    for (final entry in _metrics) {
      countsByOperation[entry.operation] =
          (countsByOperation[entry.operation] ?? 0) + 1;
      final route = entry.useRelay ? 'relay' : 'base';
      countsByRoute[route] = (countsByRoute[route] ?? 0) + 1;
      durationByRoute[route] =
          (durationByRoute[route] ?? Duration.zero) + entry.duration;
      final mode = entry.relayMode;
      if (mode != null) {
        countsByRelayMode[mode] = (countsByRelayMode[mode] ?? 0) + 1;
      }
      if (!entry.success && entry.failure != null) {
        final typeName = entry.failure.runtimeType.toString();
        failuresByType[typeName] = (failuresByType[typeName] ?? 0) + 1;

        if (entry.failure is NetworkFailure) {
          final statusCode =
              (entry.failure! as NetworkFailure).context['httpStatusCode']
                  as int?;
          if (statusCode != null) {
            statusCodes[statusCode] = (statusCodes[statusCode] ?? 0) + 1;
          }
        } else if (entry.failure is RpcFailure) {
          final rpcCode = (entry.failure! as RpcFailure).rpcCode;
          if (rpcCode != null) {
            rpcCodes[rpcCode] = (rpcCodes[rpcCode] ?? 0) + 1;
          }
        }
      }
    }

    final p95ByOperation = _p95DurationMsByOperation(_metrics);

    final logContext = <String, Object?>{
      'operation': 'executeAgentSql',
      'successCount': _successCount,
      'failureCount': _failureCount,
      'successRate': _successCount / (_successCount + _failureCount),
      'avgSuccessDurationMs': averageSuccessDuration.inMilliseconds,
      'avgFailureDurationMs': averageFailureDuration.inMilliseconds,
      'countsByOperation': countsByOperation,
      'countsByRoute': countsByRoute,
      'countsByRelayMode': countsByRelayMode,
      'avgDurationMsByRoute': _averageDurationMsByKey(
        totals: durationByRoute,
        counts: countsByRoute,
      ),
      'p95DurationMsByOperation': p95ByOperation,
      'failuresByType': failuresByType,
      'httpStatusCodes': statusCodes,
      'rpcErrorCodes': rpcCodes,
    };

    final cache = _sqlCache;
    if (cache != null) {
      final hits = cache.cacheHits;
      final misses = cache.cacheMisses;
      final denom = hits + misses;
      logContext['sqlCacheHits'] = hits;
      logContext['sqlCacheMisses'] = misses;
      logContext['sqlBatchCacheHits'] = cache.batchCacheHits;
      logContext['sqlBatchCacheMisses'] = cache.batchCacheMisses;
      logContext['sqlCacheSize'] = cache.cacheSize;
      logContext['sqlCacheHitRate'] = denom == 0 ? null : hits / denom;
    }

    AppLogger.info(
      'Agent SQL execution metrics',
      context: logContext,
    );

    _lastLoggedAt = now;
  }

  /// Returns metrics for the last N entries. Useful for debugging.
  List<Map<String, Object?>> getRecentMetrics({int limit = 100}) {
    final recent = _metrics.reversed.take(limit).toList();
    return recent.map((entry) {
      return <String, Object?>{
        'operation': entry.operation,
        'agentId': entry.agentId,
        'durationMs': entry.duration.inMilliseconds,
        'success': entry.success,
        'failureType': entry.failure?.runtimeType.toString(),
        'route': entry.useRelay ? 'relay' : 'base',
        'relayMode': entry.relayMode,
        'preferDbStreaming': entry.preferDbStreaming,
        'apiVersion': entry.apiVersion,
        'maxParallelReadOnlyBatchItems': entry.maxParallelReadOnlyBatchItems,
        'totalCommands': entry.totalCommands,
        'successfulCommands': entry.successfulCommands,
        'failedCommands': entry.failedCommands,
        'rowCount': entry.rowCount,
        'recordedAt': entry.recordedAt.toIso8601String(),
      };
    }).toList();
  }

  /// Clears all metrics. Useful for testing.
  void clear() {
    _metrics.clear();
    _successCount = 0;
    _failureCount = 0;
    _totalSuccessDuration = Duration.zero;
    _totalFailureDuration = Duration.zero;
    _lastLoggedAt = null;
  }

  static int? _batchRowCount(AgentSqlBatchExecutionResult? result) {
    if (result == null) {
      return null;
    }
    return result.items.fold<int>(
      0,
      (sum, item) => sum + item.rowCount,
    );
  }

  static Map<String, int> _averageDurationMsByKey({
    required Map<String, Duration> totals,
    required Map<String, int> counts,
  }) {
    return <String, int>{
      for (final entry in totals.entries)
        entry.key: entry.value.inMilliseconds ~/ (counts[entry.key] ?? 1),
    };
  }

  static Map<String, int> _p95DurationMsByOperation(List<_MetricEntry> entries) {
    final byOp = <String, List<int>>{};
    for (final entry in entries) {
      (byOp[entry.operation] ??= <int>[]).add(entry.duration.inMilliseconds);
    }
    final out = <String, int>{};
    for (final e in byOp.entries) {
      final sorted = List<int>.of(e.value)..sort();
      final idx = (sorted.length * 0.95).ceil().clamp(1, sorted.length) - 1;
      out[e.key] = sorted[idx];
    }
    return out;
  }
}

class _MetricEntry {
  _MetricEntry({
    required this.operation,
    required this.agentId,
    required this.duration,
    required this.success,
    required this.recordedAt,
    this.failure,
    this.useRelay = false,
    this.relayMode,
    this.preferDbStreaming,
    this.apiVersion,
    this.maxParallelReadOnlyBatchItems,
    this.totalCommands,
    this.successfulCommands,
    this.failedCommands,
    this.rowCount,
  });

  final String operation;
  final String agentId;
  final Duration duration;
  final bool success;
  final AppFailure? failure;
  final DateTime recordedAt;
  final bool useRelay;
  final String? relayMode;
  final bool? preferDbStreaming;
  final String? apiVersion;
  final int? maxParallelReadOnlyBatchItems;
  final int? totalCommands;
  final int? successfulCommands;
  final int? failedCommands;
  final int? rowCount;
}
