import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_warn_if_sql_rows_at_cap.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_read_only_batch_options.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_transport_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_plan.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/sales/data/sales_live_map_batch_command_builder.dart';
import 'package:colmeia/features/sales/data/sales_live_map_batch_load_config.dart';
import 'package:colmeia/features/sales/data/sales_live_map_batch_rows_mapper.dart';
import 'package:colmeia/features/sales/data/sales_live_map_batch_target_result.dart';

/// Executes merged catalog + sales SQL batches and catalog pagination for one
/// agent target in the sales live map load path.
final class SalesLiveMapBatchTargetRunner {
  SalesLiveMapBatchTargetRunner({
    required this._agentQueriesRepository,
    int? maxParallelReadOnlyBatchItems,
    AgentQueryTransportPolicy? transportPolicy,
  }) : _maxParallelReadOnlyBatchItems =
           maxParallelReadOnlyBatchItems ??
           AppEnvironment.agentSqlOverviewBatchMaxParallelReadOnlyItems,
       _transportPolicy =
           transportPolicy ??
           AgentQueryTransportPolicy(
             mode: AppEnvironment.agentQueryTransportPolicyMode,
           );

  final AgentQueriesRepository _agentQueriesRepository;
  final int _maxParallelReadOnlyBatchItems;
  final AgentQueryTransportPolicy _transportPolicy;

  Future<SalesLiveMapBatchTargetResult> loadFirstBatchForTarget({
    required String userId,
    required AgentQueryTarget target,
    required AgentQueryPlan plan,
    required CadastroFilialFilter catalogFilter,
    required ResumoTotalVendasMunicipioFilialPeriodoFilter salesFilter,
    required AgentQueryTargetResolution resolution,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final started = DateTime.now();
    final agentId = target.agentId.trim();
    final firstPageFilter = catalogFilter.copyWith(
      page: 1,
      pageSize: CadastroFilialFilter.maxPageSize,
    );
    final batch = SalesLiveMapBatchCommandBuilder.build(
      catalogFilter: firstPageFilter.forAgent(agentId),
      salesFilter: salesFilter.forAgent(agentId),
    );
    final batchRequest = _transportPolicy.applyBatch(
      AgentSqlExecuteBatchRequest(
        agentId: agentId,
        requestingUserId: userId,
        hubPresenceOnlineAgentIdsSnapshot:
            resolution.hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow:
            target.hubConnectedFromApprovedCatalogRow,
        commands: batch.commands,
        clientToken: target.clientToken,
        bridgeTimeoutMs: plan.bridgeTimeoutMs,
        options: AgentSqlReadOnlyBatchOptions.dashboard(
          sqlTimeoutMs: SalesLiveMapBatchLoadConfig.sqlTimeoutMs,
          maxRows: SalesLiveMapBatchLoadConfig.batchMaxRows,
          maxParallelReadOnlyBatchItems: _maxParallelReadOnlyBatchItems,
        ),
        // Avoid sticking empty agent successes on the live-map refresh path.
        skipTransportCache: true,
        useRelay: true,
      ),
      dashboardBatch: true,
    );
    final result = await _agentQueriesRepository.executeSqlBatch(
      batchRequest,
      cancelScope: cancelScope,
    );
    final execution = result.getOrNull();
    if (execution == null) {
      final failure = result.exceptionOrNull()!;
      return SalesLiveMapBatchTargetResult(
        target: target,
        elapsedMs: DateTime.now().difference(started).inMilliseconds,
        catalogFailure: failure,
        salesFailure: failure,
      );
    }

    final mapped = SalesLiveMapBatchRowsMapper.mapMergedExecution(
      target: target,
      execution: execution,
      indexes: batch.indexes,
    );
    if (mapped.catalogFailure != null && mapped.salesFailure != null) {
      return SalesLiveMapBatchTargetResult(
        target: target,
        elapsedMs: DateTime.now().difference(started).inMilliseconds,
        catalogFailure: mapped.catalogFailure,
        salesFailure: mapped.salesFailure,
      );
    }

    agentQueriesWarnIfSqlRowsAtCap(
      operation: 'loadSalesLiveMapBatch',
      agentId: target.agentId,
      returnedRowCount: mapped.salesRows.length,
      maxRows: AgentQueriesBoundedResultMaxRows
          .resumoTotalVendasMunicipioFilialPeriodo,
    );

    return SalesLiveMapBatchTargetResult(
      target: target,
      elapsedMs: DateTime.now().difference(started).inMilliseconds,
      catalogRows: mapped.catalogRows,
      catalogSourceRowCount: mapped.catalogSourceRowCount,
      salesRows: mapped.salesRows,
      catalogFailure: mapped.catalogFailure,
      salesFailure: mapped.salesFailure,
    );
  }

  Future<SalesLiveMapBatchTargetResult> paginateCatalogForTarget({
    required SalesLiveMapBatchTargetResult firstBatch,
    required String userId,
    required AgentQueryTarget target,
    required AgentQueryPlan plan,
    required CadastroFilialFilter catalogFilter,
    required AgentQueryTargetResolution resolution,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    if (!SalesLiveMapBatchTargetResult.needsCatalogPagination(firstBatch)) {
      return firstBatch;
    }
    final pagination = await _loadRemainingCatalogPages(
      userId: userId,
      target: target,
      plan: plan,
      catalogFilter: catalogFilter,
      resolution: resolution,
      cancelScope: cancelScope,
      initialRows: firstBatch.catalogRows,
      reportedTotalCount: firstBatch.catalogSourceRowCount,
      startPage: 2,
    );
    return SalesLiveMapBatchTargetResult(
      target: target,
      elapsedMs: firstBatch.elapsedMs,
      catalogRows: pagination.rows,
      catalogSourceRowCount: pagination.sourceRowCount,
      salesRows: firstBatch.salesRows,
      catalogFailure: firstBatch.catalogFailure,
      salesFailure: firstBatch.salesFailure,
      paginationStalled: pagination.paginationStalled,
    );
  }

  Future<
    ({
      List<CadastroFilialRow> rows,
      int sourceRowCount,
      bool paginationStalled,
    })
  >
  _loadRemainingCatalogPages({
    required String userId,
    required AgentQueryTarget target,
    required AgentQueryPlan plan,
    required CadastroFilialFilter catalogFilter,
    required AgentQueryTargetResolution resolution,
    required AgentQueriesCancelScope? cancelScope,
    required List<CadastroFilialRow> initialRows,
    required int reportedTotalCount,
    required int startPage,
  }) async {
    final rows = List<CadastroFilialRow>.from(initialRows);
    final seenRowKeys = rows
        .map((row) => '${row.codEmpresa}:${row.codFilial}')
        .toSet();
    var page = startPage;
    var paginationStalled = false;
    final agentId = target.agentId.trim();

    while (page <= SalesLiveMapBatchLoadConfig.maxAllPagesPerAgent) {
      if (rows.length >= reportedTotalCount) {
        break;
      }
      final pageFilter = catalogFilter.copyWith(
        page: page,
        pageSize: CadastroFilialFilter.maxPageSize,
      );
      final batch = SalesLiveMapBatchCommandBuilder.buildCatalogOnly(
        catalogFilter: pageFilter.forAgent(agentId),
      );
      final batchRequest = _transportPolicy.applyBatch(
        AgentSqlExecuteBatchRequest(
          agentId: agentId,
          requestingUserId: userId,
          hubPresenceOnlineAgentIdsSnapshot:
              resolution.hubPresenceOnlineAgentIdsSnapshot,
          hubConnectedFromApprovedCatalogRow:
              target.hubConnectedFromApprovedCatalogRow,
          commands: batch.commands,
          clientToken: target.clientToken,
          bridgeTimeoutMs: plan.bridgeTimeoutMs,
          options: AgentSqlReadOnlyBatchOptions.dashboard(
            sqlTimeoutMs: SalesLiveMapBatchLoadConfig.sqlTimeoutMs,
            maxRows: AgentQueriesBoundedResultMaxRows.cadastroFilialPage,
            maxParallelReadOnlyBatchItems: _maxParallelReadOnlyBatchItems,
          ),
          skipTransportCache: true,
          useRelay: true,
        ),
        dashboardBatch: true,
      );
      final result = await _agentQueriesRepository.executeSqlBatch(
        batchRequest,
        cancelScope: cancelScope,
      );
      final execution = result.getOrNull();
      if (execution == null) {
        paginationStalled = true;
        _logPaginationPageFailure(
          agentId: agentId,
          filter: catalogFilter,
          page: page,
          failure: result.exceptionOrNull(),
        );
        break;
      }
      final pageResult = SalesLiveMapBatchRowsMapper.mapCatalogExecution(
        execution: execution,
        catalogIndex: batch.indexes.catalog,
      );
      if (pageResult.failure != null) {
        paginationStalled = true;
        _logPaginationPageFailure(
          agentId: agentId,
          filter: catalogFilter,
          page: page,
          failure: pageResult.failure,
        );
        break;
      }
      var newRowCount = 0;
      for (final row in pageResult.rows) {
        if (!seenRowKeys.add('${row.codEmpresa}:${row.codFilial}')) {
          continue;
        }
        rows.add(row);
        newRowCount += 1;
      }
      if (pageResult.rows.isEmpty) {
        break;
      }
      if (newRowCount == 0) {
        paginationStalled = true;
        _logPaginationStalled(
          agentId: agentId,
          filter: catalogFilter,
          page: page,
          pageRowCount: pageResult.rows.length,
          loadedUniqueRowCount: rows.length,
          reportedTotalCount: reportedTotalCount,
        );
        break;
      }
      if (rows.length >= reportedTotalCount ||
          pageResult.rows.length < CadastroFilialFilter.maxPageSize) {
        break;
      }
      page += 1;
    }

    return (
      rows: rows,
      sourceRowCount: paginationStalled ? rows.length : reportedTotalCount,
      paginationStalled: paginationStalled,
    );
  }

  void _logPaginationPageFailure({
    required String agentId,
    required CadastroFilialFilter filter,
    required int page,
    required AppFailure? failure,
  }) {
    AppLogger.warning(
      'Sales live map catalog batch pagination page failed',
      context: <String, Object?>{
        'operation': 'loadSalesLiveMapBatch',
        'agentId': agentId.trim(),
        'filterScopeSignature': filter.filterScopeSignature,
        'page': page,
        'failureType': failure?.runtimeType.toString(),
        'failureMessage': failure?.message,
      },
    );
  }

  void _logPaginationStalled({
    required String agentId,
    required CadastroFilialFilter filter,
    required int page,
    required int pageRowCount,
    required int loadedUniqueRowCount,
    required int reportedTotalCount,
  }) {
    AppLogger.warning(
      'Sales live map catalog batch pagination stalled without new rows',
      context: <String, Object?>{
        'operation': 'loadSalesLiveMapBatch',
        'agentId': agentId.trim(),
        'filterScopeSignature': filter.filterScopeSignature,
        'page': page,
        'pageRowCount': pageRowCount,
        'loadedUniqueRowCount': loadedUniqueRowCount,
        'reportedTotalCount': reportedTotalCount,
      },
    );
  }
}
