import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_read_only_batch_options.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_dia_semana_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_dia_semana_usuario_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_mensal_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_produto_venda_lucratividade_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_total_diario_vendas_row_model.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_transport_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy_extensions.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/overview/data/overview_batch_command_builder.dart';
import 'package:colmeia/features/overview/data/overview_batch_facts_persister.dart';
import 'package:colmeia/features/overview/data/overview_batch_load_config.dart';
import 'package:colmeia/features/overview/data/overview_batch_load_result.dart';
import 'package:colmeia/features/overview/data/overview_cached_section_loader.dart';
import 'package:colmeia/features/overview/data/overview_sql_batch_item_rows_mapper.dart';

/// Executes and maps the overview section SQL batch for a single agent target,
/// including cached-section merge and fact persistence.
final class OverviewSectionBatchRunner {
  OverviewSectionBatchRunner({
    required this._agentQueriesRepository,
    this._cachedSectionLoader,
    this._factsPersister,
    this._maxParallelReadOnlyBatchItems = 4,
    this._sqlTimeoutMs = OverviewBatchLoadConfig.sqlTimeoutMs,
    this._maxRows = OverviewBatchLoadConfig.maxRows,
    AgentQueryTransportPolicy? transportPolicy,
  }) : _transportPolicy =
           transportPolicy ??
           AgentQueryTransportPolicy(
             mode: AppEnvironment.agentQueryTransportPolicyMode,
           );

  final AgentQueriesRepository _agentQueriesRepository;
  final OverviewCachedSectionLoader? _cachedSectionLoader;
  final OverviewBatchFactsPersister? _factsPersister;
  final int _maxParallelReadOnlyBatchItems;
  final int _sqlTimeoutMs;
  final int _maxRows;
  final AgentQueryTransportPolicy _transportPolicy;

  bool get _usesCachedDailyMonthlySections =>
      _cachedSectionLoader?.usesDailyMonthly ?? false;

  bool get _usesCachedWeekdaySection =>
      _cachedSectionLoader?.usesWeekday ?? false;

  bool get _usesCachedLucratividadeSection =>
      _cachedSectionLoader?.usesLucratividade ?? false;

  Future<OverviewBatchTargetResult> loadForTarget({
    required String userId,
    required AgentQueryTarget target,
    required int planBridgeTimeoutMs,
    required OverviewSectionBatchCommands batch,
    required ResumoParcelasMensalFilter mensalFilter,
    required ResumoParcelasDiaSemanaFilter weekdayFilter,
    required ResumoTotalDiarioVendasFilter dailyTotalFilter,
    required Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
    Set<String>? factsPersistedAgentIds,
  }) async {
    final started = DateTime.now();
    final batchOutcome = await _executeSqlBatch(
      userId: userId,
      target: target,
      planBridgeTimeoutMs: planBridgeTimeoutMs,
      batch: batch,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      cancelScope: cancelScope,
      cachePolicy: cachePolicy,
    );
    final cachedSections = await _cachedSectionLoader?.load(
      cachePolicy: cachePolicy,
      userId: userId,
      target: target,
      mensalFilter: mensalFilter,
      weekdayFilter: weekdayFilter,
      dailyTotalFilter: dailyTotalFilter,
      planBridgeTimeoutMs: planBridgeTimeoutMs,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      cancelScope: cancelScope,
    );
    final elapsedMs = DateTime.now().difference(started).inMilliseconds;
    if (batchOutcome.failure != null) {
      return targetResultWithSectionFailures(
        target: target,
        elapsedMs: elapsedMs,
        failure: batchOutcome.failure!,
        cachedSections: cachedSections,
      );
    }

    final mapped = mergeCachedSections(
      base: mapExecution(
        target: target,
        elapsedMs: elapsedMs,
        execution: batchOutcome.execution!,
        indexes: batch.indexes,
      ),
      cached: cachedSections,
    );
    await persistFacts(
      userId: userId,
      target: target,
      mensalFilter: mensalFilter,
      dailyTotalFilter: dailyTotalFilter,
      monthlyRows: mapped.monthlyRows,
      dailyRows: mapped.dailyRows,
      cachePolicy: cachePolicy,
      factsPersistedAgentIds: factsPersistedAgentIds,
    );
    return mapped;
  }

  Future<void> persistFacts({
    required String userId,
    required AgentQueryTarget target,
    required ResumoParcelasMensalFilter mensalFilter,
    required ResumoTotalDiarioVendasFilter dailyTotalFilter,
    required List<ResumoParcelasMensalRow> monthlyRows,
    required List<ResumoTotalDiarioVendasRow> dailyRows,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
    Set<String>? factsPersistedAgentIds,
  }) async {
    final persister = _factsPersister;
    if (persister == null) {
      return;
    }
    await persister.persistDailyRows(
      userId: userId,
      agentId: target.agentId,
      filter: dailyTotalFilter,
      rows: dailyRows,
      cachePolicy: cachePolicy,
    );
    await persister.persistMonthlyRows(
      userId: userId,
      agentId: target.agentId,
      filter: mensalFilter,
      rows: monthlyRows,
      cachePolicy: cachePolicy,
    );
    if (cachePolicy != AgentQueryLoadPolicy.forceRefresh &&
        (dailyRows.isNotEmpty || monthlyRows.isNotEmpty)) {
      factsPersistedAgentIds?.add(target.agentId);
    }
  }

  OverviewBatchTargetResult mergeCachedSections({
    required OverviewBatchTargetResult base,
    required OverviewCachedSections? cached,
  }) {
    if (cached == null) {
      return base;
    }
    return OverviewBatchTargetResult(
      target: base.target,
      elapsedMs: base.elapsedMs,
      mainRows: base.mainRows,
      userRankingRows: base.userRankingRows,
      monthlyRows: cached.monthlyRows,
      weekdayRows: cached.weekdayRows,
      dailyRows: cached.dailyRows,
      weekdayUserRows: base.weekdayUserRows,
      lucratividadeRows: cached.lucratividadeRows,
      mainFailure: base.mainFailure,
      userRankingFailure: base.userRankingFailure,
      monthlyFailure: cached.monthlyFailure ?? base.monthlyFailure,
      weekdayFailure: cached.weekdayFailure ?? base.weekdayFailure,
      dailyFailure: cached.dailyFailure ?? base.dailyFailure,
      weekdayUserFailure: base.weekdayUserFailure,
      lucratividadeFailure:
          cached.lucratividadeFailure ?? base.lucratividadeFailure,
    );
  }

  OverviewBatchTargetResult targetResultWithSectionFailures({
    required AgentQueryTarget target,
    required int elapsedMs,
    required AppFailure failure,
    OverviewCachedSections? cachedSections,
    AppFailure? mainFailure,
  }) {
    final cached = cachedSections;
    return OverviewBatchTargetResult(
      target: target,
      elapsedMs: elapsedMs,
      monthlyRows: cached?.monthlyRows ?? const <ResumoParcelasMensalRow>[],
      weekdayRows: cached?.weekdayRows ?? const <ResumoParcelasDiaSemanaRow>[],
      dailyRows: cached?.dailyRows ?? const <ResumoTotalDiarioVendasRow>[],
      lucratividadeRows:
          cached?.lucratividadeRows ??
          const <ResumoProdutoVendaLucratividadeRow>[],
      mainFailure: mainFailure,
      monthlyFailure: _usesCachedDailyMonthlySections
          ? cached?.monthlyFailure
          : failure,
      weekdayFailure: _usesCachedWeekdaySection
          ? cached?.weekdayFailure
          : failure,
      dailyFailure: _usesCachedDailyMonthlySections
          ? cached?.dailyFailure
          : failure,
      weekdayUserFailure: failure,
      lucratividadeFailure: _usesCachedLucratividadeSection
          ? cached?.lucratividadeFailure
          : failure,
    );
  }

  OverviewBatchTargetResult mapExecution({
    required AgentQueryTarget target,
    required int elapsedMs,
    required AgentSqlBatchExecutionResult execution,
    required OverviewSectionBatchCommandIndexes indexes,
  }) {
    final byIndex = <int, AgentSqlBatchExecutionItem>{
      for (final item in execution.items) item.index: item,
    };

    final monthly = indexes.monthly == null
        ? const OverviewSqlBatchItemRowsResult<ResumoParcelasMensalRow>(
            rows: <ResumoParcelasMensalRow>[],
          )
        : OverviewSqlBatchItemRowsMapper.mapRowsForIndex(
            byIndex,
            indexes.monthly!,
            (row) => ResumoParcelasMensalRowModel.fromMap(row).toEntity(),
          );
    if (indexes.monthly != null) {
      _warnIfReachedMaxRows(
        target: target,
        section: 'monthly',
        rowCount: monthly.rows.length,
        maxRows: AgentQueriesBoundedResultMaxRows.resumoParcelasMensal,
      );
    }
    final weekday = indexes.weekday == null
        ? const OverviewSqlBatchItemRowsResult<ResumoParcelasDiaSemanaRow>(
            rows: <ResumoParcelasDiaSemanaRow>[],
          )
        : OverviewSqlBatchItemRowsMapper.mapRowsForIndex(
            byIndex,
            indexes.weekday!,
            (row) => ResumoParcelasDiaSemanaRowModel.fromMap(row).toEntity(),
          );
    if (indexes.weekday != null) {
      _warnIfReachedMaxRows(
        target: target,
        section: 'weekday',
        rowCount: weekday.rows.length,
        maxRows: AgentQueriesBoundedResultMaxRows.resumoParcelasDiaSemana,
      );
    }
    final daily = indexes.daily == null
        ? const OverviewSqlBatchItemRowsResult<ResumoTotalDiarioVendasRow>(
            rows: <ResumoTotalDiarioVendasRow>[],
          )
        : OverviewSqlBatchItemRowsMapper.mapRowsForIndex(
            byIndex,
            indexes.daily!,
            (row) => ResumoTotalDiarioVendasRowModel.fromMap(row).toEntity(),
          );
    if (indexes.daily != null) {
      _warnIfReachedMaxRows(
        target: target,
        section: 'daily',
        rowCount: daily.rows.length,
        maxRows: AgentQueriesBoundedResultMaxRows.resumoTotalDiarioVendas,
      );
    }
    final weekdayUser = indexes.weekdayUser == null
        ? const OverviewSqlBatchItemRowsResult<
            ResumoParcelasDiaSemanaUsuarioRow
          >(
            rows: <ResumoParcelasDiaSemanaUsuarioRow>[],
          )
        : OverviewSqlBatchItemRowsMapper.mapRowsForIndex(
            byIndex,
            indexes.weekdayUser!,
            (row) =>
                ResumoParcelasDiaSemanaUsuarioRowModel.fromMap(row).toEntity(),
          );
    if (indexes.weekdayUser != null) {
      _warnIfReachedMaxRows(
        target: target,
        section: 'weekdayUser',
        rowCount: weekdayUser.rows.length,
        maxRows:
            AgentQueriesBoundedResultMaxRows.resumoParcelasDiaSemanaUsuario,
      );
    }
    final lucratividade = indexes.lucratividade == null
        ? const OverviewSqlBatchItemRowsResult<
            ResumoProdutoVendaLucratividadeRow
          >(
            rows: <ResumoProdutoVendaLucratividadeRow>[],
          )
        : OverviewSqlBatchItemRowsMapper.mapRowsForIndex(
            byIndex,
            indexes.lucratividade!,
            (row) =>
                ResumoProdutoVendaLucratividadeRowModel.fromMap(row).toEntity(),
          );
    if (indexes.lucratividade != null) {
      _warnIfReachedMaxRows(
        target: target,
        section: 'lucratividade',
        rowCount: lucratividade.rows.length,
        maxRows:
            AgentQueriesBoundedResultMaxRows.resumoProdutoVendaLucratividade,
      );
    }

    return OverviewBatchTargetResult(
      target: target,
      elapsedMs: elapsedMs,
      monthlyRows: monthly.rows,
      weekdayRows: weekday.rows,
      dailyRows: daily.rows,
      weekdayUserRows: weekdayUser.rows,
      lucratividadeRows: lucratividade.rows,
      monthlyFailure: monthly.failure,
      weekdayFailure: weekday.failure,
      dailyFailure: daily.failure,
      weekdayUserFailure: weekdayUser.failure,
      lucratividadeFailure: lucratividade.failure,
    );
  }

  Future<({AgentSqlBatchExecutionResult? execution, AppFailure? failure})>
  _executeSqlBatch({
    required String userId,
    required AgentQueryTarget target,
    required int planBridgeTimeoutMs,
    required OverviewSectionBatchCommands batch,
    required Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) async {
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
    final execution = result.getOrNull();
    if (execution == null) {
      return (execution: null, failure: result.exceptionOrNull());
    }
    return (execution: execution, failure: null);
  }

  void _warnIfReachedMaxRows({
    required AgentQueryTarget target,
    required String section,
    required int rowCount,
    required int maxRows,
  }) {
    if (rowCount < maxRows) {
      return;
    }
    AppLogger.warning(
      'Overview batch section reached max_rows cap (possible truncation)',
      context: <String, Object?>{
        'operation': 'loadOverviewBatch',
        'section': section,
        'agentId': target.agentId,
        'rowCount': rowCount,
        'maxRows': maxRows,
      },
    );
  }
}
