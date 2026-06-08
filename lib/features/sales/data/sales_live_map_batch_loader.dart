import 'dart:math' as math;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_warn_if_sql_rows_at_cap.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_batch_item_rows_mapper.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_read_only_batch_options.dart';
import 'package:colmeia/features/agent_queries/data/models/cadastro_filial_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_total_vendas_municipio_filial_periodo_row_model.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_transport_policy.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_sql_batch_target_wave_runner.dart';
import 'package:colmeia/features/agent_queries/data/queries/cadastro_filial_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_total_vendas_municipio_filial_periodo_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_plan.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:result_dart/result_dart.dart';

/// SQL commands in the merged sales live map batch (catalog page + period sales).
const int salesLiveMapBatchCommandCount = 2;

final class SalesLiveMapBatchLoadResult {
  const SalesLiveMapBatchLoadResult({
    required this.catalogPage,
    required this.salesReport,
    required this.totalElapsedMs,
    this.isFinal = true,
    this.salesLoadingComplete = true,
  });

  final CadastroFilialAcrossAgentsPageResult catalogPage;
  final AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>
  salesReport;
  final int totalElapsedMs;

  /// When false, more catalog pagination or target waves may still be in flight.
  final bool isFinal;

  /// When false, merged batch first pages are still loading per target wave.
  final bool salesLoadingComplete;
}

final class _SalesLiveMapBatchTargetResult {
  const _SalesLiveMapBatchTargetResult({
    required this.target,
    required this.elapsedMs,
    this.catalogRows = const <CadastroFilialRow>[],
    this.catalogSourceRowCount = 0,
    this.salesRows = const <ResumoTotalVendasMunicipioFilialPeriodoRow>[],
    this.catalogFailure,
    this.salesFailure,
    this.paginationStalled = false,
  });

  final AgentQueryTarget target;
  final int elapsedMs;
  final List<CadastroFilialRow> catalogRows;
  final int catalogSourceRowCount;
  final List<ResumoTotalVendasMunicipioFilialPeriodoRow> salesRows;
  final AppFailure? catalogFailure;
  final AppFailure? salesFailure;
  final bool paginationStalled;
}

final class _SalesLiveMapBatchCommandIndexes {
  const _SalesLiveMapBatchCommandIndexes({
    required this.catalog,
    required this.sales,
  });

  final int catalog;
  final int sales;
}

final class _SalesLiveMapBatchCommands {
  const _SalesLiveMapBatchCommands({
    required this.commands,
    required this.indexes,
  });

  final List<AgentSqlExecuteBatchCommand> commands;
  final _SalesLiveMapBatchCommandIndexes indexes;
}

class SalesLiveMapBatchLoader {
  SalesLiveMapBatchLoader({
    required AgentQueryPlanBuilder planBuilder,
    required AgentQueriesRepository agentQueriesRepository,
    int? maxParallelReadOnlyBatchItems,
    int? targetWaveConcurrency,
    AgentQueryTransportPolicy? transportPolicy,
  }) : _planBuilder = planBuilder,
       _agentQueriesRepository = agentQueriesRepository,
       _maxParallelReadOnlyBatchItems =
           maxParallelReadOnlyBatchItems ??
           AppEnvironment.agentSqlOverviewBatchMaxParallelReadOnlyItems,
       _targetWaveConcurrency =
           targetWaveConcurrency ?? AppEnvironment.salesLiveMapMergeWaveSize,
       _transportPolicy =
           transportPolicy ??
           AgentQueryTransportPolicy(
             mode: AppEnvironment.agentQueryTransportPolicyMode,
           );

  static int get batchBridgeTimeoutMs =>
      AppEnvironment.salesLiveMapBridgeTimeoutMs;

  static int get batchSqlTimeoutMs => AppEnvironment.salesLiveMapBridgeTimeoutMs;

  static int get batchMaxRows =>
      AgentQueriesBoundedResultMaxRows.resumoTotalVendasMunicipioFilialPeriodo;

  static const int _maxAllPagesPerAgent = 400;

  final AgentQueryPlanBuilder _planBuilder;
  final AgentQueriesRepository _agentQueriesRepository;
  final int _maxParallelReadOnlyBatchItems;
  final int _targetWaveConcurrency;
  final AgentQueryTransportPolicy _transportPolicy;

  static const _targetWaveRunner = AgentSqlBatchTargetWaveRunner();

  Future<AppResult<SalesLiveMapBatchLoadResult>> load({
    required String userId,
    required CadastroFilialFilter catalogFilter,
    required ResumoTotalVendasMunicipioFilialPeriodoFilter salesFilter,
    required AgentQueryTargetResolution preResolvedResolution,
    AgentQueriesCancelScope? cancelScope,
    int? bridgeTimeoutMs,
    int? targetWaveConcurrency,
  }) async {
    AppResult<SalesLiveMapBatchLoadResult>? finalResult;
    await for (final result in loadProgressively(
      userId: userId,
      catalogFilter: catalogFilter,
      salesFilter: salesFilter,
      preResolvedResolution: preResolvedResolution,
      cancelScope: cancelScope,
      bridgeTimeoutMs: bridgeTimeoutMs,
      targetWaveConcurrency: targetWaveConcurrency,
    )) {
      finalResult = result;
      if (result.isError()) {
        return result;
      }
    }
    return finalResult ??
        const Failure<SalesLiveMapBatchLoadResult, AppFailure>(
          UnknownFailure(
            message: 'Sales live map batch load produced no data',
            userMessage: 'Unable to load the sales live map.',
          ),
        );
  }

  Stream<AppResult<SalesLiveMapBatchLoadResult>> loadProgressively({
    required String userId,
    required CadastroFilialFilter catalogFilter,
    required ResumoTotalVendasMunicipioFilialPeriodoFilter salesFilter,
    required AgentQueryTargetResolution preResolvedResolution,
    AgentQueriesCancelScope? cancelScope,
    int? bridgeTimeoutMs,
    int? targetWaveConcurrency,
  }) async* {
    final catalogValidation = catalogFilter.validationError();
    if (catalogValidation != null) {
      yield Failure<SalesLiveMapBatchLoadResult, AppFailure>(
        ValidationFailure(
          message: catalogValidation,
          context: const <String, Object?>{
            'operation': 'loadSalesLiveMapBatch',
          },
        ),
      );
      return;
    }
    final salesValidation = salesFilter.validationError();
    if (salesValidation != null) {
      yield Failure<SalesLiveMapBatchLoadResult, AppFailure>(
        ValidationFailure(
          message: salesValidation,
          context: const <String, Object?>{
            'operation': 'loadSalesLiveMapBatch',
          },
        ),
      );
      return;
    }

    final planResult = _planBuilder.build(
      queryKey: AgentQueryKey.cadastroFilial,
      strategy: AgentQueryExecutionStrategy.mergeAll,
      resolution: preResolvedResolution,
      bridgeTimeoutMs: bridgeTimeoutMs ?? batchBridgeTimeoutMs,
      orderPlannedTargetsOnlineFirst: true,
      dedupePlannedTargetsByAgentId: true,
    );
    final plan = planResult.getOrNull();
    if (plan == null) {
      yield Failure<SalesLiveMapBatchLoadResult, AppFailure>(
        planResult.exceptionOrNull()!,
      );
      return;
    }

    final started = DateTime.now();
    final targets = plan.plannedTargets.toList();
    final waveCap = targetWaveConcurrency ?? _targetWaveConcurrency;
    final waveSize = waveCap >= targets.length
        ? targets.length
        : math.max(1, waveCap);
    final firstBatchResults = <_SalesLiveMapBatchTargetResult>[];

    for (var start = 0; start < targets.length; start += waveSize) {
      final end = math.min(start + waveSize, targets.length);
      final waveResults = await Future.wait(
        List<Future<_SalesLiveMapBatchTargetResult>>.generate(
          end - start,
          (offset) => _loadFirstBatchForTarget(
            userId: userId,
            target: targets[start + offset],
            plan: plan,
            catalogFilter: catalogFilter,
            salesFilter: salesFilter,
            resolution: preResolvedResolution,
            cancelScope: cancelScope,
          ),
        ),
      );
      firstBatchResults.addAll(waveResults);
      final elapsedMs = DateTime.now().difference(started).inMilliseconds;
      yield Success<SalesLiveMapBatchLoadResult, AppFailure>(
        _buildBatchLoadResult(
          plan: plan,
          targetResults: firstBatchResults,
          totalElapsedMs: elapsedMs,
          isFinal: false,
          salesLoadingComplete: end >= targets.length,
        ),
      );
    }

    final paginationTargets = firstBatchResults
        .where(_needsCatalogPagination)
        .toList(growable: false);
    var targetResults = firstBatchResults;
    if (paginationTargets.isNotEmpty) {
      final paginatedResults = await _targetWaveRunner.run(
        targets: paginationTargets.map((result) => result.target).toList(),
        waveConcurrencyCap: waveCap,
        task: (target) {
          final firstBatch = paginationTargets.firstWhere(
            (result) => result.target.agentId == target.agentId,
          );
          return _paginateCatalogForTarget(
            firstBatch: firstBatch,
            userId: userId,
            target: target,
            plan: plan,
            catalogFilter: catalogFilter,
            resolution: preResolvedResolution,
            cancelScope: cancelScope,
          );
        },
      );
      targetResults = _mergePaginatedResults(
        firstBatchResults: firstBatchResults,
        paginatedResults: paginatedResults,
      );
    }

    final totalElapsedMs = DateTime.now().difference(started).inMilliseconds;
    yield Success<SalesLiveMapBatchLoadResult, AppFailure>(
      _buildBatchLoadResult(
        plan: plan,
        targetResults: targetResults,
        totalElapsedMs: totalElapsedMs,
        isFinal: true,
        salesLoadingComplete: true,
      ),
    );
  }

  SalesLiveMapBatchLoadResult _buildBatchLoadResult({
    required AgentQueryPlan plan,
    required List<_SalesLiveMapBatchTargetResult> targetResults,
    required int totalElapsedMs,
    required bool isFinal,
    required bool salesLoadingComplete,
  }) {
    final paginationStalledAgentIds = targetResults
        .where((result) => result.paginationStalled)
        .map((result) => result.target.agentId)
        .toSet();
    return SalesLiveMapBatchLoadResult(
      catalogPage: CadastroFilialAcrossAgentsPageResult.fromReport(
        _buildCatalogReport(plan: plan, targetResults: targetResults),
        paginationStalledAgentIds: paginationStalledAgentIds,
      ),
      salesReport: _buildSalesReport(
        plan: plan,
        targetResults: targetResults,
        totalElapsedMs: totalElapsedMs,
      ),
      totalElapsedMs: totalElapsedMs,
      isFinal: isFinal,
      salesLoadingComplete: salesLoadingComplete,
    );
  }

  static bool _needsCatalogPagination(_SalesLiveMapBatchTargetResult result) {
    return result.catalogFailure == null &&
        result.catalogRows.isNotEmpty &&
        result.catalogRows.length < result.catalogSourceRowCount;
  }

  List<_SalesLiveMapBatchTargetResult> _mergePaginatedResults({
    required List<_SalesLiveMapBatchTargetResult> firstBatchResults,
    required List<_SalesLiveMapBatchTargetResult> paginatedResults,
  }) {
    final paginatedByAgentId = <String, _SalesLiveMapBatchTargetResult>{
      for (final result in paginatedResults) result.target.agentId: result,
    };
    return firstBatchResults
        .map(
          (result) => paginatedByAgentId[result.target.agentId] ?? result,
        )
        .toList(growable: false);
  }

  Future<_SalesLiveMapBatchTargetResult> _loadFirstBatchForTarget({
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
    final batch = _buildCommands(
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
          sqlTimeoutMs: batchSqlTimeoutMs,
          maxRows: batchMaxRows,
          maxParallelReadOnlyBatchItems: _maxParallelReadOnlyBatchItems,
        ),
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
      return _SalesLiveMapBatchTargetResult(
        target: target,
        elapsedMs: DateTime.now().difference(started).inMilliseconds,
        catalogFailure: failure,
        salesFailure: failure,
      );
    }

    final mapped = _mapMergedExecution(
      target: target,
      execution: execution,
      indexes: batch.indexes,
    );
    if (mapped.catalogFailure != null && mapped.salesFailure != null) {
      return _SalesLiveMapBatchTargetResult(
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

    return _SalesLiveMapBatchTargetResult(
      target: target,
      elapsedMs: DateTime.now().difference(started).inMilliseconds,
      catalogRows: mapped.catalogRows,
      catalogSourceRowCount: mapped.catalogSourceRowCount,
      salesRows: mapped.salesRows,
      catalogFailure: mapped.catalogFailure,
      salesFailure: mapped.salesFailure,
    );
  }

  Future<_SalesLiveMapBatchTargetResult> _paginateCatalogForTarget({
    required _SalesLiveMapBatchTargetResult firstBatch,
    required String userId,
    required AgentQueryTarget target,
    required AgentQueryPlan plan,
    required CadastroFilialFilter catalogFilter,
    required AgentQueryTargetResolution resolution,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    if (!_needsCatalogPagination(firstBatch)) {
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
    return _SalesLiveMapBatchTargetResult(
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

  Future<({
    List<CadastroFilialRow> rows,
    int sourceRowCount,
    bool paginationStalled,
  })> _loadRemainingCatalogPages({
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

    while (page <= _maxAllPagesPerAgent) {
      if (rows.length >= reportedTotalCount) {
        break;
      }
      final pageFilter = catalogFilter.copyWith(
        page: page,
        pageSize: CadastroFilialFilter.maxPageSize,
      );
      final batch = _buildCatalogOnlyCommands(
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
            sqlTimeoutMs: batchSqlTimeoutMs,
            maxRows: AgentQueriesBoundedResultMaxRows.cadastroFilialPage,
            maxParallelReadOnlyBatchItems: _maxParallelReadOnlyBatchItems,
          ),
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
      final pageResult = _mapCatalogExecution(
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

  _SalesLiveMapBatchTargetResult _mapMergedExecution({
    required AgentQueryTarget target,
    required AgentSqlBatchExecutionResult execution,
    required _SalesLiveMapBatchCommandIndexes indexes,
  }) {
    final byIndex = <int, AgentSqlBatchExecutionItem>{
      for (final item in execution.items) item.index: item,
    };
    final catalog = _mapCatalogExecution(
      execution: execution,
      catalogIndex: indexes.catalog,
    );
    final sales = AgentSqlBatchItemRowsMapper.mapRowsForIndex(
      byIndex,
      indexes.sales,
      (row) =>
          ResumoTotalVendasMunicipioFilialPeriodoRowModel.fromMap(row).toEntity(),
      operation: 'loadSalesLiveMapBatch',
    );
    return _SalesLiveMapBatchTargetResult(
      target: target,
      elapsedMs: 0,
      catalogRows: catalog.rows,
      catalogSourceRowCount: catalog.sourceRowCount,
      salesRows: sales.rows,
      catalogFailure: catalog.failure,
      salesFailure: sales.failure,
    );
  }

  ({List<CadastroFilialRow> rows, int sourceRowCount, AppFailure? failure})
  _mapCatalogExecution({
    required AgentSqlBatchExecutionResult execution,
    required int catalogIndex,
  }) {
    final byIndex = <int, AgentSqlBatchExecutionItem>{
      for (final item in execution.items) item.index: item,
    };
    final item = byIndex[catalogIndex];
    if (item == null || !item.ok) {
      final failure = AgentSqlBatchItemRowsMapper.mapRowsForIndex(
        byIndex,
        catalogIndex,
        (row) => CadastroFilialRowModel.fromMap(row).toEntity(),
        operation: 'loadSalesLiveMapBatch',
      ).failure;
      return (
        rows: const <CadastroFilialRow>[],
        sourceRowCount: 0,
        failure: failure,
      );
    }
    final page = _mapCatalogPage(item.rows);
    return (
      rows: page.items,
      sourceRowCount: page.totalCount,
      failure: null,
    );
  }

  CadastroFilialPageResult _mapCatalogPage(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      return const CadastroFilialPageResult(
        items: <CadastroFilialRow>[],
        totalCount: 0,
      );
    }
    final totalCount = AgentQueriesSqlRowMapReader.readRequiredInt(
      rows.first,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('TotalCount'),
    );
    final items = rows
        .where(_rowHasBranchKey)
        .map((row) => CadastroFilialRowModel.fromMap(row).toEntity())
        .toList(growable: false);
    return CadastroFilialPageResult(items: items, totalCount: totalCount);
  }

  static bool _rowHasBranchKey(Map<String, dynamic> row) {
    final raw = AgentQueriesSqlRowMapReader.lookupFirst(
      row,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodEmpresa'),
    );
    return raw != null;
  }

  _SalesLiveMapBatchCommands _buildCommands({
    required CadastroFilialFilter catalogFilter,
    required ResumoTotalVendasMunicipioFilialPeriodoFilter salesFilter,
  }) {
    final commands = <AgentSqlExecuteBatchCommand>[];
    final catalog = _addCatalogCommand(commands, catalogFilter);
    final sales = _addSalesCommand(commands, salesFilter);
    return _SalesLiveMapBatchCommands(
      commands: commands,
      indexes: _SalesLiveMapBatchCommandIndexes(catalog: catalog, sales: sales),
    );
  }

  _SalesLiveMapBatchCommands _buildCatalogOnlyCommands({
    required CadastroFilialFilter catalogFilter,
  }) {
    final commands = <AgentSqlExecuteBatchCommand>[];
    final catalog = _addCatalogCommand(commands, catalogFilter);
    return _SalesLiveMapBatchCommands(
      commands: commands,
      indexes: _SalesLiveMapBatchCommandIndexes(catalog: catalog, sales: -1),
    );
  }

  int _addCatalogCommand(
    List<AgentSqlExecuteBatchCommand> commands,
    CadastroFilialFilter catalogFilter,
  ) {
    final index = commands.length;
    commands.add(
      AgentSqlExecuteBatchCommand(
        sql: CadastroFilialSql.query(
          branches: catalogFilter.selectedBranches,
          hasSelectedBranches: catalogFilter.hasSelectedBranches,
          codEmpresa: catalogFilter.codEmpresa,
          codFilial: catalogFilter.codFilial,
          projection: catalogFilter.mapCatalogProjection
              ? CadastroFilialSqlProjection.mapCatalog
              : CadastroFilialSqlProjection.registration,
        ),
        namedParams: <String, Object?>{
          'startRow': catalogFilter.startRow,
          'endRow': catalogFilter.endRow,
        },
        executionOrder: index,
      ),
    );
    return index;
  }

  int _addSalesCommand(
    List<AgentSqlExecuteBatchCommand> commands,
    ResumoTotalVendasMunicipioFilialPeriodoFilter salesFilter,
  ) {
    final index = commands.length;
    commands.add(
      AgentSqlExecuteBatchCommand(
        sql: ResumoTotalVendasMunicipioFilialPeriodoSql.query(
          branches: salesFilter.selectedBranches,
          codEmpresa: salesFilter.codEmpresa,
          codFilial: salesFilter.codFilial,
        ),
        namedParams: <String, Object?>{
          'dataVendaInicio': AgentQueriesSqlLocalDate.format(
            salesFilter.dataVendaInicio,
          ),
          'dataVendaFim': AgentQueriesSqlLocalDate.format(
            salesFilter.dataVendaFim,
          ),
          'origem': salesFilter.trimmedOrigem,
          'geraFinanceiro': salesFilter.trimmedGeraFinanceiro,
          'preVenda': salesFilter.trimmedPreVenda,
        },
        executionOrder: index,
      ),
    );
    return index;
  }

  AgentQueryExecutionReport<CadastroFilialRow> _buildCatalogReport({
    required AgentQueryPlan plan,
    required List<_SalesLiveMapBatchTargetResult> targetResults,
  }) {
    return AgentQueryExecutionReport<CadastroFilialRow>(
      queryKey: AgentQueryKey.cadastroFilial,
      strategy: AgentQueryExecutionStrategy.mergeAll,
      consideredApprovedAgentCount: plan.consideredApprovedAgentCount,
      plannedTargets: plan.plannedTargets,
      missingClientTokenTargets: plan.missingClientTokenTargets,
      skippedDueToHubPresenceTargets: plan.skippedDueToHubPresenceTargets,
      totalElapsedMs: targetResults.fold<int>(
        0,
        (max, result) => math.max(max, result.elapsedMs),
      ),
      participants: targetResults
          .map(
            (result) => AgentQueryExecutionParticipant<CadastroFilialRow>(
              agentId: result.target.agentId,
              displayName: result.target.displayName,
              rows: result.catalogRows,
              elapsedMs: result.elapsedMs,
              sourceRowCount: result.catalogFailure == null
                  ? result.catalogSourceRowCount
                  : result.catalogRows.length,
              failure: result.catalogFailure,
            ),
          )
          .toList(growable: false),
    );
  }

  AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>
  _buildSalesReport({
    required AgentQueryPlan plan,
    required List<_SalesLiveMapBatchTargetResult> targetResults,
    required int totalElapsedMs,
  }) {
    return AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>(
      queryKey: AgentQueryKey.resumoTotalVendasMunicipioFilialPeriodo,
      strategy: AgentQueryExecutionStrategy.mergeAll,
      consideredApprovedAgentCount: plan.consideredApprovedAgentCount,
      plannedTargets: plan.plannedTargets,
      missingClientTokenTargets: plan.missingClientTokenTargets,
      skippedDueToHubPresenceTargets: plan.skippedDueToHubPresenceTargets,
      totalElapsedMs: totalElapsedMs,
      participants: targetResults
          .map(
            (result) =>
                AgentQueryExecutionParticipant<
                  ResumoTotalVendasMunicipioFilialPeriodoRow
                >(
                  agentId: result.target.agentId,
                  displayName: result.target.displayName,
                  rows: result.salesRows,
                  elapsedMs: result.elapsedMs,
                  sourceRowCount: result.salesRows.length,
                  failure: result.salesFailure,
                ),
          )
          .toList(growable: false),
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

extension on CadastroFilialFilter {
  CadastroFilialFilter forAgent(String agentId) {
    if (!hasSelectedBranches) {
      return this;
    }
    return copyWith(selectedBranches: branchesForAgent(agentId));
  }
}

extension on ResumoTotalVendasMunicipioFilialPeriodoFilter {
  ResumoTotalVendasMunicipioFilialPeriodoFilter forAgent(String agentId) {
    if (selectedBranches.isEmpty) {
      return this;
    }
    return ResumoTotalVendasMunicipioFilialPeriodoFilter(
      dataVendaInicio: dataVendaInicio,
      dataVendaFim: dataVendaFim,
      origem: origem,
      geraFinanceiro: geraFinanceiro,
      preVenda: preVenda,
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      selectedBranches: branchesForAgent(agentId),
    );
  }
}
