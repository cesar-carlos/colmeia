import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_read_only_batch_options.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcela_forma_pagamento_row_model_v2.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcela_por_usuario_row_model.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_transport_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy_extensions.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/overview/data/overview_batch_command_builder.dart';
import 'package:colmeia/features/overview/data/overview_batch_load_config.dart';
import 'package:colmeia/features/overview/data/overview_batch_load_result.dart';
import 'package:colmeia/features/overview/data/overview_sql_batch_item_rows_mapper.dart';

/// Executes and maps the overview main phased SQL batch (payment resumo +
/// per-user ranking) for a single agent target.
final class OverviewMainBatchRunner {
  OverviewMainBatchRunner({
    required AgentQueriesRepository agentQueriesRepository,
    int maxParallelReadOnlyBatchItems = 4,
    int sqlTimeoutMs = OverviewBatchLoadConfig.sqlTimeoutMs,
    int maxRows = OverviewBatchLoadConfig.maxRows,
    AgentQueryTransportPolicy? transportPolicy,
  }) : _agentQueriesRepository = agentQueriesRepository,
       _maxParallelReadOnlyBatchItems = maxParallelReadOnlyBatchItems,
       _sqlTimeoutMs = sqlTimeoutMs,
       _maxRows = maxRows,
       _transportPolicy =
           transportPolicy ??
           AgentQueryTransportPolicy(
             mode: AppEnvironment.agentQueryTransportPolicyMode,
           );

  final AgentQueriesRepository _agentQueriesRepository;
  final int _maxParallelReadOnlyBatchItems;
  final int _sqlTimeoutMs;
  final int _maxRows;
  final AgentQueryTransportPolicy _transportPolicy;

  Future<OverviewBatchTargetResult> loadForTarget({
    required String userId,
    required AgentQueryTarget target,
    required int planBridgeTimeoutMs,
    required OverviewMainBatchCommands batch,
    required Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) async {
    final started = DateTime.now();
    final batchRequest = _transportPolicy.applyBatch(
      AgentSqlExecuteBatchRequest(
        agentId: target.agentId,
        requestingUserId: userId,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow:
            target.hubConnectedFromApprovedCatalogRow,
        commands: batch.commands,
        clientToken: target.clientToken,
        bridgeTimeoutMs: planBridgeTimeoutMs,
        options: AgentSqlReadOnlyBatchOptions.dashboard(
          sqlTimeoutMs: _sqlTimeoutMs,
          maxRows: _maxRows,
          maxParallelReadOnlyBatchItems: _maxParallelReadOnlyBatchItems,
        ),
        skipTransportCache: cachePolicy.bypassTransportCache,
      ),
      dashboardBatch: true,
    );
    final result = await _agentQueriesRepository.executeSqlBatch(
      batchRequest,
      cancelScope: cancelScope,
    );
    final elapsedMs = DateTime.now().difference(started).inMilliseconds;
    final execution = result.getOrNull();
    if (execution == null) {
      final failure = result.exceptionOrNull()!;
      return OverviewBatchTargetResult(
        target: target,
        elapsedMs: elapsedMs,
        mainFailure: failure,
      );
    }

    return mapExecution(
      target: target,
      elapsedMs: elapsedMs,
      execution: execution,
      indexes: batch.indexes,
    );
  }

  OverviewBatchTargetResult mapExecution({
    required AgentQueryTarget target,
    required int elapsedMs,
    required AgentSqlBatchExecutionResult execution,
    required OverviewMainBatchCommandIndexes indexes,
  }) {
    final byIndex = <int, AgentSqlBatchExecutionItem>{
      for (final item in execution.items) item.index: item,
    };

    final main = OverviewSqlBatchItemRowsMapper.mapRowsForIndex(
      byIndex,
      indexes.main,
      (row) => ResumoParcelaFormaPagamentoRowModelV2.fromMap(row).toEntity(),
    );
    final userRanking = OverviewSqlBatchItemRowsMapper.mapRowsForIndex(
      byIndex,
      indexes.userRanking,
      (row) => ResumoParcelaPorUsuarioRowModel.fromMap(row).toEntity(),
    );

    return OverviewBatchTargetResult(
      target: target,
      elapsedMs: elapsedMs,
      mainRows: main.rows,
      mainFailure: main.failure,
      userRankingRows: userRanking.rows,
      userRankingFailure: userRanking.failure,
    );
  }
}
