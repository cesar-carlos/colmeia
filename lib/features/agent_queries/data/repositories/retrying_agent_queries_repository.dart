import 'dart:math' as math;

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_failure_codes.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_retry_backoff.dart';
import 'package:colmeia/features/agent_queries/data/agent_query_failure_ui_key_resolver.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_rpc_user_message_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:uuid/uuid.dart';

/// Decorator that retries transient failures automatically with exponential
/// backoff, preserving the original request semantics while improving
/// reliability for temporary network issues or server overload.
///
/// Retry policy:
/// - Maximum 3 attempts (1 initial + 2 retries)
/// - Only retries when `failure.isTransient == true` AND no `retryAfter` hint
/// - Exponential backoff ceilings with full jitter:
///   0..200ms after 1st failure, 0..400ms after 2nd failure
/// - `ValidationFailure`, `SessionFailure`, `AuthorizationFailure`,
///   `StorageFailure` have `isTransient=false` and are never retried
class RetryingAgentQueriesRepository implements AgentQueriesRepository {
  RetryingAgentQueriesRepository({
    required AgentQueriesRepository delegate,
    int maxAttempts = 3,
    Duration initialRetryDelay = const Duration(milliseconds: 200),
    Duration defaultTotalRetryBudget = const Duration(minutes: 9),
    math.Random? random,
    Uuid? uuid,
  }) : _delegate = delegate,
       _maxAttempts = maxAttempts,
       _initialRetryDelay = initialRetryDelay,
       _defaultTotalRetryBudget = defaultTotalRetryBudget,
       _random = random ?? math.Random(),
       _uuid = uuid ?? const Uuid();

  final AgentQueriesRepository _delegate;
  final int _maxAttempts;
  final Duration _initialRetryDelay;
  final Duration _defaultTotalRetryBudget;
  final math.Random _random;
  final Uuid _uuid;
  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final logicalRequest = _stableExecuteRequest(request);
    final budget = Stopwatch()..start();
    var attempt = 1;
    AppResult<AgentSqlExecutionResult>? lastFailure;
    while (true) {
      final result = await _delegate.executeSql(
        logicalRequest,
        cancelScope: cancelScope,
      );

      if (result.isSuccess()) {
        if (attempt > 1) {
          AppLogger.info(
            'Agent SQL execute succeeded after retry',
            context: <String, Object?>{
              'operation': 'executeAgentSql',
              'agentId': logicalRequest.trimmedAgentId,
              'attempt': attempt,
            },
          );
        }
        return result;
      }

      lastFailure = result;
      final failure = result.exceptionOrNull()!;

      if (attempt >= _maxAttempts ||
          !_shouldRetry(failure, cancelScope) ||
          !_hasRetryBudgetRemaining(
            budget,
            bridgeTimeoutMs: logicalRequest.bridgeTimeoutMs,
          )) {
        if (attempt > 1) {
          AppLogger.warning(
            'Agent SQL execute failed after all retries',
            context: <String, Object?>{
              'operation': 'executeAgentSql',
              'agentId': logicalRequest.trimmedAgentId,
              'attempt': attempt,
              'failureType': failure.runtimeType.toString(),
            },
          );
        }
        return result;
      }

      final delay = _calculateBackoffDelay(attempt);
      if (!_canAffordDelay(
        budget,
        delay,
        bridgeTimeoutMs: logicalRequest.bridgeTimeoutMs,
      )) {
        return result;
      }
      AppLogger.debug(
        'Agent SQL execute failed, will retry',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': logicalRequest.trimmedAgentId,
          'attempt': attempt,
          'failureType': failure.runtimeType.toString(),
          'retryDelayMs': delay.inMilliseconds,
        },
      );

      await Future<void>.delayed(delay);
      if (cancelScope?.isCancelled == true) {
        return lastFailure;
      }
      attempt++;
    }
  }
  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final logicalRequest = _stableBatchRequest(request);
    final budget = Stopwatch()..start();
    var attempt = 1;
    AppResult<AgentSqlBatchExecutionResult>? lastFailure;
    while (true) {
      final result = await _delegate.executeSqlBatch(
        logicalRequest,
        cancelScope: cancelScope,
      );

      if (result.isSuccess()) {
        return result;
      }

      lastFailure = result;
      final failure = result.exceptionOrNull()!;
      if (attempt >= _maxAttempts ||
          !_shouldRetry(failure, cancelScope) ||
          !_hasRetryBudgetRemaining(
            budget,
            bridgeTimeoutMs: logicalRequest.bridgeTimeoutMs,
          )) {
        return result;
      }

      final delay = _calculateBackoffDelay(attempt);
      if (!_canAffordDelay(
        budget,
        delay,
        bridgeTimeoutMs: logicalRequest.bridgeTimeoutMs,
      )) {
        return result;
      }
      AppLogger.debug(
        'Agent SQL batch execute failed, will retry',
        context: <String, Object?>{
          'operation': 'executeAgentSqlBatch',
          'agentId': logicalRequest.trimmedAgentId,
          'attempt': attempt,
          'failureType': failure.runtimeType.toString(),
          'retryDelayMs': delay.inMilliseconds,
        },
      );

      await Future<void>.delayed(delay);
      if (cancelScope?.isCancelled == true) {
        return lastFailure;
      }
      attempt++;
    }
  }

  AgentSqlExecuteRequest _stableExecuteRequest(AgentSqlExecuteRequest request) {
    final existing = request.transportRpcId?.trim();
    if (existing != null && existing.isNotEmpty) {
      return request;
    }
    return request.copyWith(transportRpcId: _uuid.v4());
  }

  AgentSqlExecuteBatchRequest _stableBatchRequest(
    AgentSqlExecuteBatchRequest request,
  ) {
    final existing = request.transportRpcId?.trim();
    if (existing != null && existing.isNotEmpty) {
      return request;
    }
    return request.copyWith(transportRpcId: _uuid.v4());
  }

  Duration _totalRetryBudget({required int? bridgeTimeoutMs}) {
    if (bridgeTimeoutMs != null) {
      return Duration(milliseconds: bridgeTimeoutMs * _maxAttempts);
    }
    return _defaultTotalRetryBudget;
  }

  bool _hasRetryBudgetRemaining(
    Stopwatch budget, {
    required int? bridgeTimeoutMs,
  }) {
    return budget.elapsed < _totalRetryBudget(bridgeTimeoutMs: bridgeTimeoutMs);
  }

  bool _canAffordDelay(
    Stopwatch budget,
    Duration delay, {
    required int? bridgeTimeoutMs,
  }) {
    final total = _totalRetryBudget(bridgeTimeoutMs: bridgeTimeoutMs);
    return budget.elapsed + delay < total;
  }
  Duration _calculateBackoffDelay(int failedAttempt) {
    final ceiling = AgentQueriesRetryBackoff.ceiling(
      initialDelay: _initialRetryDelay,
      failedAttempt: failedAttempt,
    );
    return AgentQueriesRetryBackoff.fullJitter(
      ceiling: ceiling,
      random: _random,
    );
  }

  bool _shouldRetry(
    AppFailure failure, [
    AgentQueriesCancelScope? cancelScope,
  ]) {
    if (cancelScope?.isCancelled == true) {
      return false;
    }
    if (failure is OperationCancelledFailure) {
      return false;
    }
    if (_isRateLimitedFailure(failure)) {
      return false;
    }
    if (_isReplayDetectedFailure(failure)) {
      return false;
    }
    if (_retryAfterOf(failure) != null) {
      return false;
    }
    if (failure.isTransient) {
      return true;
    }
    return _isCooperativeHubWarmupFailure(failure);
  }

  bool _isReplayDetectedFailure(AppFailure failure) {
    if (failure is RpcFailure) {
      if (failure.rpcCode == -32014) {
        return true;
      }
      if (failure.reason?.toLowerCase() == 'replay_detected') {
        return true;
      }
    }
    return false;
  }

  bool _isRateLimitedFailure(AppFailure failure) {
    if (resolveAgentQueryFailureUiKey(failure) ==
        AgentSqlRpcFailureUiKey.rateLimited) {
      return true;
    }
    if (failure is RpcFailure) {
      if (failure.rpcCode == -32013) {
        return true;
      }
      if (isAgentSqlRpcRateLimitedReason(failure.reason)) {
        return true;
      }
    }
    if (failure is NetworkFailure) {
      if (failure.context['httpStatusCode'] == 429) {
        return true;
      }
      final transportCode =
          failure.context[AgentQueriesFailureContext.transportCodeField];
      if (transportCode is String && isSocketRateLimitedCode(transportCode)) {
        return true;
      }
    }
    return false;
  }

  /// Hub sometimes returns `SERVICE_UNAVAILABLE` / "protocol negotiation is
  /// not ready" while the agent link warms up. Those payloads may omit
  /// `retryable: true`; still treat as a short-lived bridge condition.
  ///
  bool _isCooperativeHubWarmupFailure(AppFailure failure) {
    if (failure is RpcFailure) {
      final msg = failure.message.toLowerCase();
      final tech = (failure.technicalMessage ?? '').toLowerCase();
      if (msg.contains('protocol negotiation') ||
          tech.contains('protocol negotiation')) {
        return true;
      }
      if (msg.contains('negotiation is not ready') ||
          tech.contains('negotiation is not ready')) {
        return true;
      }
      final code = failure.context['code']?.toString().toUpperCase();
      if (code == 'SERVICE_UNAVAILABLE') {
        return true;
      }
    }
    if (failure is NetworkFailure) {
      final http = failure.context['httpStatusCode'];
      if (http == 503) {
        final body =
            failure.context[DioHttpFailureContext.responseBodyField]
                ?.toString() ??
            '';
        final lower = body.toLowerCase();
        if (lower.contains('protocol negotiation') ||
            lower.contains('service_unavailable')) {
          return true;
        }
      }
    }
    return false;
  }

  Duration? _retryAfterOf(AppFailure failure) => switch (failure) {
    final NetworkFailure f => f.retryAfter,
    final RpcFailure f => f.retryAfter,
    _ => null,
  };
}
