import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report_resumo_parcelas.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/overview/data/datasources/overview_local_datasource.dart';
import 'package:colmeia/features/overview/data/mappers/overview_agent_resumo_mapper.dart';
import 'package:colmeia/features/overview/data/mappers/overview_daily_sales_trend_mapper.dart';
import 'package:colmeia/features/overview/data/mappers/overview_monthly_parcel_mapper.dart';
import 'package:colmeia/features/overview/data/mappers/overview_user_ranking_mapper.dart';
import 'package:colmeia/features/overview/data/mappers/overview_weekday_sales_trend_mapper.dart';
import 'package:colmeia/features/overview/data/mappers/overview_weekday_user_sales_trend_mapper.dart';
import 'package:colmeia/features/overview/data/models/overview_model.dart';
import 'package:colmeia/features/overview/data/overview_batch_loader.dart';
import 'package:colmeia/features/overview/data/overview_user_rankings_override_policy.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_query_failure_detail.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_daily_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_monthly_parcel_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_resumo_row.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_user_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/overview_agent_query_failure_mapper.dart';
import 'package:colmeia/features/overview/domain/overview_failure_ui_key.dart';
import 'package:colmeia/features/overview/domain/overview_last_twelve_months_venda_range.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:result_dart/result_dart.dart';

/// When the overview falls back to cached KPIs because no agent could run the
/// main resumo (missing local `client_token`), keep chart payloads from cache
/// but preserve **this request's** resumo report metadata (partial failures,
/// skipped/offline agent ids) so alerts and diagnostics stay accurate.
Overview _overviewMergeCachedWithFreshReportSlice({
  required Overview cachedEntity,
  required Overview freshReportOverview,
}) {
  return cachedEntity.copyWith(
    partialQueryFailureDetails: freshReportOverview.partialQueryFailureDetails,
    hubPresenceOnlineAgentIdsSnapshot:
        freshReportOverview.hubPresenceOnlineAgentIdsSnapshot,
    agentIdsExcludedFromQueryFailure:
        freshReportOverview.agentIdsExcludedFromQueryFailure,
    agentNamesExcludedFromQueryFailure:
        freshReportOverview.agentNamesExcludedFromQueryFailure,
    agentIdsSkippedDueToHubPresence:
        freshReportOverview.agentIdsSkippedDueToHubPresence,
    agentNamesSkippedDueToHubPresence:
        freshReportOverview.agentNamesSkippedDueToHubPresence,
    mainResumoHadPlannedTargets:
        freshReportOverview.mainResumoHadPlannedTargets,
  );
}

class _OverviewBatchSectionFailure {
  const _OverviewBatchSectionFailure({
    required this.loadFailed,
    this.message,
  });

  final bool loadFailed;
  final String? message;
}

class OverviewRepositoryImpl implements OverviewRepository {
  OverviewRepositoryImpl({
    required OverviewLocalDataSource localDataSource,
    required OverviewBatchLoader batchLoader,
    DateTime Function()? now,
  }) : _localDataSource = localDataSource,
       _batchLoader = batchLoader,
       _now = now ?? DateTime.now;

  final OverviewLocalDataSource _localDataSource;
  final OverviewBatchLoader _batchLoader;
  final DateTime Function() _now;

  static const String _sourceAgentIdsContextField = 'sourceAgentIds';
  static const Duration _overviewCacheMaxAge = Duration(hours: 48);

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

  static const Set<OverviewProgressiveSection> _summaryProgressiveSections =
      <OverviewProgressiveSection>{
        OverviewProgressiveSection.summary,
        OverviewProgressiveSection.paymentMix,
        OverviewProgressiveSection.agentRanking,
        OverviewProgressiveSection.userRanking,
      };

  @override
  Future<AppResult<Overview>> loadOverview({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    OverviewFilter filter = const OverviewFilter(),
    OverviewLoadLabels? rowLabels,
  }) async {
    AppResult<Overview>? lastResult;
    await for (final result in loadOverviewProgressively(
      userId: userId,
      policy: policy,
      filter: filter,
      rowLabels: rowLabels,
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
            userMessage: 'Unable to load the overview.',
          ),
        );
  }

  @override
  Stream<AppResult<OverviewProgressiveSnapshot>> loadOverviewProgressively({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    OverviewFilter filter = const OverviewFilter(),
    OverviewLoadLabels? rowLabels,
  }) async* {
    yield* _loadOverviewProgressivelyBatch(
      userId: userId,
      policy: policy,
      filter: filter,
      rowLabels: rowLabels,
    );
  }

  Stream<AppResult<OverviewProgressiveSnapshot>>
  _loadOverviewProgressivelyBatch({
    required String userId,
    required OverviewLoadPolicy policy,
    required OverviewFilter filter,
    OverviewLoadLabels? rowLabels,
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
        final successfulMainResults = batchResults
            .where((result) => result.mainFailure == null)
            .toList(growable: false);
        if (loaded.plan.plannedTargets.isNotEmpty &&
            successfulMainResults.isEmpty) {
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

        var shouldSaveFinalOverview = report.consideredApprovedAgentCount > 0;
        final batchUserRankingsOverride =
            overviewUserRankingsOverrideFromBatchTargetResults(
              batchResults: batchResults,
              paymentMergedRows: report.mergedRows,
              userId: userId,
              rowLabels: resolvedRowLabels,
              operation: 'loadOverviewProgressivelyBatch',
            );
        var overview = _buildOverview(
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
          ),
          monthlyParcelTrendLoadFailed: _batchSectionFailure(
            batchResults,
            (result) => result.monthlyFailure,
          ).loadFailed,
          monthlyParcelTrendLoadFailureMessage: _batchSectionFailure(
            batchResults,
            (result) => result.monthlyFailure,
          ).message,
          weekdaySalesTrend: _batchWeekdayPoints(batchResults),
          weekdaySalesTrendLoadFailed: _batchSectionFailure(
            batchResults,
            (result) => result.weekdayFailure,
          ).loadFailed,
          weekdaySalesTrendLoadFailureMessage: _batchSectionFailure(
            batchResults,
            (result) => result.weekdayFailure,
          ).message,
          dailySalesTrend: _batchDailyPoints(batchResults, dailyTotalFilter),
          dailySalesTrendLoadFailed: _batchSectionFailure(
            batchResults,
            (result) => result.dailyFailure,
          ).loadFailed,
          dailySalesTrendLoadFailureMessage: _batchSectionFailure(
            batchResults,
            (result) => result.dailyFailure,
          ).message,
          weekdayUserSalesTrend: _batchWeekdayUserPoints(batchResults),
          weekdayUserSalesTrendLoadFailed: _batchSectionFailure(
            batchResults,
            (result) => result.weekdayUserFailure,
          ).loadFailed,
          weekdayUserSalesTrendLoadFailureMessage: _batchSectionFailure(
            batchResults,
            (result) => result.weekdayUserFailure,
          ).message,
          lucratividadeTrend: _batchLucratividadePoints(batchResults),
          lucratividadeTrendLoadFailed: _batchSectionFailure(
            batchResults,
            (result) => result.lucratividadeFailure,
          ).loadFailed,
          lucratividadeTrendLoadFailureMessage: _batchSectionFailure(
            batchResults,
            (result) => result.lucratividadeFailure,
          ).message,
          lucratividadePartialFailureAgentNames:
              _batchLucratividadePartialFailureAgentNames(batchResults),
          lucratividadeMensalTrend: _batchLucratividadeMensalRows(batchResults),
          lucratividadeMensalTrendLoadFailed: _batchSectionFailure(
            batchResults,
            (result) => result.lucratividadeMensalFailure,
          ).loadFailed,
          lucratividadeMensalTrendLoadFailureMessage: _batchSectionFailure(
            batchResults,
            (result) => result.lucratividadeMensalFailure,
          ).message,
          mainResumoHadPlannedTargets: report.plannedTargets.isNotEmpty,
          partialQueryFailureDetails: <OverviewAgentQueryFailureDetail>[
            ...overviewPartialFailuresFromParticipants(report.participants),
            ..._batchLucratividadePartialFailureDetails(batchResults),
          ],
          hubPresenceOnlineAgentIdsSnapshot:
              loaded.resolution.hubPresenceOnlineAgentIdsSnapshot,
          userRankingsOverride: batchUserRankingsOverride,
        );

        if (report.requiresClientTokenSetup && sourceAgentIds != null) {
          final freshReportOverview = overview;
          final cachedEntity = await _readCachedOverviewForMissingClientTokens(
            userId: userId,
            policy: policy,
            period: period,
            expectedSortedAgentIds: sourceAgentIds,
            agentIdsMissingClientToken: report.missingClientTokenAgentIds,
            agentNamesMissingClientToken: report.missingClientTokenAgentNames,
          );
          if (cachedEntity != null) {
            overview = _overviewMergeCachedWithFreshReportSlice(
              cachedEntity: cachedEntity,
              freshReportOverview: freshReportOverview,
            );
            shouldSaveFinalOverview = false;
          }
        }

        if (loaded.isFinal &&
            shouldSaveFinalOverview &&
            sourceAgentIds != null) {
          await _saveOverviewCache(
            userId: userId,
            overview: overview,
            sourceAgentIds: sourceAgentIds,
          );
        }

        if (loaded.isFinal) {
          AppLogger.info(
            'Overview loaded from agent query batch',
            context: <String, Object?>{
              'operation': 'loadOverview',
              'userId': userId,
              'agentCount': report.consideredApprovedAgentCount,
              'plannedAgentCount': report.plannedTargets.length,
              'periodStart': period.start.toIso8601String(),
              'periodEnd': period.end.toIso8601String(),
              'paymentMethods': overview.paymentMethods.length,
              'partialQueryFailures':
                  overview.agentIdsExcludedFromQueryFailure.length,
              'agentsMissingClientToken':
                  overview.agentIdsMissingClientToken.length,
              'batchElapsedMs': loaded.totalElapsedMs,
            },
          );
        }

        yield Success<OverviewProgressiveSnapshot, AppFailure>(
          _snapshotFor(
            overview: overview,
            completedSections: loaded.isFinal
                ? _allProgressiveSections
                : _summaryProgressiveSections,
            isFinal: loaded.isFinal,
          ),
        );
      }
    } on Object catch (error, stackTrace) {
      final failure = mapToAppFailure(
        error,
        stackTrace: stackTrace,
        fallbackMessage: 'Unable to load overview',
        fallbackUserMessage: 'Unable to load the overview.',
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
    ResumoParcelasMensalFilter filter,
  ) {
    final report = _batchReport<ResumoParcelasMensalRow>(
      results,
      (result) => result.monthlyRows,
      (result) => result.monthlyFailure,
    );
    return overviewMonthlyParcelPointsFromRows(
      report.chartRowsFilledPeriod(filter),
    );
  }

  List<OverviewWeekdaySalesTrendPoint> _batchWeekdayPoints(
    List<OverviewBatchTargetResult> results,
  ) {
    final report = _batchReport<ResumoParcelasDiaSemanaRow>(
      results,
      (result) => result.weekdayRows,
      (result) => result.weekdayFailure,
    );
    return overviewWeekdaySalesTrendPointsFromRows(report.chartRowsWeek);
  }

  List<OverviewDailySalesTrendPoint> _batchDailyPoints(
    List<OverviewBatchTargetResult> results,
    ResumoTotalDiarioVendasFilter filter,
  ) {
    final report = _batchReport<ResumoTotalDiarioVendasRow>(
      results,
      (result) => result.dailyRows,
      (result) => result.dailyFailure,
    );
    return overviewDailySalesTrendPointsFromRows(
      report.chartRowsFilledPeriod(filter),
    );
  }

  List<OverviewWeekdayUserSalesTrendPoint> _batchWeekdayUserPoints(
    List<OverviewBatchTargetResult> results,
  ) {
    final report = _batchReport<ResumoParcelasDiaSemanaUsuarioRow>(
      results,
      (result) => result.weekdayUserRows,
      (result) => result.weekdayUserFailure,
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
    final details = <OverviewAgentQueryFailureDetail>[];
    for (final result in results) {
      final failure = result.lucratividadeFailure;
      if (failure == null) {
        continue;
      }
      details.add(
        overviewLucratividadePartialFailureDetail(
          agentId: result.target.agentId,
          displayName: result.target.displayName,
          failure: failure,
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
    AppFailure? Function(OverviewBatchTargetResult result) failureOf,
  ) {
    return AgentQueryExecutionReport<Row>(
      queryKey: AgentQueryKey.resumoParcelaFormaPagamento,
      strategy: _resolveExecutionStrategy(const OverviewFilter()),
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
    String? firstFailureMessage;
    var hasFailure = false;
    var hasSuccess = false;
    for (final result in results) {
      final failure = failureOf(result);
      if (failure != null) {
        hasFailure = true;
        firstFailureMessage ??= failure.userMessage;
      } else {
        hasSuccess = true;
      }
    }
    if (hasFailure && !hasSuccess) {
      return _OverviewBatchSectionFailure(
        loadFailed: true,
        message: firstFailureMessage,
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
    final completed = isFinal
        ? _allProgressiveSections
        : Set<OverviewProgressiveSection>.unmodifiable(completedSections);
    return OverviewProgressiveSnapshot(
      overview: overview,
      completedSections: completed,
      pendingSections: Set<OverviewProgressiveSection>.unmodifiable(
        _allProgressiveSections.difference(completed),
      ),
      isFinal: isFinal,
    );
  }

  Future<void> _saveOverviewCache({
    required String userId,
    required Overview overview,
    required List<String> sourceAgentIds,
  }) async {
    final model = OverviewModel.fromEntity(
      overview,
      cachedAt: _now(),
      sourceAgentIds: sourceAgentIds,
    );

    try {
      await _localDataSource.saveOverview(userId: userId, overview: model);
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Overview cache save failed; returning computed overview',
        context: <String, Object?>{
          'operation': 'loadOverview',
          'userId': userId,
        },
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Merge-all loads every planned agent in parallel and merges rows (required
  /// for consolidated KPIs). Race would keep only the first successful agent.
  /// Single-source when exactly one agent is selected.
  AgentQueryExecutionStrategy _resolveExecutionStrategy(
    OverviewFilter filter,
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
    final head = branches.first;
    return ResumoProdutoVendaLucratividadeRow(
      codEmpresa: head.codEmpresa,
      codFilial: head.codFilial,
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
    List<ResumoParcelaFormaPagamentoRow> rows,
  ) {
    return rows
        .map(overviewPaymentResumoRowFromAgentRow)
        .toList(growable: false);
  }

  Map<String, List<OverviewPaymentResumoRow>> _mapRowsByAgentId(
    Map<String, List<ResumoParcelaFormaPagamentoRow>> rowsByAgentId,
  ) {
    return <String, List<OverviewPaymentResumoRow>>{
      for (final entry in rowsByAgentId.entries)
        entry.key: _mapOverviewRows(entry.value),
    };
  }

  Map<String, String> _resolveAgentDisplayNames(
    AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow> report,
  ) {
    return <String, String>{
      for (final target in report.plannedTargets)
        target.agentId: target.displayName,
      for (final target in report.missingClientTokenTargets)
        target.agentId: target.displayName,
    };
  }

  List<String> _resolveSourceAgentIds(
    AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow> report,
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

  Future<AppResult<Overview>> _recoverOrFail({
    required AppFailure failure,
    required String userId,
    required OverviewLoadPolicy policy,
    required _OverviewPeriod period,
    required List<String>? sourceAgentIds,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    final cachedOverview = await _readCachedOverviewIfAllowed(
      userId: userId,
      policy: policy,
      failure: failure,
      period: period,
      expectedSortedAgentIds: sourceAgentIds,
      error: error ?? failure.cause ?? failure,
      stackTrace: stackTrace ?? failure.stackTrace ?? StackTrace.current,
    );
    if (cachedOverview != null) {
      return Success<Overview, AppFailure>(
        cachedOverview.toEntity(isStaleCache: true),
      );
    }

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

  Future<OverviewModel?> _readCachedOverviewIfAllowed({
    required String userId,
    required OverviewLoadPolicy policy,
    required AppFailure failure,
    required _OverviewPeriod period,
    required List<String>? expectedSortedAgentIds,
    required Object error,
    required StackTrace stackTrace,
  }) async {
    if (!_shouldFallbackToCache(policy: policy, failure: failure)) {
      return null;
    }

    final cachedOverview = await _localDataSource.readOverview(userId: userId);
    if (cachedOverview == null) {
      return null;
    }

    if (!_isCacheAcceptable(
      cached: cachedOverview,
      period: period,
      expectedSortedAgentIds: expectedSortedAgentIds,
    )) {
      return null;
    }

    final warningContext = <String, Object?>{
      'operation': 'loadOverview',
      'userId': userId,
      'policy': policy.name,
      'failureType': failure.runtimeType.toString(),
    };
    if (cachedOverview.sourceAgentIds == null) {
      warningContext['legacyCacheMissingAgentSignature'] = true;
    }

    AppLogger.warning(
      'Overview fallback to cached data',
      context: warningContext,
      error: error,
      stackTrace: stackTrace,
    );
    return cachedOverview;
  }

  Future<Overview?> _readCachedOverviewForMissingClientTokens({
    required String userId,
    required OverviewLoadPolicy policy,
    required _OverviewPeriod period,
    required List<String> expectedSortedAgentIds,
    required List<String> agentIdsMissingClientToken,
    required List<String> agentNamesMissingClientToken,
  }) async {
    final cachedOverview = await _localDataSource.readOverview(userId: userId);
    if (cachedOverview == null) {
      return null;
    }

    if (!_isCacheAcceptable(
      cached: cachedOverview,
      period: period,
      expectedSortedAgentIds: expectedSortedAgentIds,
    )) {
      return null;
    }

    AppLogger.warning(
      policy == OverviewLoadPolicy.forceRefresh
          ? 'Overview fallback to cached data (missing local client_token; '
                'force refresh cannot run queries)'
          : 'Overview fallback to cached data (missing local client token)',
      context: <String, Object?>{
        'operation': 'loadOverview',
        'userId': userId,
        'policy': policy.name,
        'missingTokenCount': agentIdsMissingClientToken.length,
        'missingTokenAgentIds': agentIdsMissingClientToken.join(', '),
      },
    );

    return cachedOverview
        .toEntity(isStaleCache: true)
        .copyWith(
          approvedAgentCount: expectedSortedAgentIds.length,
          agentIdsMissingClientToken: agentIdsMissingClientToken,
          agentNamesMissingClientToken: agentNamesMissingClientToken,
        );
  }

  bool _isCacheAcceptable({
    required OverviewModel cached,
    required _OverviewPeriod period,
    required List<String>? expectedSortedAgentIds,
  }) {
    if (!_sameCalendarDay(cached.periodStart, period.start) ||
        !_sameCalendarDay(cached.periodEnd, period.end)) {
      return false;
    }

    if (cached.cachedAt != null) {
      final age = _now().difference(cached.cachedAt!);
      if (age > _overviewCacheMaxAge) {
        return false;
      }
    }

    if (expectedSortedAgentIds != null) {
      if (cached.sourceAgentIds == null) {
        return false;
      }
      final actual = List<String>.from(cached.sourceAgentIds!)..sort();
      final expected = List<String>.from(expectedSortedAgentIds)..sort();
      if (!_listEquals(expected, actual)) {
        return false;
      }
    }

    return true;
  }

  static bool _sameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  bool _shouldFallbackToCache({
    required OverviewLoadPolicy policy,
    required AppFailure failure,
  }) {
    if (policy == OverviewLoadPolicy.forceRefresh) {
      return false;
    }
    if (failure is ValidationFailure ||
        failure is SessionFailure ||
        failure is AuthorizationFailure) {
      return false;
    }
    if (failure case RpcFailure(:final retryable)) {
      return retryable;
    }
    return failure.isTransient || failure is UnknownFailure;
  }

  bool _isNoApprovedAgentsFailure(AppFailure failure) {
    return failure is ValidationFailure &&
        failure.context[OverviewFailureUiKey.field] ==
            OverviewFailureUiKey.noApprovedAgents;
  }

  _OverviewPeriod _buildPeriod(OverviewFilter filter) {
    final rr = filter.referenceRange;
    if (rr != null) {
      final start = DateTime(
        rr.startInclusive.year,
        rr.startInclusive.month,
        rr.startInclusive.day,
      );
      final end = DateTime(
        rr.endInclusive.year,
        rr.endInclusive.month,
        rr.endInclusive.day,
        23,
        59,
        59,
        999,
      );
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

  Overview _buildOverview(
    List<OverviewPaymentResumoRow> rows, {
    required Map<String, List<OverviewPaymentResumoRow>> rowsByAgentId,
    required Map<String, String> agentDisplayNamesById,
    required DateTime periodStart,
    required DateTime periodEnd,
    required int approvedAgentCount,
    required OverviewLoadLabels rowLabels,
    List<String> agentIdsExcludedFromQueryFailure = const <String>[],
    List<String> agentNamesExcludedFromQueryFailure = const <String>[],
    List<String> agentIdsMissingClientToken = const <String>[],
    List<String> agentNamesMissingClientToken = const <String>[],
    List<String> agentIdsSkippedDueToHubPresence = const <String>[],
    List<String> agentNamesSkippedDueToHubPresence = const <String>[],
    List<OverviewMonthlyParcelPoint> monthlyParcelTrend =
        const <OverviewMonthlyParcelPoint>[],
    bool monthlyParcelTrendLoadFailed = false,
    String? monthlyParcelTrendLoadFailureMessage,
    List<OverviewWeekdaySalesTrendPoint> weekdaySalesTrend =
        const <OverviewWeekdaySalesTrendPoint>[],
    bool weekdaySalesTrendLoadFailed = false,
    String? weekdaySalesTrendLoadFailureMessage,
    List<OverviewDailySalesTrendPoint> dailySalesTrend =
        const <OverviewDailySalesTrendPoint>[],
    bool dailySalesTrendLoadFailed = false,
    String? dailySalesTrendLoadFailureMessage,
    List<OverviewWeekdayUserSalesTrendPoint> weekdayUserSalesTrend =
        const <OverviewWeekdayUserSalesTrendPoint>[],
    bool weekdayUserSalesTrendLoadFailed = false,
    String? weekdayUserSalesTrendLoadFailureMessage,
    List<ResumoProdutoVendaLucratividadeMensalRow> lucratividadeMensalTrend =
        const <ResumoProdutoVendaLucratividadeMensalRow>[],
    bool lucratividadeMensalTrendLoadFailed = false,
    String? lucratividadeMensalTrendLoadFailureMessage,
    List<ResumoProdutoVendaLucratividadeRow> lucratividadeTrend =
        const <ResumoProdutoVendaLucratividadeRow>[],
    bool lucratividadeTrendLoadFailed = false,
    String? lucratividadeTrendLoadFailureMessage,
    List<String> lucratividadePartialFailureAgentNames = const <String>[],
    bool mainResumoHadPlannedTargets = false,
    List<OverviewAgentQueryFailureDetail> partialQueryFailureDetails =
        const <OverviewAgentQueryFailureDetail>[],
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    List<OverviewUserRanking>? userRankingsOverride,
  }) {
    final paymentBuckets = <String, _PaymentMethodAggregate>{};
    final userBuckets = <String, _UserAggregate>{};

    var totalSalesCount = 0;
    var totalAmount = 0.0;

    for (final row in rows) {
      totalSalesCount += row.qtdVendas;
      totalAmount += row.valorParcela;

      final paymentKey =
          '${row.codFormaPagamento.trim()}'
          '|${row.descricaoFormaPagamento.trim()}';
      paymentBuckets
          .putIfAbsent(
            paymentKey,
            () => _PaymentMethodAggregate(
              code: row.codFormaPagamento.trim(),
              label: _resolvePaymentMethodLabel(row, rowLabels),
            ),
          )
          .add(row.qtdVendas, row.valorParcela);

      if (userRankingsOverride == null) {
        final userKey = overviewUserRankingNormalizeKey(
          row.nomeUsuario,
          rowLabels,
        );
        userBuckets
            .putIfAbsent(
              userKey,
              () => _UserAggregate(
                userName: overviewUserRankingDisplayName(
                  row.nomeUsuario,
                  rowLabels,
                ),
              ),
            )
            .add(row.qtdVendas, row.valorParcela);
      }
    }

    final paymentMethods =
        paymentBuckets.values
            .map(
              (item) => OverviewPaymentMethodBreakdown(
                code: item.code,
                label: item.label,
                totalSalesCount: item.totalSalesCount,
                totalAmount: item.totalAmount,
                averageTicket: item.averageTicket,
                sharePercent: totalAmount <= 0
                    ? 0
                    : item.totalAmount / totalAmount * 100,
              ),
            )
            .toList(growable: false)
          ..sort(_compareBreakdowns);

    final agentRankings =
        rowsByAgentId.entries
            .map((entry) {
              final agentId = entry.key;
              var sales = 0;
              var amount = 0.0;
              for (final row in entry.value) {
                sales += row.qtdVendas;
                amount += row.valorParcela;
              }
              return OverviewAgentRanking(
                agentId: agentId,
                displayName: agentDisplayNamesById[agentId] ?? agentId.trim(),
                totalSalesCount: sales,
                totalAmount: amount,
              );
            })
            .toList(growable: false)
          ..sort(_compareAgents);

    final userRankings =
        userRankingsOverride ??
        userBuckets.values
            .map(
              (item) => OverviewUserRanking(
                userName: item.userName,
                totalSalesCount: item.totalSalesCount,
                totalAmount: item.totalAmount,
                averageTicket: item.averageTicket,
              ),
            )
            .toList(growable: false)
          ..sort(_compareUsers);

    return Overview(
      periodStart: periodStart,
      periodEnd: periodEnd,
      kpis: OverviewPaymentKpis(
        totalSalesCount: totalSalesCount,
        totalAmount: totalAmount,
        averageTicket: totalSalesCount == 0 ? 0 : totalAmount / totalSalesCount,
        paymentMethodCount: paymentMethods.length,
      ),
      paymentMethods: paymentMethods,
      agentRankings: agentRankings,
      userRankings: userRankings,
      monthlyParcelTrend: monthlyParcelTrend,
      monthlyParcelTrendLoadFailed: monthlyParcelTrendLoadFailed,
      monthlyParcelTrendLoadFailureMessage:
          monthlyParcelTrendLoadFailureMessage,
      weekdaySalesTrend: weekdaySalesTrend,
      weekdaySalesTrendLoadFailed: weekdaySalesTrendLoadFailed,
      weekdaySalesTrendLoadFailureMessage: weekdaySalesTrendLoadFailureMessage,
      dailySalesTrend: dailySalesTrend,
      dailySalesTrendLoadFailed: dailySalesTrendLoadFailed,
      dailySalesTrendLoadFailureMessage: dailySalesTrendLoadFailureMessage,
      weekdayUserSalesTrend: weekdayUserSalesTrend,
      weekdayUserSalesTrendLoadFailed: weekdayUserSalesTrendLoadFailed,
      weekdayUserSalesTrendLoadFailureMessage:
          weekdayUserSalesTrendLoadFailureMessage,
      lucratividadeMensalTrend: lucratividadeMensalTrend,
      lucratividadeMensalTrendLoadFailed: lucratividadeMensalTrendLoadFailed,
      lucratividadeMensalTrendLoadFailureMessage:
          lucratividadeMensalTrendLoadFailureMessage,
      lucratividadeTrend: lucratividadeTrend,
      lucratividadeTrendLoadFailed: lucratividadeTrendLoadFailed,
      lucratividadeTrendLoadFailureMessage:
          lucratividadeTrendLoadFailureMessage,
      lucratividadePartialFailureAgentNames:
          lucratividadePartialFailureAgentNames,
      approvedAgentCount: approvedAgentCount,
      agentIdsExcludedFromQueryFailure: agentIdsExcludedFromQueryFailure,
      agentNamesExcludedFromQueryFailure: agentNamesExcludedFromQueryFailure,
      agentIdsMissingClientToken: agentIdsMissingClientToken,
      agentNamesMissingClientToken: agentNamesMissingClientToken,
      agentIdsSkippedDueToHubPresence: agentIdsSkippedDueToHubPresence,
      agentNamesSkippedDueToHubPresence: agentNamesSkippedDueToHubPresence,
      mainResumoHadPlannedTargets: mainResumoHadPlannedTargets,
      partialQueryFailureDetails: partialQueryFailureDetails,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
    );
  }

  String _resolvePaymentMethodLabel(
    OverviewPaymentResumoRow row,
    OverviewLoadLabels labels,
  ) {
    final description = row.descricaoFormaPagamento.trim();
    if (description.isNotEmpty) {
      return description;
    }
    final code = row.codFormaPagamento.trim();
    return code.isEmpty ? labels.unknownPaymentMethodLabel : code;
  }

  static int _compareBreakdowns(
    OverviewPaymentMethodBreakdown left,
    OverviewPaymentMethodBreakdown right,
  ) {
    final amount = right.totalAmount.compareTo(left.totalAmount);
    if (amount != 0) {
      return amount;
    }
    final sales = right.totalSalesCount.compareTo(left.totalSalesCount);
    if (sales != 0) {
      return sales;
    }
    return left.label.compareTo(right.label);
  }

  static int _compareAgents(
    OverviewAgentRanking left,
    OverviewAgentRanking right,
  ) {
    final amount = right.totalAmount.compareTo(left.totalAmount);
    if (amount != 0) {
      return amount;
    }
    final sales = right.totalSalesCount.compareTo(left.totalSalesCount);
    if (sales != 0) {
      return sales;
    }
    return left.displayName.compareTo(right.displayName);
  }

  static int _compareUsers(
    OverviewUserRanking left,
    OverviewUserRanking right,
  ) {
    final amount = right.totalAmount.compareTo(left.totalAmount);
    if (amount != 0) {
      return amount;
    }
    final sales = right.totalSalesCount.compareTo(left.totalSalesCount);
    if (sales != 0) {
      return sales;
    }
    return left.userName.compareTo(right.userName);
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

class _PaymentMethodAggregate {
  _PaymentMethodAggregate({
    required this.code,
    required this.label,
  });

  final String code;
  final String label;
  int totalSalesCount = 0;
  double totalAmount = 0;

  double get averageTicket =>
      totalSalesCount == 0 ? 0 : totalAmount / totalSalesCount;

  void add(int salesCount, double amount) {
    totalSalesCount += salesCount;
    totalAmount += amount;
  }
}

class _UserAggregate {
  _UserAggregate({required this.userName});

  final String userName;
  int totalSalesCount = 0;
  double totalAmount = 0;

  double get averageTicket =>
      totalSalesCount == 0 ? 0 : totalAmount / totalSalesCount;

  void add(int salesCount, double amount) {
    totalSalesCount += salesCount;
    totalAmount += amount;
  }
}
