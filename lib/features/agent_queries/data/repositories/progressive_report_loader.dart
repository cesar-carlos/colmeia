import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_progress.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:result_dart/result_dart.dart';

class ProgressiveReportLoader<Row> {
  const ProgressiveReportLoader();

  Stream<AppResult<AgentQueryProgress<Row>>> load({
    required Future<AppResult<List<Row>>> Function(AgentQueriesCancelScope)
    execute,
    required List<Row> Function(AgentSqlExecutionResult) mapRows,
    AgentQueriesCancelScope? parent,
  }) => loadBatches(
    parent: parent,
    mapRows: mapRows,
    execute: (scope, publish) => execute(scope),
  );

  Stream<AppResult<AgentQueryProgress<Row>>> loadBatches({
    required Future<AppResult<List<Row>>> Function(
      AgentQueriesCancelScope,
      void Function(List<Row>),
    )
    execute,
    List<Row> Function(AgentSqlExecutionResult)? mapRows,
    AgentQueriesCancelScope? parent,
  }) {
    var received = 0;
    var active = true;
    var settled = false;
    late final StreamController<AppResult<AgentQueryProgress<Row>>> controller;
    late final AgentQueriesCancelScope scope;
    void publish(List<Row> rows) {
      if (!active || scope.isCancelled || rows.isEmpty) return;
      scope.progressObserver!.hasPublishedRows = true;
      received += rows.length;
      controller.add(
        Success(
          AgentQueryProgress(
            rows: rows,
            isComplete: false,
            receivedRowCount: received,
          ),
        ),
      );
    }

    scope =
        AgentQueriesCancelScope(
            traceId: parent?.traceId,
            deadline: parent?.deadline,
            diagnostics: parent?.diagnostics,
            progressObserver: AgentQueryProgressObserver((execution) {
              if (!active) return;
              if (mapRows != null) publish(mapRows(execution));
            }),
          )
          ..relayCancelHandler = parent?.relayCancelHandler
          ..socketRpcCancelHandler = parent?.socketRpcCancelHandler
          ..streamingSqlCancelHandler = parent?.streamingSqlCancelHandler;
    final unregister = parent?.registerLocalCancellation(scope.cancelAll);
    Future<void> run() async {
      try {
        if (scope.isCancelled) {
          controller.add(const Failure(OperationCancelledFailure()));
          return;
        }
        final result = await execute(scope, publish);
        if (!active) return;
        if (scope.isCancelled) {
          controller.add(const Failure(OperationCancelledFailure()));
        } else {
          controller.add(
            result.map(
              (rows) => AgentQueryProgress(
                rows: rows,
                isComplete: true,
                receivedRowCount: rows.length,
              ),
            ),
          );
        }
      } on Object catch (error, stack) {
        if (active) {
          controller.add(
            Failure(
              UnknownFailure(
                message: 'Progressive report could not be completed',
                cause: error,
                stackTrace: stack,
                context: const {
                  AgentSqlRpcFailureUiKey.field:
                      AgentSqlRpcFailureUiKey.unexpectedAgentResponse,
                },
              ),
            ),
          );
        }
        scope.cancelAll();
      } finally {
        settled = true;
        unregister?.call();
        await controller.close();
      }
    }

    controller = StreamController(
      onListen: () => unawaited(run()),
      onCancel: () {
        active = false;
        unregister?.call();
        if (!settled) {
          scope.cancelAll();
        }
      },
    );
    return controller.stream;
  }
}
