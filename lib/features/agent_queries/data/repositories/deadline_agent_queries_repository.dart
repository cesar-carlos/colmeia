import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_deadline.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_diagnostics.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:result_dart/result_dart.dart';

class DeadlineAgentQueriesRepository implements AgentQueriesRepository {
  DeadlineAgentQueriesRepository({
    required this._delegate,
    this._bindCancelScope,
    this._diagnosticsEnabled = false,
  });

  final bool _diagnosticsEnabled;
  static const defaultBudget = Duration(minutes: 9);
  static const maxAttempts = 3;
  final AgentQueriesRepository _delegate;
  final void Function(AgentQueriesCancelScope)? _bindCancelScope;

  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) => _run(
    totalTimeoutMs: request.totalTimeoutMs,
    bridgeTimeoutMs: request.bridgeTimeoutMs,
    parent: cancelScope,
    execute: (scope) => _delegate.executeSql(request, cancelScope: scope),
  );

  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) => _run(
    totalTimeoutMs: request.totalTimeoutMs,
    bridgeTimeoutMs: request.bridgeTimeoutMs,
    parent: cancelScope,
    execute: (scope) => _delegate.executeSqlBatch(request, cancelScope: scope),
  );

  Future<AppResult<T>> _run<T extends Object>({
    required int? totalTimeoutMs,
    required int? bridgeTimeoutMs,
    required AgentQueriesCancelScope? parent,
    required Future<AppResult<T>> Function(AgentQueriesCancelScope) execute,
  }) async {
    if (parent?.isCancelled ?? false) {
      return const Failure(OperationCancelledFailure());
    }
    if (totalTimeoutMs != null && totalTimeoutMs < 1) {
      return const Failure(
        ValidationFailure(message: 'totalTimeoutMs must be >= 1'),
      );
    }
    var budget = totalTimeoutMs != null
        ? Duration(milliseconds: totalTimeoutMs)
        : bridgeTimeoutMs != null && bridgeTimeoutMs > 0
        ? Duration(milliseconds: bridgeTimeoutMs * maxAttempts)
        : defaultBudget;
    final parentRemaining = parent?.deadline?.remaining;
    if (parentRemaining != null && parentRemaining < budget) {
      budget = parentRemaining;
    }
    final scope =
        AgentQueriesCancelScope(
            traceId: parent?.traceId,
            deadline: AgentQueryDeadline(budget),
            progressObserver: parent?.progressObserver,
            diagnostics:
                parent?.diagnostics ??
                (_diagnosticsEnabled ? AgentQueryDiagnostics() : null),
          )
          ..relayCancelHandler = parent?.relayCancelHandler
          ..socketRpcCancelHandler = parent?.socketRpcCancelHandler
          ..streamingSqlCancelHandler = parent?.streamingSqlCancelHandler;
    _bindCancelScope?.call(scope);
    final stopped = Completer<AppResult<T>>();
    final unregister = parent?.registerLocalCancellation(() {
      if (!stopped.isCompleted) {
        stopped.complete(const Failure(OperationCancelledFailure()));
      }
      scope.cancelAll();
    });
    final timer = Timer(budget, () {
      if (!stopped.isCompleted) {
        stopped.complete(
          Failure(
            NetworkFailure(
              message: 'Agent query total deadline exceeded',
              isTransient: false,
              context: {
                AgentSqlRpcFailureUiKey.field:
                    AgentSqlRpcFailureUiKey.transportTimeout,
                'deadlineExceeded': true,
                'totalTimeoutMs': budget.inMilliseconds,
              },
            ),
          ),
        );
      }
      scope.cancelAll();
    });
    try {
      if (scope.isCancelled) {
        return const Failure(OperationCancelledFailure());
      }
      if (scope.deadline!.remaining == Duration.zero) {
        scope.cancelAll();
        return const Failure(
          NetworkFailure(
            message: 'Agent query total deadline expired before dispatch',
            isTransient: false,
            context: {
              AgentSqlRpcFailureUiKey.field:
                  AgentSqlRpcFailureUiKey.transportTimeout,
              'deadlineExceeded': true,
            },
          ),
        );
      }
      return await Future.any([execute(scope), stopped.future]);
    } finally {
      scope.diagnostics?.complete();
      timer.cancel();
      unregister?.call();
    }
  }
}
