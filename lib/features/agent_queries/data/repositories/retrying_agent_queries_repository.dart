import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';

/// Decorator that retries transient failures automatically with exponential
/// backoff, preserving the original request semantics while improving
/// reliability for temporary network issues or server overload.
///
/// Retry policy:
/// - Maximum 3 attempts (1 initial + 2 retries)
/// - Only retries when `failure.isTransient == true` AND no `retryAfter` hint
/// - Exponential backoff: 200ms after 1st failure, 400ms after 2nd failure
/// - `ValidationFailure`, `SessionFailure`, `AuthorizationFailure`,
///   `StorageFailure` have `isTransient=false` and are never retried
class RetryingAgentQueriesRepository implements AgentQueriesRepository {
  RetryingAgentQueriesRepository({
    required AgentQueriesRepository delegate,
    int maxAttempts = 3,
    Duration initialRetryDelay = const Duration(milliseconds: 200),
  })  : _delegate = delegate,
        _maxAttempts = maxAttempts,
        _initialRetryDelay = initialRetryDelay;

  final AgentQueriesRepository _delegate;
  final int _maxAttempts;
  final Duration _initialRetryDelay;

  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request,
  ) async {
    var attempt = 1;
    while (true) {
      final result = await _delegate.executeSql(request);

      if (result.isSuccess()) {
        if (attempt > 1) {
          AppLogger.info(
            'Agent SQL execute succeeded after retry',
            context: <String, Object?>{
              'operation': 'executeAgentSql',
              'agentId': request.trimmedAgentId,
              'attempt': attempt,
            },
          );
        }
        return result;
      }

      final failure = result.exceptionOrNull()!;

      if (attempt >= _maxAttempts || !_shouldRetry(failure)) {
        if (attempt > 1) {
          AppLogger.warning(
            'Agent SQL execute failed after all retries',
            context: <String, Object?>{
              'operation': 'executeAgentSql',
              'agentId': request.trimmedAgentId,
              'attempt': attempt,
              'failureType': failure.runtimeType.toString(),
            },
          );
        }
        return result;
      }

      final delay = _calculateBackoffDelay(attempt);
      AppLogger.debug(
        'Agent SQL execute failed, will retry',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          'attempt': attempt,
          'failureType': failure.runtimeType.toString(),
          'retryDelayMs': delay.inMilliseconds,
        },
      );

      await Future<void>.delayed(delay);
      attempt++;
    }
  }

  Duration _calculateBackoffDelay(int failedAttempt) {
    final multiplier = failedAttempt;
    return _initialRetryDelay * multiplier;
  }

  bool _shouldRetry(AppFailure failure) =>
      failure.isTransient && _retryAfterOf(failure) == null;

  Duration? _retryAfterOf(AppFailure failure) => switch (failure) {
        final NetworkFailure f => f.retryAfter,
        final RpcFailure f => f.retryAfter,
        _ => null,
      };
}
