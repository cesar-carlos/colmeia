import 'dart:async';

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_progress.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/paged_progressive_report_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/progressive_report_repository.dart';
import 'package:result_dart/result_dart.dart';

/// Chooses presentation progress independently from the transport selection.
abstract final class ProgressiveReportLoading {
  static bool isEnabled(String reportId) =>
      AppEnvironment.progressiveReportIds.contains(reportId);
  static Stream<AppResult<AgentQueryProgress<Row>>> watch<Filter, Row>({
    required String reportId,
    required Object repository,
    required Future<AppResult<List<Row>>> Function(AgentQueriesCancelScope)
    loadComplete,
    required String userId,
    required String agentId,
    required Filter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) {
    if (AppEnvironment.progressiveReportIds.contains(reportId) &&
        repository is ProgressiveReportRepository<Filter, Row>) {
      return repository.loadProgressively(
        userId: userId,
        agentId: agentId,
        filter: filter,
        clientToken: clientToken,
        bridgeTimeoutMs: bridgeTimeoutMs,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
        cancelScope: cancelScope,
        cachePolicy: cachePolicy,
      );
    }
    return _watchComplete(loadComplete, cancelScope);
  }

  static Stream<AppResult<AgentQueryProgress<Row>>> _watchComplete<Row>(
    Future<AppResult<List<Row>>> Function(AgentQueriesCancelScope) load,
    AgentQueriesCancelScope? parent,
  ) {
    final scope =
        AgentQueriesCancelScope(
            traceId: parent?.traceId,
            deadline: parent?.deadline,
            diagnostics: parent?.diagnostics,
          )
          ..relayCancelHandler = parent?.relayCancelHandler
          ..socketRpcCancelHandler = parent?.socketRpcCancelHandler
          ..streamingSqlCancelHandler = parent?.streamingSqlCancelHandler;
    final unregister = parent?.registerLocalCancellation(scope.cancelAll);
    var active = true;
    var settled = false;
    late final StreamController<AppResult<AgentQueryProgress<Row>>> controller;
    Future<void> run() async {
      try {
        final result = scope.isCancelled
            ? Failure<List<Row>, AppFailure>(const OperationCancelledFailure())
            : await load(scope);
        if (!active) return;
        controller.add(
          scope.isCancelled
              ? const Failure(OperationCancelledFailure())
              : result.map(
                  (rows) => AgentQueryProgress(
                    rows: rows,
                    isComplete: true,
                    receivedRowCount: rows.length,
                  ),
                ),
        );
      } on Object catch (error, stack) {
        if (active) {
          controller.add(
            Failure(
              UnknownFailure(
                message: 'Report could not be completed',
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
        if (!settled) scope.cancelAll();
      },
    );
    return controller.stream;
  }

  static Stream<AppResult<AgentQueryProgress<Row>>> watchPages<Filter, Row>({
    required String reportId,
    required Object repository,
    required String userId,
    required String agentId,
    required Filter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) {
    if (repository is! PagedProgressiveReportRepository<Filter, Row>) {
      return Stream.value(
        const Failure(
          ValidationFailure(
            message: 'Repository does not support complete catalog loading',
            context: {
              AgentSqlRpcFailureUiKey.field:
                  AgentSqlRpcFailureUiKey.unexpectedAgentResponse,
            },
          ),
        ),
      );
    }
    return repository.loadPagesProgressively(
      userId: userId,
      agentId: agentId,
      filter: filter,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      cancelScope: cancelScope,
      emitPartialResults: AppEnvironment.progressiveReportIds.contains(
        reportId,
      ),
    );
  }
}
