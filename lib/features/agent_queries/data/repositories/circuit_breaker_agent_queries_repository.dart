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
/// States:
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

  _CircuitState _state = _CircuitState.closed;
  int _consecutiveFailures = 0;
  DateTime? _openedAt;

  /// Visible for testing and observability.
  String get state => _state.name;

  /// Visible for testing and observability.
  int get consecutiveFailures => _consecutiveFailures;

  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    if (_state == _CircuitState.open) {
      final now = DateTime.now();
      if (_openedAt != null && now.difference(_openedAt!) >= _cooldownPeriod) {
        _state = _CircuitState.halfOpen;
        AppLogger.info(
          'Circuit breaker entering half-open state for probe',
          context: <String, Object?>{
            'operation': 'executeAgentSql',
            'agentId': request.trimmedAgentId,
            'cooldownElapsed': _cooldownPeriod.inSeconds,
          },
        );
      } else {
        return Failure<AgentSqlExecutionResult, AppFailure>(
          NetworkFailure(
            message: 'Circuit breaker open: hub overload protection active',
            userMessage:
                'O servidor esta temporariamente indisponivel. '
                'Tente novamente em alguns instantes.',
            context: <String, Object?>{
              'circuitBreakerState': 'open',
              'consecutiveFailures': _consecutiveFailures,
              'cooldownRemainingMs': _openedAt == null
                  ? 0
                  : (_cooldownPeriod.inMilliseconds -
                        now.difference(_openedAt!).inMilliseconds),
            },
          ),
        );
      }
    }

    final result = await _delegate.executeSql(
      request,
      cancelScope: cancelScope,
    );

    if (result.isSuccess()) {
      _onSuccess();
      return result;
    }

    final failure = result.exceptionOrNull()!;
    if (_isCircuitBreakingFailure(failure)) {
      _onFailure(failure);
    }

    return result;
  }

  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final openFailure = _openCircuitFailure<AgentSqlBatchExecutionResult>();
    if (openFailure != null) {
      return openFailure;
    }

    final result = await _delegate.executeSqlBatch(
      request,
      cancelScope: cancelScope,
    );
    if (result.isSuccess()) {
      _onSuccess();
      return result;
    }

    final failure = result.exceptionOrNull()!;
    if (_isCircuitBreakingFailure(failure)) {
      _onFailure(failure);
    }
    return result;
  }

  AppResult<T>? _openCircuitFailure<T extends Object>() {
    if (_state != _CircuitState.open) {
      return null;
    }
    final now = DateTime.now();
    if (_openedAt != null && now.difference(_openedAt!) >= _cooldownPeriod) {
      _state = _CircuitState.halfOpen;
      return null;
    }
    return Failure<T, AppFailure>(
      NetworkFailure(
        message: 'Circuit breaker open: hub overload protection active',
        userMessage:
            'O servidor esta temporariamente indisponivel. '
            'Tente novamente em alguns instantes.',
        context: <String, Object?>{
          'circuitBreakerState': 'open',
          'consecutiveFailures': _consecutiveFailures,
          'cooldownRemainingMs': _openedAt == null
              ? 0
              : (_cooldownPeriod.inMilliseconds -
                    now.difference(_openedAt!).inMilliseconds),
        },
      ),
    );
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

  void _onSuccess() {
    if (_state == _CircuitState.halfOpen) {
      _state = _CircuitState.closed;
      _consecutiveFailures = 0;
      AppLogger.info(
        'Circuit breaker closed: hub recovered',
        context: <String, Object?>{'operation': 'executeAgentSql'},
      );
    } else if (_consecutiveFailures > 0) {
      _consecutiveFailures = 0;
    }
  }

  void _onFailure(AppFailure failure) {
    _consecutiveFailures++;

    if (_state == _CircuitState.halfOpen) {
      _state = _CircuitState.open;
      _openedAt = DateTime.now();
      AppLogger.warning(
        'Circuit breaker re-opened: probe request failed',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'consecutiveFailures': _consecutiveFailures,
          'failureType': failure.runtimeType.toString(),
        },
      );
      return;
    }

    if (_state == _CircuitState.closed &&
        _consecutiveFailures >= _failureThreshold) {
      _state = _CircuitState.open;
      _openedAt = DateTime.now();
      AppLogger.warning(
        'Circuit breaker opened: hub overload detected',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'consecutiveFailures': _consecutiveFailures,
          'failureThreshold': _failureThreshold,
          'cooldownPeriod': _cooldownPeriod.inSeconds,
        },
      );
    }
  }
}

enum _CircuitState {
  closed,
  open,
  halfOpen,
}
