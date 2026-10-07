import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/socket/per_agent_concurrency_gate.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:result_dart/result_dart.dart';

/// Limits concurrent REST bridge calls per `agentId` before they reach
/// the concrete REST repository implementation (mirrors hub shared rate-limit
/// pressure).
///
/// Construct with a [PerAgentConcurrencyGate] whose cap matches env; the chain
/// factory omits this decorator when the resolved cap is `0`.
class RestInflightAgentQueriesRepository implements AgentQueriesRepository {
  RestInflightAgentQueriesRepository({
    required this._delegate,
    required this._gate,
  });

  final AgentQueriesRepository _delegate;
  final PerAgentConcurrencyGate _gate;

  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final id = request.trimmedAgentId;
    if (id.isEmpty) {
      return _delegate.executeSql(request, cancelScope: cancelScope);
    }
    final acquireFailure = await _acquireSlot(id, cancelScope);
    if (acquireFailure != null) {
      return Failure(acquireFailure);
    }
    try {
      if (cancelScope?.isCancelled ?? false) {
        return const Failure(OperationCancelledFailure());
      }
      return await _delegate.executeSql(request, cancelScope: cancelScope);
    } finally {
      _gate.release(id);
    }
  }

  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final id = request.trimmedAgentId;
    if (id.isEmpty) {
      return _delegate.executeSqlBatch(request, cancelScope: cancelScope);
    }
    final acquireFailure = await _acquireSlot(id, cancelScope);
    if (acquireFailure != null) {
      return Failure(acquireFailure);
    }
    try {
      if (cancelScope?.isCancelled ?? false) {
        return const Failure(OperationCancelledFailure());
      }
      return await _delegate.executeSqlBatch(request, cancelScope: cancelScope);
    } finally {
      _gate.release(id);
    }
  }

  Future<AppFailure?> _acquireSlot(
    String agentId,
    AgentQueriesCancelScope? cancelScope,
  ) async {
    if (cancelScope?.isCancelled ?? false) {
      return const OperationCancelledFailure();
    }
    final stopwatch = Stopwatch()..start();
    void Function()? unregisterCancellation;
    try {
      await _gate.acquire(
        agentId,
        onQueuedWaiter: (waiter) {
          unregisterCancellation = cancelScope?.registerLocalCancellation(
            () => _gate.cancelQueuedWaiter(agentId, waiter),
          );
        },
      );
      if (cancelScope?.isCancelled ?? false) {
        _gate.release(agentId);
        return const OperationCancelledFailure();
      }
      return null;
    } on GateQueueWaitCancelled {
      return const OperationCancelledFailure();
    } on TimeoutException catch (error) {
      return NetworkFailure(
        message: 'REST agent queue wait exceeded',
        cause: error,
        isTransient: false,
        context: const {
          AgentSqlRpcFailureUiKey.field:
              AgentSqlRpcFailureUiKey.transportTimeout,
          'localQueueWaitExceeded': true,
        },
      );
    } on GateQueueFull catch (error) {
      return NetworkFailure(
        message: 'REST agent waiter queue is full',
        cause: error,
        isTransient: false,
        context: const {
          AgentSqlRpcFailureUiKey.field: AgentSqlRpcFailureUiKey.rateLimited,
          'localQueueFull': true,
        },
      );
    } finally {
      cancelScope?.diagnostics?.addDuration('local_queue', stopwatch.elapsed);
      unregisterCancellation?.call();
    }
  }
}
