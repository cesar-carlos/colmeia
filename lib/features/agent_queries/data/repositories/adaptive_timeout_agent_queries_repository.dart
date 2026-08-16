import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/agent_latency_budget.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
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
///
/// **Boundary vs `AgentLatencyOracle`:** this decorator adjusts declared
/// `AgentSqlExecuteRequest.bridgeTimeoutMs` / batch SQL timeouts on the
/// repository chain only. Transport-level pending timers for relay/socket use
/// `AgentLatencyOracle` when the caller omits a per-RPC timeout — the two
/// layers are orthogonal and can both apply when a request carries an explicit
/// bridge timeout while the relay stack still uses oracle-backed dispatch
/// defaults for null RPC timeouts.
class AdaptiveTimeoutAgentQueriesRepository implements AgentQueriesRepository {
  AdaptiveTimeoutAgentQueriesRepository({
    required this._delegate,
    this._safetyMultiplier = 3.0,
    this._minTimeout = const Duration(seconds: 10),
    this._maxTimeout = const Duration(seconds: 180),
  });

  final AgentQueriesRepository _delegate;
  final double _safetyMultiplier;
  final Duration _minTimeout;
  final Duration _maxTimeout;

  final Map<String, List<Duration>> _latencies = <String, List<Duration>>{};
  static const int _maxLatencyHistoryPerAgent = 50;

  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final adaptiveTimeout = _effectiveAdaptiveTimeout(request);

    final adjustedRequest = adaptiveTimeout != null
        ? request.copyWith(bridgeTimeoutMs: adaptiveTimeout.inMilliseconds)
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
    final result = await _delegate.executeSql(
      adjustedRequest,
      cancelScope: cancelScope,
    );
    stopwatch.stop();

    if (result.isSuccess()) {
      _recordLatency(request.trimmedAgentId, stopwatch.elapsed);
    }

    return result;
  }

  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final adaptiveTimeout = _effectiveBatchAdaptiveTimeout(request);
    final adjustedRequest = adaptiveTimeout == null
        ? request
        : request.copyWith(bridgeTimeoutMs: adaptiveTimeout.inMilliseconds);

    final stopwatch = Stopwatch()..start();
    final result = await _delegate.executeSqlBatch(
      adjustedRequest,
      cancelScope: cancelScope,
    );
    stopwatch.stop();

    if (result.isSuccess()) {
      _recordLatency(request.trimmedAgentId, stopwatch.elapsed);
    }
    return result;
  }

  Duration? _effectiveAdaptiveTimeout(AgentSqlExecuteRequest request) {
    final declaredMs = request.bridgeTimeoutMs;
    if (declaredMs == null) {
      return null;
    }
    final declared = Duration(milliseconds: declaredMs);
    final adaptive = _calculateAdaptiveTimeout(request);
    if (adaptive == null) {
      return declared;
    }
    return adaptive > declared ? adaptive : declared;
  }

  Duration? _effectiveBatchAdaptiveTimeout(
    AgentSqlExecuteBatchRequest request,
  ) {
    final declaredMs = request.bridgeTimeoutMs;
    if (declaredMs == null) {
      return null;
    }
    final declared = Duration(milliseconds: declaredMs);
    final adaptive = _calculateBatchAdaptiveTimeout(request);
    if (adaptive == null) {
      return declared;
    }
    return adaptive > declared ? adaptive : declared;
  }

  Duration? _calculateAdaptiveTimeout(AgentSqlExecuteRequest request) {
    if (request.bridgeTimeoutMs == null) {
      return null;
    }

    final agentId = request.trimmedAgentId;
    final history = _latencies[agentId];

    return AgentLatencyBudget.suggestFromAverage(
      history: history ?? const <Duration>[],
      safetyMultiplier: _safetyMultiplier,
      minTimeout: _minTimeout,
      maxTimeout: _maxTimeout,
    );
  }

  Duration? _calculateBatchAdaptiveTimeout(
    AgentSqlExecuteBatchRequest request,
  ) {
    if (request.bridgeTimeoutMs == null) {
      return null;
    }
    final history = _latencies[request.trimmedAgentId];
    return AgentLatencyBudget.suggestFromAverage(
      history: history ?? const <Duration>[],
      safetyMultiplier: _safetyMultiplier,
      minTimeout: _minTimeout,
      maxTimeout: _maxTimeout,
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
