import 'dart:async';

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/sync/agent_query_facts_prefetch_coordinator.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_fact_kind.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_store.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/overview/data/overview_agent_query_load_policy_mapper.dart';
import 'package:colmeia/features/overview/data/overview_batch_assembler.dart';
import 'package:colmeia/features/overview/data/overview_batch_loader.dart';
import 'package:colmeia/features/overview/data/overview_batch_section_mapper.dart';
import 'package:colmeia/features/overview/data/overview_repository_support.dart';
import 'package:colmeia/features/overview/data/overview_user_rankings_override_policy.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_query_failure_detail.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/entities/overview_section_request.dart';
import 'package:colmeia/features/overview/domain/overview_agent_query_failure_mapper.dart';
import 'package:colmeia/features/overview/domain/overview_failure_ui_key.dart';
import 'package:colmeia/features/overview/domain/overview_last_twelve_months_venda_range.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:result_dart/result_dart.dart';

class OverviewRepositoryImpl implements OverviewRepository {
  OverviewRepositoryImpl({
    required OverviewBatchLoader batchLoader,
    AgentQueryFactsStore? factsStore,
    AgentQueryFactsPrefetchCoordinator? factsPrefetchCoordinator,
    DateTime Function()? now,
    OverviewBatchAssembler assembler = const OverviewBatchAssembler(),
    OverviewBatchSectionMapper sectionMapper =
        const OverviewBatchSectionMapper(),
  }) : _batchLoader = batchLoader,
       _factsStore = factsStore,
       _factsPrefetchCoordinator = factsPrefetchCoordinator,
       _now = now ?? DateTime.now,
       _assembler = assembler,
       _sectionMapper = sectionMapper;

  final OverviewBatchLoader _batchLoader;
  final AgentQueryFactsStore? _factsStore;
  final AgentQueryFactsPrefetchCoordinator? _factsPrefetchCoordinator;
  final DateTime Function() _now;
  final OverviewBatchAssembler _assembler;
  final OverviewBatchSectionMapper _sectionMapper;

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
    final period = buildOverviewPeriod(filter, now: _now);
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
    final executionStrategy = resolveOverviewExecutionStrategy(filter);
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
          final failure = mapOverviewFailure(
            loadResult.exceptionOrNull()!,
            userId: userId,
          );
          final recovered = await recoverOverviewOrFail(
            failure: failure,
            userId: userId,
            policy: policy,
          );
          yield asOverviewProgressiveResult(recovered);
          return;
        }

        final batchResults = loaded.targetResults;
        final report = loaded.mainResumoReport;

        if (loaded.completedWithOnlyTargetFailures) {
          final firstMainFailure = batchResults
              .map((result) => result.mainFailure)
              .whereType<AppFailure>()
              .first;
          final failure = mapOverviewFailure(
            firstMainFailure,
            userId: userId,
          );
          final recovered = await recoverOverviewOrFail(
            failure: failure,
            userId: userId,
            policy: policy,
          );
          yield asOverviewProgressiveResult(recovered);
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
        final userRankingRowsByAgentId = batchUserRankingsOverride == null
            ? null
            : _sectionMapper.userRankingRowsByAgentId(batchResults);
        final mainSectionFailure = _sectionMapper.sectionFailure(
          batchResults,
          (result) => result.mainFailure,
        );
        final monthlySectionFailure = _sectionMapper.sectionFailure(
          batchResults,
          (result) => result.monthlyFailure,
        );
        final weekdaySectionFailure = _sectionMapper.sectionFailure(
          batchResults,
          (result) => result.weekdayFailure,
        );
        final dailySectionFailure = _sectionMapper.sectionFailure(
          batchResults,
          (result) => result.dailyFailure,
        );
        final weekdayUserSectionFailure = _sectionMapper.sectionFailure(
          batchResults,
          (result) => result.weekdayUserFailure,
        );
        final lucratividadeSectionFailure = _sectionMapper.sectionFailure(
          batchResults,
          (result) => result.lucratividadeFailure,
        );
        final overview = _assembler.buildOverview(
          _sectionMapper.mapOverviewRows(report.mergedRows),
          rowsByAgentId: _sectionMapper.mapRowsByAgentId(report.rowsByAgentId),
          agentDisplayNamesById: resolveAgentDisplayNames(report),
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
          monthlyParcelTrend: _sectionMapper.monthlyPoints(
            batchResults,
            mensalFilter,
            sectionLoadFailed: monthlySectionFailure.loadFailed,
            strategy: executionStrategy,
          ),
          monthlyParcelTrendLoadFailed: monthlySectionFailure.loadFailed,
          monthlyParcelTrendLoadFailure: monthlySectionFailure.failure,
          weekdaySalesTrend: _sectionMapper.weekdayPoints(
            batchResults,
            strategy: executionStrategy,
          ),
          weekdaySalesTrendLoadFailed: weekdaySectionFailure.loadFailed,
          weekdaySalesTrendLoadFailure: weekdaySectionFailure.failure,
          dailySalesTrend: _sectionMapper.dailyPoints(
            batchResults,
            dailyTotalFilter,
            sectionLoadFailed: dailySectionFailure.loadFailed,
            strategy: executionStrategy,
          ),
          dailySalesTrendLoadFailed: dailySectionFailure.loadFailed,
          dailySalesTrendLoadFailure: dailySectionFailure.failure,
          weekdayUserSalesTrend: _sectionMapper.weekdayUserPoints(
            batchResults,
            strategy: executionStrategy,
          ),
          weekdayUserSalesTrendLoadFailed: weekdayUserSectionFailure.loadFailed,
          weekdayUserSalesTrendLoadFailure: weekdayUserSectionFailure.failure,
          lucratividadeTrend: _sectionMapper.lucratividadePoints(batchResults),
          lucratividadeTrendLoadFailed: lucratividadeSectionFailure.loadFailed,
          lucratividadeTrendLoadFailure: lucratividadeSectionFailure.failure,
          lucratividadePartialFailureAgentNames: _sectionMapper
              .lucratividadePartialFailureAgentNames(
                batchResults,
              ),
          mainResumoHadPlannedTargets: report.plannedTargets.isNotEmpty,
          partialQueryFailureDetails: <OverviewAgentQueryFailureDetail>[
            ...overviewPartialFailuresFromParticipants(report.participants),
            ..._sectionMapper.lucratividadePartialFailureDetails(batchResults),
            ..._sectionMapper.sectionPartialFailureDetails(
              batchResults,
              failureOf: (result) => result.userRankingFailure,
              source: OverviewAgentQueryFailureSource.userResumo,
            ),
            ..._sectionMapper.sectionPartialFailureDetails(
              batchResults,
              failureOf: (result) => result.monthlyFailure,
              source: OverviewAgentQueryFailureSource.monthlyTrend,
            ),
            ..._sectionMapper.sectionPartialFailureDetails(
              batchResults,
              failureOf: (result) => result.weekdayFailure,
              source: OverviewAgentQueryFailureSource.weekdayTrend,
            ),
            ..._sectionMapper.sectionPartialFailureDetails(
              batchResults,
              failureOf: (result) => result.weekdayUserFailure,
              source: OverviewAgentQueryFailureSource.weekdayUserTrend,
            ),
            ..._sectionMapper.sectionPartialFailureDetails(
              batchResults,
              failureOf: (result) => result.dailyFailure,
              source: OverviewAgentQueryFailureSource.dailyTrend,
            ),
          ],
          hubPresenceOnlineAgentIdsSnapshot:
              loaded.resolution.hubPresenceOnlineAgentIdsSnapshot,
          userRankingsOverride: batchUserRankingsOverride,
          userRankingRowsByAgentId: userRankingRowsByAgentId,
          agentRankingsLoadFailed: mainSectionFailure.loadFailed,
          agentRankingsLoadFailure: mainSectionFailure.failure,
          userRankingsLoadFailed: mainSectionFailure.loadFailed,
          userRankingsLoadFailure: mainSectionFailure.failure,
        );

        if (loaded.isFinal) {
          logOverviewLoadTelemetry(
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
          overviewProgressiveSnapshotFor(
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
      final recovered = await recoverOverviewOrFail(
        failure: failure,
        userId: userId,
        policy: policy,
        error: error,
        stackTrace: stackTrace,
      );
      yield asOverviewProgressiveResult(recovered);
    }
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
}
