import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_failure_codes.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:result_dart/result_dart.dart';

/// Circuit breaker that prevents cascading failures when the hub is
/// overloaded or repeatedly returning 503/timeout errors.
///
/// State is partitioned per `agentId`: failures on one agent never trip the
/// breaker for another. This avoids one misbehaving agent from blocking
/// SQL traffic to the rest.
///
/// States (per agent):
/// - **Closed** (normal): requests flow through to delegate
/// - **Open** (protecting): fail-fast without calling hub
/// - **Half-Open** (testing): allows one probe request to test recovery
///
/// Transitions:
/// - Closed → Open: after [_failureThreshold] consecutive failures
/// - Open → Half-Open: after [_cooldownPeriod] has elapsed
/// - Half-Open → Closed: if probe request succeeds
/// - Half-Open → Open: if probe request fails (resets cooldown timer)
///
/// Only circuit-breaking failures (503, timeouts, connection errors) count
/// toward the threshold. Validation, auth, and session failures do not trip
/// the breaker since they indicate client-side issues, not hub overload.
class CircuitBreakerAgentQueriesRepository implements AgentQueriesRepository {
  CircuitBreakerAgentQueriesRepository({
    required AgentQueriesRepository delegate,
    int failureThreshold = 5,
    Duration cooldownPeriod = const Duration(seconds: 30),
  }) : _delegate = delegate,
       _failureThreshold = failureThreshold,
       _cooldownPeriod = cooldownPeriod;

  final AgentQueriesRepository _delegate;
  final int _failureThreshold;
  final Duration _cooldownPeriod;

  final Map<String, _AgentCircuit> _circuits = <String, _AgentCircuit>{};

  _AgentCircuit _circuitFor(String agentId) {
    return _circuits.putIfAbsent(agentId, _AgentCircuit.new);
  }

  _AgentCircuit? _circuitOrNull(String agentId) => _circuits[agentId];

  /// Visible for testing and observability — returns the breaker state name
  /// for [agentId] (`closed`, `open`, or `halfOpen`).
  String stateFor(String agentId) =>
      _circuitOrNull(agentId)?.state.name ?? _CircuitState.closed.name;

  /// Visible for testing and observability — returns the consecutive failure
  /// count for [agentId].
  int consecutiveFailuresFor(String agentId) =>
      _circuitOrNull(agentId)?.consecutiveFailures ?? 0;

  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final agentId = request.trimmedAgentId;
    final circuit = _circuitFor(agentId);

    final openFailure = _openCircuitFailure<AgentSqlExecutionResult>(
      circuit: circuit,
      agentId: agentId,
    );
    if (openFailure != null) {
      return openFailure;
    }

    final halfOpenProbeFailure =
        _halfOpenProbeInFlightFailure<AgentSqlExecutionResult>(
          circuit: circuit,
          agentId: agentId,
        );
    if (halfOpenProbeFailure != null) {
      return halfOpenProbeFailure;
    }

    final armedProbe = _armHalfOpenProbe(circuit);
    try {
      final result = await _delegate.executeSql(
        request,
        cancelScope: cancelScope,
      );

      if (result.isSuccess()) {
        _onSuccess(circuit, agentId);
        return result;
      }

      final failure = result.exceptionOrNull()!;
      if (_isCircuitBreakingFailure(failure)) {
        _onFailure(circuit, agentId, failure);
      }

      return result;
    } finally {
      _releaseHalfOpenProbe(circuit, armedProbe: armedProbe);
    }
  }

  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final agentId = request.trimmedAgentId;
    final circuit = _circuitFor(agentId);

    final openFailure = _openCircuitFailure<AgentSqlBatchExecutionResult>(
      circuit: circuit,
      agentId: agentId,
    );
    if (openFailure != null) {
      return openFailure;
    }

    final halfOpenProbeFailure =
        _halfOpenProbeInFlightFailure<AgentSqlBatchExecutionResult>(
          circuit: circuit,
          agentId: agentId,
        );
    if (halfOpenProbeFailure != null) {
      return halfOpenProbeFailure;
    }

    final armedProbe = _armHalfOpenProbe(circuit);
    try {
      final result = await _delegate.executeSqlBatch(
        request,
        cancelScope: cancelScope,
      );
      if (result.isSuccess()) {
        _onSuccess(circuit, agentId);
        return result;
      }

      final failure = result.exceptionOrNull()!;
      if (_isCircuitBreakingFailure(failure)) {
        _onFailure(circuit, agentId, failure);
      }
      return result;
    } finally {
      _releaseHalfOpenProbe(circuit, armedProbe: armedProbe);
    }
  }

  AppResult<T>? _openCircuitFailure<T extends Object>({
    required _AgentCircuit circuit,
    required String agentId,
  }) {
    if (circuit.state != _CircuitState.open) {
      return null;
    }
    final now = DateTime.now();
    if (circuit.openedAt != null &&
        now.difference(circuit.openedAt!) >= _cooldownPeriod) {
      circuit.state = _CircuitState.halfOpen;
      AppLogger.info(
        'Circuit breaker entering half-open state for probe',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': agentId,
          'cooldownElapsed': _cooldownPeriod.inSeconds,
        },
      );
      return null;
    }
    return Failure<T, AppFailure>(
      NetworkFailure(
        message: 'Circuit breaker open: hub overload protection active',
        userMessage:
            'O servidor esta temporariamente indisponivel. '
            'Tente novamente em alguns instantes.',
        context: <String, Object?>{
          'agentId': agentId,
          'circuitBreakerState': 'open',
          'consecutiveFailures': circuit.consecutiveFailures,
          'cooldownRemainingMs': circuit.openedAt == null
              ? 0
              : (_cooldownPeriod.inMilliseconds -
                    now.difference(circuit.openedAt!).inMilliseconds),
        },
      ),
    );
  }

  AppResult<T>? _halfOpenProbeInFlightFailure<T extends Object>({
    required _AgentCircuit circuit,
    required String agentId,
  }) {
    if (circuit.state != _CircuitState.halfOpen || !circuit.probeInFlight) {
      return null;
    }
    return Failure<T, AppFailure>(
      NetworkFailure(
        message: 'Circuit breaker half-open: probe already in flight',
        userMessage:
            'O servidor esta se recuperando. Tente novamente em instantes.',
        context: <String, Object?>{
          'agentId': agentId,
          'circuitBreakerState': 'halfOpen',
          'probeInFlight': true,
        },
      ),
    );
  }

  bool _armHalfOpenProbe(_AgentCircuit circuit) {
    if (circuit.state != _CircuitState.halfOpen) {
      return false;
    }
    circuit.probeInFlight = true;
    return true;
  }

  void _releaseHalfOpenProbe(
    _AgentCircuit circuit, {
    required bool armedProbe,
  }) {
    if (armedProbe) {
      circuit.probeInFlight = false;
    }
  }

  bool _isCircuitBreakingFailure(AppFailure failure) {
    if (failure is NetworkFailure) {
      final statusCode = failure.context['httpStatusCode'] as int?;
      final transportCode = failure
          .context[AgentQueriesFailureContext.transportCodeField]
          ?.toString()
          .trim()
          .toLowerCase();
      final message = failure.message.toLowerCase();
      return statusCode == 503 ||
          statusCode == 502 ||
          statusCode == 504 ||
          _isCircuitBreakingTransportCode(transportCode) ||
          message.contains('timeout') ||
          message.contains('timed out') ||
          message.contains('connection') ||
          message.contains('disconnected');
    }
    return false;
  }

  bool _isCircuitBreakingTransportCode(String? code) {
    return code == 'timeout' ||
        code == 'disconnected' ||
        code == 'conversation_lost' ||
        code == 'conversation_start_failed' ||
        code == 'service_unavailable' ||
        code == 'unavailable' ||
        code == 'overload' ||
        code == 'overloaded';
  }

  void _onSuccess(_AgentCircuit circuit, String agentId) {
    if (circuit.state == _CircuitState.halfOpen) {
      circuit
        ..state = _CircuitState.closed
        ..consecutiveFailures = 0;
      AppLogger.info(
        'Circuit breaker closed: hub recovered',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': agentId,
        },
      );
    } else if (circuit.consecutiveFailures > 0) {
      circuit.consecutiveFailures = 0;
    }
  }

  void _onFailure(
    _AgentCircuit circuit,
    String agentId,
    AppFailure failure,
  ) {
    circuit.consecutiveFailures++;

    if (circuit.state == _CircuitState.halfOpen) {
      circuit
        ..state = _CircuitState.open
        ..openedAt = DateTime.now();
      AppLogger.warning(
        'Circuit breaker re-opened: probe request failed',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': agentId,
          'consecutiveFailures': circuit.consecutiveFailures,
          'failureType': failure.runtimeType.toString(),
        },
      );
      return;
    }

    if (circuit.state == _CircuitState.closed &&
        circuit.consecutiveFailures >= _failureThreshold) {
      circuit
        ..state = _CircuitState.open
        ..openedAt = DateTime.now();
      AppLogger.warning(
        'Circuit breaker opened: hub overload detected',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': agentId,
          'consecutiveFailures': circuit.consecutiveFailures,
          'failureThreshold': _failureThreshold,
          'cooldownPeriod': _cooldownPeriod.inSeconds,
        },
      );
    }
  }
}

class _AgentCircuit {
  _CircuitState state = _CircuitState.closed;
  int consecutiveFailures = 0;
  DateTime? openedAt;
  bool probeInFlight = false;
}

enum _CircuitState {
  closed,
  open,
  halfOpen,
}
