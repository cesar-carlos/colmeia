import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
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
  })  : _delegate = delegate,
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
    AgentSqlExecuteRequest request,
  ) async {
    if (_state == _CircuitState.open) {
      final now = DateTime.now();
      if (_openedAt != null &&
          now.difference(_openedAt!) >= _cooldownPeriod) {
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

    final result = await _delegate.executeSql(request);

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

  bool _isCircuitBreakingFailure(AppFailure failure) {
    if (failure is NetworkFailure) {
      final statusCode = failure.context['httpStatusCode'] as int?;
      return statusCode == 503 ||
          statusCode == 502 ||
          statusCode == 504 ||
          failure.message.contains('timeout') ||
          failure.message.contains('connection');
    }
    return false;
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
