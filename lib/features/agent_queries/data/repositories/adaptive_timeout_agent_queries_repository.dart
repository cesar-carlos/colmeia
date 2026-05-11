import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';

/// Applies adaptive timeouts based on historical query latency patterns.
///
/// Instead of using a fixed timeout for all queries, this decorator adjusts
/// timeouts dynamically based on:
/// - Recent successful query latencies (moving average)
/// - Safety multiplier (default 3x) to allow for variance
/// - Floor and ceiling bounds to prevent extreme values
///
/// Benefits:
/// - Fast-fail on queries that are genuinely stuck (> 3x normal latency)
/// - Allows slow but valid queries to complete (respects their typical latency)
/// - Reduces unnecessary hub load from overly long timeouts
///
/// Only queries that already specify a bridgeTimeoutMs are eligible for
/// adaptive adjustment. Queries without explicit timeout pass through
/// unchanged and rely on the datasource/hub defaults.
class AdaptiveTimeoutAgentQueriesRepository implements AgentQueriesRepository {
  AdaptiveTimeoutAgentQueriesRepository({
    required AgentQueriesRepository delegate,
    double safetyMultiplier = 3.0,
    Duration minTimeout = const Duration(seconds: 10),
    Duration maxTimeout = const Duration(seconds: 180),
  }) : _delegate = delegate,
       _safetyMultiplier = safetyMultiplier,
       _minTimeout = minTimeout,
       _maxTimeout = maxTimeout;

  final AgentQueriesRepository _delegate;
  final double _safetyMultiplier;
  final Duration _minTimeout;
  final Duration _maxTimeout;

  final Map<String, List<Duration>> _latencies = <String, List<Duration>>{};
  static const int _maxLatencyHistoryPerAgent = 50;

  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request,
  ) async {
    final adaptiveTimeout = _calculateAdaptiveTimeout(request);

    final adjustedRequest = adaptiveTimeout != null
        ? AgentSqlExecuteRequest(
            agentId: request.agentId,
            sql: request.sql,
            namedParams: request.namedParams,
            requestingUserId: request.requestingUserId,
            clientToken: request.clientToken,
            bridgeTimeoutMs: adaptiveTimeout.inMilliseconds,
            executeOptions: request.executeOptions,
            useRelay: request.useRelay,
            pagination: request.pagination,
            apiVersion: request.apiVersion,
            outboundCompression: request.outboundCompression,
            payloadFrameCompression: request.payloadFrameCompression,
            hubPresenceOnlineAgentIdsSnapshot:
                request.hubPresenceOnlineAgentIdsSnapshot,
            hubConnectedFromApprovedCatalogRow:
                request.hubConnectedFromApprovedCatalogRow,
          )
        : request;

    if (adaptiveTimeout != null &&
        adaptiveTimeout.inMilliseconds != request.bridgeTimeoutMs) {
      AppLogger.debug(
        'Applied adaptive timeout',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          'originalTimeoutMs': request.bridgeTimeoutMs,
          'adaptiveTimeoutMs': adaptiveTimeout.inMilliseconds,
        },
      );
    }

    final stopwatch = Stopwatch()..start();
    final result = await _delegate.executeSql(adjustedRequest);
    stopwatch.stop();

    if (result.isSuccess()) {
      _recordLatency(request.trimmedAgentId, stopwatch.elapsed);
    }

    return result;
  }

  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request,
  ) async {
    final adaptiveTimeout = _calculateBatchAdaptiveTimeout(request);
    final adjustedRequest = adaptiveTimeout == null
        ? request
        : AgentSqlExecuteBatchRequest(
            agentId: request.agentId,
            commands: request.commands,
            clientToken: request.clientToken,
            requestingUserId: request.requestingUserId,
            hubPresenceOnlineAgentIdsSnapshot:
                request.hubPresenceOnlineAgentIdsSnapshot,
            hubConnectedFromApprovedCatalogRow:
                request.hubConnectedFromApprovedCatalogRow,
            bridgeTimeoutMs: adaptiveTimeout.inMilliseconds,
            options: request.options,
            useRelay: request.useRelay,
            apiVersion: request.apiVersion,
            payloadFrameCompression: request.payloadFrameCompression,
          );

    final stopwatch = Stopwatch()..start();
    final result = await _delegate.executeSqlBatch(adjustedRequest);
    stopwatch.stop();

    if (result.isSuccess()) {
      _recordLatency(request.trimmedAgentId, stopwatch.elapsed);
    }
    return result;
  }

  Duration? _calculateAdaptiveTimeout(AgentSqlExecuteRequest request) {
    if (request.bridgeTimeoutMs == null) {
      return null;
    }

    final agentId = request.trimmedAgentId;
    final history = _latencies[agentId];

    if (history == null || history.isEmpty) {
      return null;
    }

    final sum = history.fold<int>(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );
    final avgMs = sum / history.length;
    final adaptiveMs = (avgMs * _safetyMultiplier).toInt();

    final bounded = Duration(milliseconds: adaptiveMs).clamp(
      _minTimeout,
      _maxTimeout,
    );

    return bounded;
  }

  Duration? _calculateBatchAdaptiveTimeout(
    AgentSqlExecuteBatchRequest request,
  ) {
    if (request.bridgeTimeoutMs == null) {
      return null;
    }
    final history = _latencies[request.trimmedAgentId];
    if (history == null || history.isEmpty) {
      return null;
    }
    final sum = history.fold<int>(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );
    final avgMs = sum / history.length;
    return Duration(milliseconds: (avgMs * _safetyMultiplier).toInt()).clamp(
      _minTimeout,
      _maxTimeout,
    );
  }

  void _recordLatency(String agentId, Duration latency) {
    final history = _latencies.putIfAbsent(agentId, () => <Duration>[])
      ..add(latency);

    if (history.length > _maxLatencyHistoryPerAgent) {
      history.removeAt(0);
    }
  }

  /// Returns the average latency for the given agent. Useful for debugging.
  Duration? getAverageLatency(String agentId) {
    final history = _latencies[agentId];
    if (history == null || history.isEmpty) {
      return null;
    }

    final sum = history.fold<int>(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );
    return Duration(milliseconds: sum ~/ history.length);
  }

  /// Clears all latency history. Useful for testing.
  void clear() {
    _latencies.clear();
  }
}

extension on Duration {
  Duration clamp(Duration min, Duration max) {
    if (this < min) {
      return min;
    }
    if (this > max) {
      return max;
    }
    return this;
  }
}
