import 'dart:async';

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/application/sync/agent_query_facts_prefetch_coordinator.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_fact_kind.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_store.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report_resumo_parcelas.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row_v2.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/overview/data/mappers/overview_agent_resumo_mapper.dart';
import 'package:colmeia/features/overview/data/mappers/overview_monthly_parcel_mapper.dart';
import 'package:colmeia/features/overview/data/mappers/overview_weekday_sales_trend_mapper.dart';
import 'package:colmeia/features/overview/data/mappers/overview_weekday_user_sales_trend_mapper.dart';
import 'package:colmeia/features/overview/data/overview_agent_query_load_policy_mapper.dart';
import 'package:colmeia/features/overview/data/overview_batch_assembler.dart';
import 'package:colmeia/features/overview/data/overview_batch_loader.dart';
import 'package:colmeia/features/overview/data/overview_user_rankings_override_policy.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_query_failure_detail.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_monthly_parcel_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_resumo_row.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/entities/overview_section_request.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_user_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/overview_agent_query_failure_mapper.dart';
import 'package:colmeia/features/overview/domain/overview_failure_ui_key.dart';
import 'package:colmeia/features/overview/domain/overview_last_twelve_months_venda_range.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_point.dart';
import 'package:colmeia/shared/data/charts/daily_sales_trend_point_mappers.dart';
import 'package:result_dart/result_dart.dart';

class _OverviewBatchSectionFailure {
  const _OverviewBatchSectionFailure({
    required this.loadFailed,
    this.failure,
  });

  final bool loadFailed;
  final AppFailure? failure;
}

class OverviewRepositoryImpl implements OverviewRepository {
  OverviewRepositoryImpl({
    required OverviewBatchLoader batchLoader,
    AgentQueryFactsStore? factsStore,
    AgentQueryFactsPrefetchCoordinator? factsPrefetchCoordinator,
    DateTime Function()? now,
    OverviewBatchAssembler assembler = const OverviewBatchAssembler(),
  }) : _batchLoader = batchLoader,
       _factsStore = factsStore,
       _factsPrefetchCoordinator = factsPrefetchCoordinator,
       _now = now ?? DateTime.now,
       _assembler = assembler;

  final OverviewBatchLoader _batchLoader;
  final AgentQueryFactsStore? _factsStore;
  final AgentQueryFactsPrefetchCoordinator? _factsPrefetchCoordinator;
  final DateTime Function() _now;
  final OverviewBatchAssembler _assembler;

  static const String _sourceAgentIdsContextField = 'sourceAgentIds';

  static const Set<OverviewProgressiveSection> _allProgressiveSections =
      <OverviewProgressiveSection>{
        OverviewProgressiveSection.summary,
        OverviewProgressiveSection.dailySales,
        OverviewProgressiveSection.monthlyParcels,
        OverviewProgressiveSection.paymentMix,
        OverviewProgressiveSection.weekdaySales,
        OverviewProgressiveSection.weekdayUserSales,
        OverviewProgressiveSection.agentRanking,
        OverviewProgressiveSection.userRanking,
        OverviewProgressiveSection.lucratividadePeriod,
        OverviewProgressiveSection.lucratividadeMensal,
      };

  @override
  Future<AppResult<Overview>> loadOverview({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    DashboardFilter filter = const DashboardFilter(),
    OverviewLoadLabels? rowLabels,
    AgentQueriesCancelScope? cancelScope,
    OverviewSectionRequest sectionRequest = OverviewSectionRequest.full,
  }) async {
    AppResult<Overview>? lastResult;
    await for (final result in _loadOverviewProgressivelyBatch(
      userId: userId,
      policy: policy,
      filter: filter,
      rowLabels: rowLabels,
      cancelScope: cancelScope,
      mergeSqlBatchesPerTarget: true,
      sectionRequest: sectionRequest,
    )) {
      final snapshot = result.getOrNull();
      if (snapshot != null) {
        lastResult = Success<Overview, AppFailure>(snapshot.overview);
      } else {
        return Failure<Overview, AppFailure>(result.exceptionOrNull()!);
      }
    }
    return lastResult ??
        const Failure<Overview, AppFailure>(
          UnknownFailure(
            message: 'Overview load produced no data',
            userMessage: 'Não foi possível carregar a visão geral.',
          ),
        );
  }

  @override
  Stream<AppResult<OverviewProgressiveSnapshot>> loadOverviewProgressively({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    DashboardFilter filter = const DashboardFilter(),
    OverviewLoadLabels? rowLabels,
    AgentQueriesCancelScope? cancelScope,
    OverviewSectionRequest sectionRequest = OverviewSectionRequest.full,
  }) async* {
    yield* _loadOverviewProgressivelyBatch(
      userId: userId,
      policy: policy,
      filter: filter,
      rowLabels: rowLabels,
      cancelScope: cancelScope,
      mergeSqlBatchesPerTarget:
          policy == OverviewLoadPolicy.forceRefresh ||
          AppEnvironment.agentSqlOverviewMergeSqlBatchesPerTarget,
      phasedBatchPerTarget: true,
      sectionRequest: sectionRequest,
    );
  }

  Stream<AppResult<OverviewProgressiveSnapshot>>
  _loadOverviewProgressivelyBatch({
    required String userId,
    required OverviewLoadPolicy policy,
    required DashboardFilter filter,
    OverviewLoadLabels? rowLabels,
    AgentQueriesCancelScope? cancelScope,
    bool mergeSqlBatchesPerTarget = false,
    bool phasedBatchPerTarget = false,
    OverviewSectionRequest sectionRequest = OverviewSectionRequest.full,
  }) async* {
    final resolvedRowLabels = rowLabels ?? OverviewLoadLabels.englishFallback;
    final period = _buildPeriod(filter);
    final last12Range = OverviewLast12MonthsVendaRange.fromOverviewFilter(
      filter,
      clock: _now,
    );
    final mensalFilter = ResumoParcelasMensalFilter(
      dataVendaInicio: last12Range.dataVendaInicio,
      dataVendaFim: last12Range.dataVendaFim,
    );
    final weekdayFilter = ResumoParcelasDiaSemanaFilter(
      dataVendaInicio: period.start,
      dataVendaFim: period.end,
    );
    final dailyTotalFilter = ResumoTotalDiarioVendasFilter(
      dataVendaInicio: period.start,
      dataVendaFim: period.end,
    );
    final executionStrategy = _resolveExecutionStrategy(filter);
    final cachePolicy = mapOverviewLoadPolicyToAgentQuery(policy);

    if (policy == OverviewLoadPolicy.forceRefresh) {
      await _invalidateOverviewCachedFacts(userId: userId);
    }

    try {
      await for (final loadResult in _batchLoader.loadProgressively(
        userId: userId,
        filter: filter,
        periodStart: period.start,
        periodEnd: period.end,
        last12Range: last12Range,
        mensalFilter: mensalFilter,
        weekdayFilter: weekdayFilter,
        dailyTotalFilter: dailyTotalFilter,
        executionStrategy: executionStrategy,
        cancelScope: cancelScope,
        cachePolicy: cachePolicy,
        mergeSqlBatchesPerTarget: mergeSqlBatchesPerTarget,
        phasedBatchPerTarget: phasedBatchPerTarget,
        sectionRequest: sectionRequest,
      )) {
        final loaded = loadResult.getOrNull();
        if (loaded == null) {
          final failure = _mapOverviewFailure(
            loadResult.exceptionOrNull()!,
            userId: userId,
          );
          final recovered = await _recoverOrFail(
            failure: failure,
            userId: userId,
            policy: policy,
            period: period,
            sourceAgentIds: _resolveFailureSourceAgentIds(
              failure,
              fallbackSelectedAgentIds: filter.selectedAgentIds,
            ),
          );
          yield _asProgressiveResult(recovered);
          return;
        }

        final batchResults = loaded.targetResults;
        final report = loaded.mainResumoReport;

        final sourceAgentIds = report.consideredApprovedAgentCount == 0
            ? null
            : _resolveSourceAgentIds(report);
        if (loaded.completedWithOnlyTargetFailures) {
          final firstMainFailure = batchResults
              .map((result) => result.mainFailure)
              .whereType<AppFailure>()
              .first;
          final failure = _mapOverviewFailure(
            firstMainFailure,
            userId: userId,
          );
          final recovered = await _recoverOrFail(
            failure: failure,
            userId: userId,
            policy: policy,
            period: period,
            sourceAgentIds: sourceAgentIds,
          );
          yield _asProgressiveResult(recovered);
          return;
        }

        final batchUserRankingsOverride =
            overviewUserRankingsOverrideFromBatchTargetResults(
              batchResults: batchResults,
              paymentMergedRows: report.mergedRows,
              userId: userId,
              rowLabels: resolvedRowLabels,
              operation: 'loadOverviewProgressivelyBatch',
            );
        // When the per-user resumo succeeded for at least one agent we also
        // route KPIs and agent rankings through the same rows. The
        // payment-method aggregation inflates sale counts for sales paid with
        // multiple forma_pagamento; per-user rows are grouped by
        // `(branch, user)` only and `COUNT(DISTINCT Id)` is applied once.
        final userRankingRowsByAgentId = batchUserRankingsOverride == null
            ? null
            : _userRankingRowsByAgentId(batchResults);
        final monthlySectionFailure = _batchSectionFailure(
          batchResults,
          (result) => result.monthlyFailure,
        );
        final weekdaySectionFailure = _batchSectionFailure(
          batchResults,
          (result) => result.weekdayFailure,
        );
        final dailySectionFailure = _batchSectionFailure(
          batchResults,
          (result) => result.dailyFailure,
        );
        final weekdayUserSectionFailure = _batchSectionFailure(
          batchResults,
          (result) => result.weekdayUserFailure,
        );
        final lucratividadeSectionFailure = _batchSectionFailure(
          batchResults,
          (result) => result.lucratividadeFailure,
        );
        final lucratividadeMensalSectionFailure = _batchSectionFailure(
          batchResults,
          (result) => result.lucratividadeMensalFailure,
        );
        final overview = _assembler.buildOverview(
          _mapOverviewRows(report.mergedRows),
          rowsByAgentId: _mapRowsByAgentId(report.rowsByAgentId),
          agentDisplayNamesById: _resolveAgentDisplayNames(report),
          periodStart: period.start,
          periodEnd: period.end,
          approvedAgentCount: report.consideredApprovedAgentCount,
          rowLabels: resolvedRowLabels,
          agentIdsExcludedFromQueryFailure: report.failedAgentIds,
          agentNamesExcludedFromQueryFailure: report.failedAgentNames,
          agentIdsMissingClientToken: report.missingClientTokenAgentIds,
          agentNamesMissingClientToken: report.missingClientTokenAgentNames,
          agentIdsSkippedDueToHubPresence:
              report.skippedDueToHubPresenceAgentIds,
          agentNamesSkippedDueToHubPresence:
              report.skippedDueToHubPresenceAgentNames,
          monthlyParcelTrend: _batchMonthlyPoints(
            batchResults,
            mensalFilter,
            sectionLoadFailed: monthlySectionFailure.loadFailed,
            strategy: executionStrategy,
          ),
          monthlyParcelTrendLoadFailed: monthlySectionFailure.loadFailed,
          monthlyParcelTrendLoadFailure: monthlySectionFailure.failure,
          weekdaySalesTrend: _batchWeekdayPoints(
            batchResults,
            strategy: executionStrategy,
          ),
          weekdaySalesTrendLoadFailed: weekdaySectionFailure.loadFailed,
          weekdaySalesTrendLoadFailure: weekdaySectionFailure.failure,
          dailySalesTrend: _batchDailyPoints(
            batchResults,
            dailyTotalFilter,
            sectionLoadFailed: dailySectionFailure.loadFailed,
            strategy: executionStrategy,
          ),
          dailySalesTrendLoadFailed: dailySectionFailure.loadFailed,
          dailySalesTrendLoadFailure: dailySectionFailure.failure,
          weekdayUserSalesTrend: _batchWeekdayUserPoints(
            batchResults,
            strategy: executionStrategy,
          ),
          weekdayUserSalesTrendLoadFailed: weekdayUserSectionFailure.loadFailed,
          weekdayUserSalesTrendLoadFailure: weekdayUserSectionFailure.failure,
          lucratividadeTrend: _batchLucratividadePoints(batchResults),
          lucratividadeTrendLoadFailed: lucratividadeSectionFailure.loadFailed,
          lucratividadeTrendLoadFailure: lucratividadeSectionFailure.failure,
          lucratividadePartialFailureAgentNames:
              _batchLucratividadePartialFailureAgentNames(batchResults),
          lucratividadeMensalTrend: _batchLucratividadeMensalRows(batchResults),
          lucratividadeMensalTrendLoadFailed:
              lucratividadeMensalSectionFailure.loadFailed,
          lucratividadeMensalTrendLoadFailure:
              lucratividadeMensalSectionFailure.failure,
          mainResumoHadPlannedTargets: report.plannedTargets.isNotEmpty,
          partialQueryFailureDetails: <OverviewAgentQueryFailureDetail>[
            ...overviewPartialFailuresFromParticipants(report.participants),
            ..._batchLucratividadePartialFailureDetails(batchResults),
            ..._batchSectionPartialFailureDetails(
              batchResults,
              failureOf: (result) => result.userRankingFailure,
              source: OverviewAgentQueryFailureSource.userResumo,
            ),
            ..._batchSectionPartialFailureDetails(
              batchResults,
              failureOf: (result) => result.monthlyFailure,
              source: OverviewAgentQueryFailureSource.monthlyTrend,
            ),
            ..._batchSectionPartialFailureDetails(
              batchResults,
              failureOf: (result) => result.weekdayFailure,
              source: OverviewAgentQueryFailureSource.weekdayTrend,
            ),
            ..._batchSectionPartialFailureDetails(
              batchResults,
              failureOf: (result) => result.weekdayUserFailure,
              source: OverviewAgentQueryFailureSource.weekdayUserTrend,
            ),
            ..._batchSectionPartialFailureDetails(
              batchResults,
              failureOf: (result) => result.dailyFailure,
              source: OverviewAgentQueryFailureSource.dailyTrend,
            ),
            ..._batchSectionPartialFailureDetails(
              batchResults,
              failureOf: (result) => result.lucratividadeMensalFailure,
              source: OverviewAgentQueryFailureSource.lucratividadeMensalTrend,
            ),
          ],
          hubPresenceOnlineAgentIdsSnapshot:
              loaded.resolution.hubPresenceOnlineAgentIdsSnapshot,
          userRankingsOverride: batchUserRankingsOverride,
          userRankingRowsByAgentId: userRankingRowsByAgentId,
        );

        if (loaded.isFinal) {
          _logOverviewLoadTelemetry(
            userId: userId,
            policy: policy,
            loaded: loaded,
            report: report,
            overview: overview,
            batchResults: batchResults,
            period: period,
          );
          _scheduleFactsPrefetch(
            userId: userId,
            targets: loaded.plan.plannedTargets,
            dailyFilter: dailyTotalFilter,
            monthlyFilter: mensalFilter,
            hubPresenceOnlineAgentIdsSnapshot:
                loaded.resolution.hubPresenceOnlineAgentIdsSnapshot,
            bridgeTimeoutMs: loaded.plan.bridgeTimeoutMs,
            cancelScope: cancelScope,
            skipAgentIds: loaded.factsPersistedAgentIds,
          );
        }

        yield Success<OverviewProgressiveSnapshot, AppFailure>(
          _snapshotFor(
            overview: overview,
            completedSections: loaded.isFinal
                ? sectionRequest.completedWhenFinal()
                : sectionRequest.completedAfterMainBatch(),
            isFinal: loaded.isFinal,
          ),
        );
      }
    } on Object catch (error, stackTrace) {
      final failure = mapToAppFailure(
        error,
        stackTrace: stackTrace,
        fallbackMessage: 'Unable to load overview',
        fallbackUserMessage: 'Não foi possível carregar a visão geral.',
        context: <String, Object?>{
          'operation': 'loadOverview',
          'userId': userId,
          'policy': policy.name,
          OverviewFailureUiKey.field: OverviewFailureUiKey.loadFailed,
        },
      );
      final recovered = await _recoverOrFail(
        failure: failure,
        userId: userId,
        policy: policy,
        period: period,
        sourceAgentIds: _resolveFailureSourceAgentIds(
          failure,
          fallbackSelectedAgentIds: filter.selectedAgentIds,
        ),
        error: error,
        stackTrace: stackTrace,
      );
      yield _asProgressiveResult(recovered);
    }
  }

  List<OverviewMonthlyParcelPoint> _batchMonthlyPoints(
    List<OverviewBatchTargetResult> results,
    ResumoParcelasMensalFilter filter, {
    required bool sectionLoadFailed,
    required AgentQueryExecutionStrategy strategy,
  }) {
    if (sectionLoadFailed) {
      return const <OverviewMonthlyParcelPoint>[];
    }
    final report = _batchReport<ResumoParcelasMensalRow>(
      results,
      (result) => result.monthlyRows,
      (result) => result.monthlyFailure,
      queryKey: AgentQueryKey.resumoParcelasMensal,
      strategy: strategy,
    );
    return overviewMonthlyParcelPointsFromRows(
      report.chartRowsFilledPeriod(filter),
    );
  }

  List<OverviewWeekdaySalesTrendPoint> _batchWeekdayPoints(
    List<OverviewBatchTargetResult> results, {
    required AgentQueryExecutionStrategy strategy,
  }) {
    final report = _batchReport<ResumoParcelasDiaSemanaRow>(
      results,
      (result) => result.weekdayRows,
      (result) => result.weekdayFailure,
      queryKey: AgentQueryKey.resumoParcelasDiaSemana,
      strategy: strategy,
    );
    return overviewWeekdaySalesTrendPointsFromRows(report.chartRowsWeek);
  }

  List<DailySalesTrendPoint> _batchDailyPoints(
    List<OverviewBatchTargetResult> results,
    ResumoTotalDiarioVendasFilter filter, {
    required bool sectionLoadFailed,
    required AgentQueryExecutionStrategy strategy,
  }) {
    if (sectionLoadFailed) {
      return const <DailySalesTrendPoint>[];
    }
    final report = _batchReport<ResumoTotalDiarioVendasRow>(
      results,
      (result) => result.dailyRows,
      (result) => result.dailyFailure,
      queryKey: AgentQueryKey.resumoTotalDiarioVendas,
      strategy: strategy,
    );
    return dailySalesTrendPointsFromRows(
      report.chartRowsFilledPeriod(filter),
    );
  }

  List<OverviewWeekdayUserSalesTrendPoint> _batchWeekdayUserPoints(
    List<OverviewBatchTargetResult> results, {
    required AgentQueryExecutionStrategy strategy,
  }) {
    final report = _batchReport<ResumoParcelasDiaSemanaUsuarioRow>(
      results,
      (result) => result.weekdayUserRows,
      (result) => result.weekdayUserFailure,
      queryKey: AgentQueryKey.resumoParcelasDiaSemanaUsuario,
      strategy: strategy,
    );
    return overviewWeekdayUserSalesTrendPointsFromRows(
      report.aggregatedMergedRows,
    );
  }

  List<ResumoProdutoVendaLucratividadeRow> _batchLucratividadePoints(
    List<OverviewBatchTargetResult> results,
  ) {
    final rows = <ResumoProdutoVendaLucratividadeRow>[];
    for (final result in results) {
      if (result.lucratividadeFailure != null) {
        continue;
      }
      rows.add(
        _aggregateLucratividadeBranchesForAgent(
          branches: result.lucratividadeRows,
          chartAxisLabel: result.target.displayName,
        ),
      );
    }
    return rows;
  }

  List<ResumoProdutoVendaLucratividadeMensalRow> _batchLucratividadeMensalRows(
    List<OverviewBatchTargetResult> results,
  ) {
    return results
        .where((result) => result.lucratividadeMensalFailure == null)
        .expand((result) => result.lucratividadeMensalRows)
        .toList(growable: false);
  }

  /// Per-agent `ResumoParcelaPorUsuario` rows for agents that succeeded in
  /// both the main payment resumo and the user resumo. Agents with either
  /// failure are dropped so KPI/agent rankings track exactly the same scope
  /// as the user ranking card.
  Map<String, List<ResumoParcelaPorUsuarioRow>> _userRankingRowsByAgentId(
    List<OverviewBatchTargetResult> results,
  ) {
    final byAgent = <String, List<ResumoParcelaPorUsuarioRow>>{};
    for (final result in results) {
      if (result.mainFailure != null || result.userRankingFailure != null) {
        continue;
      }
      byAgent[result.target.agentId] = result.userRankingRows;
    }
    return byAgent;
  }

  List<String> _batchLucratividadePartialFailureAgentNames(
    List<OverviewBatchTargetResult> results,
  ) {
    final names =
        results
            .where((result) => result.lucratividadeFailure != null)
            .map((result) => result.target.displayName)
            .toList(growable: false)
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  List<OverviewAgentQueryFailureDetail>
  _batchLucratividadePartialFailureDetails(
    List<OverviewBatchTargetResult> results,
  ) {
    return _batchSectionPartialFailureDetails(
      results,
      failureOf: (result) => result.lucratividadeFailure,
      source: OverviewAgentQueryFailureSource.lucratividadePeriod,
    );
  }

  /// Generic per-section partial-failure mapper. Skips agents whose main
  /// resumo failed (those are surfaced via `paymentResumo` already) so the
  /// user does not see the same agent reported twice for a single batch.
  /// Output is sorted by display name for stable UI.
  List<OverviewAgentQueryFailureDetail> _batchSectionPartialFailureDetails(
    List<OverviewBatchTargetResult> results, {
    required AppFailure? Function(OverviewBatchTargetResult result) failureOf,
    required OverviewAgentQueryFailureSource source,
  }) {
    final details = <OverviewAgentQueryFailureDetail>[];
    for (final result in results) {
      if (result.mainFailure != null) {
        continue;
      }
      final failure = failureOf(result);
      if (failure == null) {
        continue;
      }
      details.add(
        overviewPartialFailureDetailForSource(
          agentId: result.target.agentId,
          displayName: result.target.displayName,
          failure: failure,
          source: source,
        ),
      );
    }
    details.sort(
      (a, b) => a.displayName.toLowerCase().compareTo(
        b.displayName.toLowerCase(),
      ),
    );
    return details;
  }

  AgentQueryExecutionReport<Row> _batchReport<Row>(
    List<OverviewBatchTargetResult> results,
    List<Row> Function(OverviewBatchTargetResult result) rowsOf,
    AppFailure? Function(OverviewBatchTargetResult result) failureOf, {
    required AgentQueryKey queryKey,
    required AgentQueryExecutionStrategy strategy,
  }) {
    return AgentQueryExecutionReport<Row>(
      queryKey: queryKey,
      strategy: strategy,
      consideredApprovedAgentCount: results.length,
      plannedTargets: results.map((result) => result.target).toList(),
      missingClientTokenTargets: const <AgentQueryTarget>[],
      totalElapsedMs: 0,
      participants: results
          .map(
            (result) => AgentQueryExecutionParticipant<Row>(
              agentId: result.target.agentId,
              displayName: result.target.displayName,
              rows: rowsOf(result),
              elapsedMs: result.elapsedMs,
              sourceRowCount: rowsOf(result).length,
              failure: failureOf(result),
            ),
          )
          .toList(growable: false),
    );
  }

  _OverviewBatchSectionFailure _batchSectionFailure(
    List<OverviewBatchTargetResult> results,
    AppFailure? Function(OverviewBatchTargetResult result) failureOf,
  ) {
    AppFailure? firstFailure;
    var hasFailure = false;
    var hasSuccess = false;
    for (final result in results) {
      final failure = failureOf(result);
      if (failure != null) {
        hasFailure = true;
        firstFailure ??= failure;
      } else {
        hasSuccess = true;
      }
    }
    if (hasFailure && !hasSuccess) {
      return _OverviewBatchSectionFailure(
        loadFailed: true,
        failure: firstFailure,
      );
    }
    return const _OverviewBatchSectionFailure(loadFailed: false);
  }

  AppResult<OverviewProgressiveSnapshot> _asProgressiveResult(
    AppResult<Overview> result,
  ) {
    return result.fold(
      (overview) => Success<OverviewProgressiveSnapshot, AppFailure>(
        _snapshotFor(
          overview: overview,
          completedSections: _allProgressiveSections,
          isFinal: true,
        ),
      ),
      Failure<OverviewProgressiveSnapshot, AppFailure>.new,
    );
  }

  OverviewProgressiveSnapshot _snapshotFor({
    required Overview overview,
    required Set<OverviewProgressiveSection> completedSections,
    required bool isFinal,
  }) {
    final completed =
        Set<OverviewProgressiveSection>.unmodifiable(completedSections);
    return OverviewProgressiveSnapshot(
      overview: overview,
      completedSections: completed,
      pendingSections: Set<OverviewProgressiveSection>.unmodifiable(
        _allProgressiveSections.difference(completed),
      ),
      isFinal: isFinal,
    );
  }

  /// Merge-all loads every planned agent in parallel and merges rows (required
  /// for consolidated KPIs). Race would keep only the first successful agent.
  /// Single-source when exactly one agent is selected.
  AgentQueryExecutionStrategy _resolveExecutionStrategy(
    DashboardFilter filter,
  ) {
    final selectedAgentIds = filter.selectedAgentIds;
    if (selectedAgentIds != null && selectedAgentIds.length == 1) {
      return AgentQueryExecutionStrategy.singleSource;
    }
    return AgentQueryExecutionStrategy.mergeAll;
  }

  ResumoProdutoVendaLucratividadeRow _aggregateLucratividadeBranchesForAgent({
    required List<ResumoProdutoVendaLucratividadeRow> branches,
    required String chartAxisLabel,
  }) {
    if (branches.isEmpty) {
      return ResumoProdutoVendaLucratividadeRow(
        codEmpresa: 0,
        codFilial: 0,
        qtdVendas: 0,
        qtdItensVendido: 0,
        valorTotalCustoMedio: 0,
        custoReposicao: 0,
        pontoEquilibrio: 0,
        valorTotalItem: 0,
        chartAxisLabel: chartAxisLabel,
      );
    }
    var qtdVendas = 0;
    var qtdItensVendido = 0.0;
    var valorTotalCustoMedio = 0.0;
    var custoReposicao = 0.0;
    var pontoEquilibrio = 0.0;
    var valorTotalItem = 0.0;
    for (final r in branches) {
      qtdVendas += r.qtdVendas;
      qtdItensVendido += r.qtdItensVendido;
      valorTotalCustoMedio += r.valorTotalCustoMedio;
      custoReposicao += r.custoReposicao;
      pontoEquilibrio += r.pontoEquilibrio;
      valorTotalItem += r.valorTotalItem;
    }
    // Multi-branch agents aggregate totals across filiais; codEmpresa/codFilial
    // are sentinel zeros so downstream code does not treat the first branch as
    // the sole scope. Use chartAxisLabel for display identity.
    return ResumoProdutoVendaLucratividadeRow(
      codEmpresa: 0,
      codFilial: 0,
      qtdVendas: qtdVendas,
      qtdItensVendido: qtdItensVendido,
      valorTotalCustoMedio: valorTotalCustoMedio,
      custoReposicao: custoReposicao,
      pontoEquilibrio: pontoEquilibrio,
      valorTotalItem: valorTotalItem,
      chartAxisLabel: chartAxisLabel,
    );
  }

  List<OverviewPaymentResumoRow> _mapOverviewRows(
    List<ResumoParcelaFormaPagamentoRowV2> rows,
  ) {
    return rows
        .map(overviewPaymentResumoRowFromResumoParcelaFormaPagamentoRowV2)
        .toList(growable: false);
  }

  Map<String, List<OverviewPaymentResumoRow>> _mapRowsByAgentId(
    Map<String, List<ResumoParcelaFormaPagamentoRowV2>> rowsByAgentId,
  ) {
    return <String, List<OverviewPaymentResumoRow>>{
      for (final entry in rowsByAgentId.entries)
        entry.key: _mapOverviewRows(entry.value),
    };
  }

  Map<String, String> _resolveAgentDisplayNames(
    AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRowV2> report,
  ) {
    return <String, String>{
      for (final target in report.plannedTargets)
        target.agentId: target.displayName,
      for (final target in report.missingClientTokenTargets)
        target.agentId: target.displayName,
    };
  }

  List<String> _resolveSourceAgentIds(
    AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRowV2> report,
  ) {
    final ids = <String>{
      for (final target in report.plannedTargets) target.agentId,
      for (final target in report.missingClientTokenTargets) target.agentId,
    }.toList(growable: false)..sort();
    return ids;
  }

  List<String>? _normalizeSelectedAgentIds(Set<String>? selectedAgentIds) {
    if (selectedAgentIds == null) {
      return null;
    }
    final ids =
        selectedAgentIds
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toList(growable: false)
          ..sort();
    return ids;
  }

  List<String>? _resolveFailureSourceAgentIds(
    AppFailure failure, {
    required Set<String>? fallbackSelectedAgentIds,
  }) {
    final rawSourceAgentIds = failure.context[_sourceAgentIdsContextField];
    if (rawSourceAgentIds is Iterable<Object?>) {
      final ids =
          rawSourceAgentIds
              .map((id) => id?.toString().trim() ?? '')
              .where((id) => id.isNotEmpty)
              .toList(growable: false)
            ..sort();
      return ids;
    }
    return _normalizeSelectedAgentIds(fallbackSelectedAgentIds);
  }

  AppFailure _mapOverviewFailure(
    AppFailure failure, {
    required String userId,
  }) {
    if (failure is ValidationFailure &&
        failure.context['reason'] == 'no_approved_agents') {
      return ValidationFailure(
        message: 'No approved agents available for overview',
        userMessage: failure.userMessage,
        cause: failure.cause ?? failure,
        stackTrace: failure.stackTrace,
        context: <String, Object?>{
          ...failure.context,
          'operation': 'loadOverview',
          'userId': userId,
          OverviewFailureUiKey.field: OverviewFailureUiKey.noApprovedAgents,
        },
      );
    }

    return failure;
  }

  void _logOverviewLoadTelemetry({
    required String userId,
    required OverviewLoadPolicy policy,
    required OverviewBatchLoadResult loaded,
    required AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRowV2> report,
    required Overview overview,
    required List<OverviewBatchTargetResult> batchResults,
    required _OverviewPeriod period,
  }) {
    var monthlySectionFailures = 0;
    var dailySectionFailures = 0;
    var weekdaySectionFailures = 0;
    var weekdayUserSectionFailures = 0;
    var lucratividadeSectionFailures = 0;
    var lucratividadeMensalSectionFailures = 0;
    for (final result in batchResults) {
      if (result.monthlyFailure != null) {
        monthlySectionFailures++;
      }
      if (result.dailyFailure != null) {
        dailySectionFailures++;
      }
      if (result.weekdayFailure != null) {
        weekdaySectionFailures++;
      }
      if (result.weekdayUserFailure != null) {
        weekdayUserSectionFailures++;
      }
      if (result.lucratividadeFailure != null) {
        lucratividadeSectionFailures++;
      }
      if (result.lucratividadeMensalFailure != null) {
        lucratividadeMensalSectionFailures++;
      }
    }

    AppLogger.info(
      'Overview loaded from agent query batch',
      context: <String, Object?>{
        'operation': 'loadOverview',
        'userId': userId,
        'policy': policy.name,
        'isFinal': loaded.isFinal,
        'consideredApprovedAgentCount': report.consideredApprovedAgentCount,
        'plannedTargetCount': loaded.plan.plannedTargets.length,
        'sqlEligibleConsideredTargetCount':
            loaded.resolution.sqlEligibleConsideredTargetCount,
        'periodStart': period.start.toIso8601String(),
        'periodEnd': period.end.toIso8601String(),
        'paymentMethods': overview.paymentMethods.length,
        'partialQueryFailures':
            overview.agentIdsExcludedFromQueryFailure.length,
        'agentsMissingClientToken': overview.agentIdsMissingClientToken.length,
        'batchElapsedMs': loaded.totalElapsedMs,
        'monthlySectionFailures': monthlySectionFailures,
        'dailySectionFailures': dailySectionFailures,
        'weekdaySectionFailures': weekdaySectionFailures,
        'weekdayUserSectionFailures': weekdayUserSectionFailures,
        'lucratividadeSectionFailures': lucratividadeSectionFailures,
        'lucratividadeMensalSectionFailures': lucratividadeMensalSectionFailures,
      },
    );
  }

  Future<AppResult<Overview>> _recoverOrFail({
    required AppFailure failure,
    required String userId,
    required OverviewLoadPolicy policy,
    required _OverviewPeriod period,
    required List<String>? sourceAgentIds,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    _logTerminalFailure(
      failure: failure,
      userId: userId,
      policy: policy,
      error: error ?? failure.cause ?? failure,
      stackTrace: stackTrace ?? failure.stackTrace,
    );
    return Failure<Overview, AppFailure>(failure);
  }

  void _logTerminalFailure({
    required AppFailure failure,
    required String userId,
    required OverviewLoadPolicy policy,
    required Object error,
    required StackTrace? stackTrace,
  }) {
    final context = <String, Object?>{
      'operation': 'loadOverview',
      'userId': userId,
      'policy': policy.name,
      'failureType': failure.runtimeType.toString(),
    };

    if (_isNoApprovedAgentsFailure(failure)) {
      AppLogger.info(
        'Overview unavailable: no approved agents',
        context: context,
      );
      return;
    }

    if (failure is ValidationFailure ||
        failure is SessionFailure ||
        failure is AuthorizationFailure) {
      AppLogger.warning(
        'Unable to load overview',
        context: context,
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }

    AppLogger.error(
      'Unable to load overview',
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  bool _isNoApprovedAgentsFailure(AppFailure failure) {
    return failure is ValidationFailure &&
        failure.context[OverviewFailureUiKey.field] ==
            OverviewFailureUiKey.noApprovedAgents;
  }

  Future<void> _invalidateOverviewCachedFacts({required String userId}) async {
    final factsStore = _factsStore;
    if (factsStore == null) {
      return;
    }
    await Future.wait([
      factsStore.removeMatchingFactKind(
        userId: userId,
        factKind: AgentQueryFactKind.dailySales,
      ),
      factsStore.removeMatchingFactKind(
        userId: userId,
        factKind: AgentQueryFactKind.monthlyParcels,
      ),
    ]);
  }

  void _scheduleFactsPrefetch({
    required String userId,
    required List<AgentQueryTarget> targets,
    required ResumoTotalDiarioVendasFilter dailyFilter,
    required ResumoParcelasMensalFilter monthlyFilter,
    required Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    required int bridgeTimeoutMs,
    AgentQueriesCancelScope? cancelScope,
    Set<String> skipAgentIds = const <String>{},
  }) {
    final coordinator = _factsPrefetchCoordinator;
    if (coordinator == null || targets.isEmpty) {
      return;
    }
    if (cancelScope?.isCancelled ?? false) {
      return;
    }
    unawaited(
      coordinator.prefetchForPlannedTargets(
        userId: userId,
        targets: targets,
        dailyFilter: dailyFilter,
        monthlyFilter: monthlyFilter,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        bridgeTimeoutMs: bridgeTimeoutMs,
        cancelScope: cancelScope,
        skipAgentIds: skipAgentIds,
      ),
    );
  }

  _OverviewPeriod _buildPeriod(DashboardFilter filter) {
    final rr = filter.referenceRange;
    if (rr != null) {
      final start = DateTime(
        rr.startInclusive.year,
        rr.startInclusive.month,
        rr.startInclusive.day,
      );
      // Mirror `DashboardYearMonth.end` semantics (microsecond precision):
      // last instant of the inclusive end day. SQL formatters truncate to
      // `yyyy-MM-dd`, so this only matters for in-process comparisons —
      // keep it consistent across the period builders so tests and cache
      // checks don't depend on a different millisecond/microsecond mix.
      final end = DateTime(
        rr.endInclusive.year,
        rr.endInclusive.month,
        rr.endInclusive.day + 1,
      ).subtract(const Duration(microseconds: 1));
      return _OverviewPeriod(start: start, end: end);
    }

    final yearMonth = filter.yearMonth;
    final DateTime start;
    final DateTime end;

    if (yearMonth != null) {
      start = yearMonth.start;
      end = yearMonth.end;
    } else {
      final now = _now();
      end = DateTime(now.year, now.month, now.day);
      start = end.subtract(const Duration(days: 29));
    }

    return _OverviewPeriod(start: start, end: end);
  }

}

class _OverviewPeriod {
  const _OverviewPeriod({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
}
