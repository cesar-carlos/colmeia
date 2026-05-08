import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
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
  }) : _delegate = delegate,
       _metricsLogInterval = metricsLogInterval {
    _schedulePeriodicLog();
  }

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
      agentId: request.trimmedAgentId,
      duration: stopwatch.elapsed,
      success: result.isSuccess(),
      failure: result.isError() ? result.exceptionOrNull() : null,
    );

    _maybeLogMetrics();

    return result;
  }

  void _recordMetric({
    required String agentId,
    required Duration duration,
    required bool success,
    AppFailure? failure,
  }) {
    final entry = _MetricEntry(
      agentId: agentId,
      duration: duration,
      success: success,
      failure: failure,
      recordedAt: DateTime.now(),
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

    for (final entry in _metrics) {
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

    AppLogger.info(
      'Agent SQL execution metrics',
      context: <String, Object?>{
        'operation': 'executeAgentSql',
        'successCount': _successCount,
        'failureCount': _failureCount,
        'successRate': _successCount / (_successCount + _failureCount),
        'avgSuccessDurationMs': averageSuccessDuration.inMilliseconds,
        'avgFailureDurationMs': averageFailureDuration.inMilliseconds,
        'failuresByType': failuresByType,
        'httpStatusCodes': statusCodes,
        'rpcErrorCodes': rpcCodes,
      },
    );

    _lastLoggedAt = now;
  }

  /// Returns metrics for the last N entries. Useful for debugging.
  List<Map<String, Object?>> getRecentMetrics({int limit = 100}) {
    final recent = _metrics.reversed.take(limit).toList();
    return recent.map((entry) {
      return <String, Object?>{
        'agentId': entry.agentId,
        'durationMs': entry.duration.inMilliseconds,
        'success': entry.success,
        'failureType': entry.failure?.runtimeType.toString(),
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
}

class _MetricEntry {
  _MetricEntry({
    required this.agentId,
    required this.duration,
    required this.success,
    required this.recordedAt,
    this.failure,
  });

  final String agentId;
  final Duration duration;
  final bool success;
  final AppFailure? failure;
  final DateTime recordedAt;
}
