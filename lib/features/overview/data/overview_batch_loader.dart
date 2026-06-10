import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_lucratividade_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_use_case.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_read_only_batch_options.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_transport_policy.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_sql_batch_target_wave_runner.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy_extensions.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_plan.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row_v2.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/overview/data/overview_batch_command_builder.dart';
import 'package:colmeia/features/overview/data/overview_batch_facts_persister.dart';
import 'package:colmeia/features/overview/data/overview_batch_load_config.dart';
import 'package:colmeia/features/overview/data/overview_batch_load_result.dart';
import 'package:colmeia/features/overview/data/overview_cached_facts_warmth_checker.dart';
import 'package:colmeia/features/overview/data/overview_cached_section_loader.dart';
import 'package:colmeia/features/overview/data/overview_main_batch_runner.dart';
import 'package:colmeia/features/overview/data/overview_section_batch_runner.dart';
import 'package:colmeia/features/overview/domain/entities/overview_section_request.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:result_dart/result_dart.dart';

export 'package:colmeia/features/overview/data/overview_batch_load_result.dart';

class OverviewBatchLoader {
  OverviewBatchLoader({
    required AgentQueryTargetResolver targetResolver,
    required AgentQueryPlanBuilder planBuilder,
    required AgentQueriesRepository agentQueriesRepository,
    OverviewBatchFactsPersister? factsPersister,
    LoadResumoTotalDiarioVendasUseCase? loadDaily,
    LoadResumoParcelasMensalUseCase? loadMonthly,
    LoadResumoParcelasDiaSemanaUseCase? loadWeekday,
    LoadResumoProdutoVendaLucratividadeUseCase? loadLucratividade,
    OverviewCachedFactsWarmthChecker? factsWarmthChecker,
    int maxParallelReadOnlyBatchItems = 4,
    int? targetWaveConcurrency,
    AgentQueryTransportPolicy? transportPolicy,
  }) : _targetResolver = targetResolver,
       _planBuilder = planBuilder,
       _agentQueriesRepository = agentQueriesRepository,
       _maxParallelReadOnlyBatchItems = maxParallelReadOnlyBatchItems,
       _cachedSectionLoader = OverviewCachedSectionLoader(
         loadDaily: loadDaily,
         loadMonthly: loadMonthly,
         loadWeekday: loadWeekday,
         loadLucratividade: loadLucratividade,
       ),
       _factsWarmthChecker = factsWarmthChecker,
       _targetWaveConcurrency =
           targetWaveConcurrency ??
           AppEnvironment.overviewTargetWaveConcurrency,
       _transportPolicy =
           transportPolicy ??
           AgentQueryTransportPolicy(
             mode: AppEnvironment.agentQueryTransportPolicyMode,
           ) {
    final resolvedTransportPolicy = _transportPolicy;
    _mainBatchRunner = OverviewMainBatchRunner(
      agentQueriesRepository: agentQueriesRepository,
      maxParallelReadOnlyBatchItems: maxParallelReadOnlyBatchItems,
      transportPolicy: resolvedTransportPolicy,
    );
    _sectionBatchRunner = OverviewSectionBatchRunner(
      agentQueriesRepository: agentQueriesRepository,
      cachedSectionLoader: _cachedSectionLoader,
      factsPersister: factsPersister,
      maxParallelReadOnlyBatchItems: maxParallelReadOnlyBatchItems,
      transportPolicy: resolvedTransportPolicy,
    );
  }

  final AgentQueryTargetResolver _targetResolver;
  final AgentQueryPlanBuilder _planBuilder;
  final AgentQueriesRepository _agentQueriesRepository;
  final int _maxParallelReadOnlyBatchItems;
  final OverviewCachedSectionLoader _cachedSectionLoader;
  final OverviewCachedFactsWarmthChecker? _factsWarmthChecker;
  final int _targetWaveConcurrency;
  final AgentQueryTransportPolicy _transportPolicy;
  late final OverviewMainBatchRunner _mainBatchRunner;
  late final OverviewSectionBatchRunner _sectionBatchRunner;

  static const _targetWaveRunner = AgentSqlBatchTargetWaveRunner();
  static const _commandBuilder = OverviewBatchCommandBuilder();

  static const int overviewBatchBridgeTimeoutMs =
      OverviewBatchLoadConfig.bridgeTimeoutMs;
  static const int overviewBatchSqlTimeoutMs =
      OverviewBatchLoadConfig.sqlTimeoutMs;
  static const int overviewBatchMaxRows = OverviewBatchLoadConfig.maxRows;

  Future<AppResult<OverviewBatchLoadResult>> load({
    required String userId,
    required DashboardFilter filter,
    required DateTime periodStart,
    required DateTime periodEnd,
    required ({DateTime dataVendaInicio, DateTime dataVendaFim}) last12Range,
    required ResumoParcelasMensalFilter mensalFilter,
    required ResumoParcelasDiaSemanaFilter weekdayFilter,
    required ResumoTotalDiarioVendasFilter dailyTotalFilter,
    required AgentQueryExecutionStrategy executionStrategy,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
    AgentQueryTargetResolution? preResolvedResolution,
    bool mergeSqlBatchesPerTarget = false,
    bool phasedBatchPerTarget = false,
  }) async {
    AppResult<OverviewBatchLoadResult>? finalResult;
    await for (final result in loadProgressively(
      userId: userId,
      filter: filter,
      periodStart: periodStart,
      periodEnd: periodEnd,
      last12Range: last12Range,
      mensalFilter: mensalFilter,
      weekdayFilter: weekdayFilter,
      dailyTotalFilter: dailyTotalFilter,
      executionStrategy: executionStrategy,
      cancelScope: cancelScope,
      cachePolicy: cachePolicy,
      preResolvedResolution: preResolvedResolution,
      mergeSqlBatchesPerTarget: mergeSqlBatchesPerTarget,
      phasedBatchPerTarget: phasedBatchPerTarget,
    )) {
      final loaded = result.getOrNull();
      if (loaded == null) {
        return result;
      }
      finalResult = result;
    }
    return finalResult ??
        const Failure<OverviewBatchLoadResult, AppFailure>(
          UnknownFailure(
            message: 'Overview batch load produced no data',
            userMessage: 'Unable to load the overview.',
          ),
        );
  }

  Stream<AppResult<OverviewBatchLoadResult>> loadProgressively({
    required String userId,
    required DashboardFilter filter,
    required DateTime periodStart,
    required DateTime periodEnd,
    required ({DateTime dataVendaInicio, DateTime dataVendaFim}) last12Range,
    required ResumoParcelasMensalFilter mensalFilter,
    required ResumoParcelasDiaSemanaFilter weekdayFilter,
    required ResumoTotalDiarioVendasFilter dailyTotalFilter,
    required AgentQueryExecutionStrategy executionStrategy,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
    AgentQueryTargetResolution? preResolvedResolution,
    bool mergeSqlBatchesPerTarget = false,
    bool phasedBatchPerTarget = false,
    OverviewSectionRequest sectionRequest = OverviewSectionRequest.full,
  }) async* {
    late final AgentQueryTargetResolution resolution;
    if (preResolvedResolution != null) {
      resolution = preResolvedResolution;
    } else {
      final resolutionResult = await _targetResolver.resolve(
        userId: userId,
        selectedAgentIds: filter.selectedAgentIds,
      );
      final resolved = resolutionResult.getOrNull();
      if (resolved == null) {
        yield Failure<OverviewBatchLoadResult, AppFailure>(
          resolutionResult.exceptionOrNull()!,
        );
        return;
      }
      resolution = resolved;
    }

    final planResult = _planBuilder.build(
      queryKey: AgentQueryKey.resumoParcelaFormaPagamentoV2,
      strategy: executionStrategy,
      resolution: resolution,
      bridgeTimeoutMs: overviewBatchBridgeTimeoutMs,
    );
    final plan = planResult.getOrNull();
    if (plan == null) {
      yield Failure<OverviewBatchLoadResult, AppFailure>(
        planResult.exceptionOrNull()!,
      );
      return;
    }

    final selectedNorm = _normalizeSelectedAgentIds(filter.selectedAgentIds);
    final includeLucratividadeMensal =
        selectedNorm != null && selectedNorm.length == 1;
    final loadsCachedSectionsViaUseCases = _cachedSectionLoader.isConfiguredFor(
      cachePolicy,
    );
    final factsWarmthChecker = _factsWarmthChecker;
    final useColdCacheMergedBatch =
        loadsCachedSectionsViaUseCases &&
        factsWarmthChecker != null &&
        !await factsWarmthChecker.areDailyMonthlyFactsWarm(
          userId: userId,
          targets: plan.plannedTargets,
          dailyFilter: dailyTotalFilter,
          monthlyFilter: mensalFilter,
          cachePolicy: cachePolicy,
        );
    final factsPersistedAgentIds = <String>{};
    final omitCachedSectionsFromSqlBatch = _cachedSectionSqlOmissionFor(
      cachePolicy: cachePolicy,
    );
    final useCachedSectionUseCases = _shouldLoadCachedSectionsViaUseCases(
      loadsCachedSectionsViaUseCases: loadsCachedSectionsViaUseCases,
      omitCachedSectionsFromSqlBatch: omitCachedSectionsFromSqlBatch,
    );
    if (useColdCacheMergedBatch) {
      yield* _loadProgressivelySingleBatchPerTarget(
        userId: userId,
        resolution: resolution,
        plan: plan,
        executionStrategy: executionStrategy,
        periodStart: periodStart,
        periodEnd: periodEnd,
        last12Range: last12Range,
        mensalFilter: mensalFilter,
        weekdayFilter: weekdayFilter,
        dailyTotalFilter: dailyTotalFilter,
        includeLucratividadeMensal: includeLucratividadeMensal,
        skipCachedSectionUseCases: true,
        cancelScope: cancelScope,
        cachePolicy: cachePolicy,
        factsPersistedAgentIds: factsPersistedAgentIds,
      );
      return;
    }
    if (mergeSqlBatchesPerTarget && !phasedBatchPerTarget) {
      yield* _loadProgressivelySingleBatchPerTarget(
        userId: userId,
        resolution: resolution,
        plan: plan,
        executionStrategy: executionStrategy,
        periodStart: periodStart,
        periodEnd: periodEnd,
        last12Range: last12Range,
        mensalFilter: mensalFilter,
        weekdayFilter: weekdayFilter,
        dailyTotalFilter: dailyTotalFilter,
        includeLucratividadeMensal: includeLucratividadeMensal,
        omitCachedSectionsFromSqlBatch: omitCachedSectionsFromSqlBatch,
        skipCachedSectionUseCases: !useCachedSectionUseCases,
        cancelScope: cancelScope,
        cachePolicy: cachePolicy,
        factsPersistedAgentIds: factsPersistedAgentIds,
        sectionRequest: sectionRequest,
      );
      return;
    }

    yield* _loadPhasedBatchPerTarget(
      userId: userId,
      resolution: resolution,
      plan: plan,
      executionStrategy: executionStrategy,
      periodStart: periodStart,
      periodEnd: periodEnd,
      last12Range: last12Range,
      mensalFilter: mensalFilter,
      weekdayFilter: weekdayFilter,
      dailyTotalFilter: dailyTotalFilter,
      includeLucratividadeMensal: includeLucratividadeMensal,
      omitCachedSectionsFromSqlBatch: omitCachedSectionsFromSqlBatch,
      cancelScope: cancelScope,
      cachePolicy: cachePolicy,
      factsPersistedAgentIds: factsPersistedAgentIds,
      sectionRequest: sectionRequest,
    );
  }

  Stream<AppResult<OverviewBatchLoadResult>> _loadPhasedBatchPerTarget({
    required String userId,
    required AgentQueryTargetResolution resolution,
    required AgentQueryPlan plan,
    required AgentQueryExecutionStrategy executionStrategy,
    required DateTime periodStart,
    required DateTime periodEnd,
    required ({DateTime dataVendaInicio, DateTime dataVendaFim}) last12Range,
    required ResumoParcelasMensalFilter mensalFilter,
    required ResumoParcelasDiaSemanaFilter weekdayFilter,
    required ResumoTotalDiarioVendasFilter dailyTotalFilter,
    required bool includeLucratividadeMensal,
    required OverviewCachedSectionSqlOmission omitCachedSectionsFromSqlBatch,
    required OverviewSectionRequest sectionRequest,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
    Set<String>? factsPersistedAgentIds,
  }) async* {
    final started = DateTime.now();
    final targets = plan.plannedTargets.toList();
    final sectionBatch = sectionRequest.sectionBatchSections.isEmpty
        ? null
        : _commandBuilder.buildSectionCommands(
            last12Range: last12Range,
            mensalFilter: mensalFilter,
            weekdayFilter: weekdayFilter,
            dailyTotalFilter: dailyTotalFilter,
            includeLucratividadeMensal: includeLucratividadeMensal,
            omitCachedSectionsFromSqlBatch: omitCachedSectionsFromSqlBatch,
            includedSectionBatchSections: sectionRequest.sectionBatchSections,
            includeMainBatch: false,
          );

    if (sectionRequest.isSectionBatchOnly) {
      if (sectionBatch == null || targets.isEmpty) {
        yield Success<OverviewBatchLoadResult, AppFailure>(
          OverviewBatchLoadResult(
            resolution: resolution,
            plan: plan,
            strategy: executionStrategy,
            targetResults: const <OverviewBatchTargetResult>[],
            mainResumoReport: _buildMainResumoReport(
              strategy: executionStrategy,
              plan: plan,
              targetResults: const <OverviewBatchTargetResult>[],
              totalElapsedMs: 0,
            ),
            totalElapsedMs: 0,
          ),
        );
        return;
      }

      final sectionResults = await _targetWaveRunner.run(
        targets: targets,
        waveConcurrencyCap: _targetWaveConcurrency,
        task: (target) => _sectionBatchRunner.loadForTarget(
          userId: userId,
          target: target,
          planBridgeTimeoutMs: plan.bridgeTimeoutMs,
          batch: sectionBatch,
          mensalFilter: mensalFilter,
          weekdayFilter: weekdayFilter,
          dailyTotalFilter: dailyTotalFilter,
          includeLucratividadeMensal: includeLucratividadeMensal,
          hubPresenceOnlineAgentIdsSnapshot:
              resolution.hubPresenceOnlineAgentIdsSnapshot,
          cancelScope: cancelScope,
          cachePolicy: cachePolicy,
          factsPersistedAgentIds: factsPersistedAgentIds,
        ),
      );
      final totalElapsedMs = DateTime.now().difference(started).inMilliseconds;
      yield Success<OverviewBatchLoadResult, AppFailure>(
        OverviewBatchLoadResult(
          resolution: resolution,
          plan: plan,
          strategy: executionStrategy,
          targetResults: sectionResults,
          mainResumoReport: _buildMainResumoReport(
            strategy: executionStrategy,
            plan: plan,
            targetResults: sectionResults,
            totalElapsedMs: totalElapsedMs,
          ),
          totalElapsedMs: totalElapsedMs,
          factsPersistedAgentIds: Set<String>.unmodifiable(
            factsPersistedAgentIds ?? const <String>{},
          ),
        ),
      );
      return;
    }

    final mainBatch = sectionRequest.runMainBatch
        ? _commandBuilder.buildMainCommands(
            periodStart: periodStart,
            periodEnd: periodEnd,
            includePaymentResumo: sectionRequest.mainBatchIncludePaymentResumo,
            includeUserRanking: sectionRequest.mainBatchIncludeUserRanking,
          )
        : null;

    final mainResults = mainBatch == null
        ? const <OverviewBatchTargetResult>[]
        : await _targetWaveRunner.run(
            targets: targets,
            waveConcurrencyCap: _targetWaveConcurrency,
            task: (target) => _mainBatchRunner.loadForTarget(
              userId: userId,
              target: target,
              planBridgeTimeoutMs: plan.bridgeTimeoutMs,
              batch: mainBatch,
              hubPresenceOnlineAgentIdsSnapshot:
                  resolution.hubPresenceOnlineAgentIdsSnapshot,
              cancelScope: cancelScope,
              cachePolicy: cachePolicy,
            ),
          );
    final mainElapsedMs = DateTime.now().difference(started).inMilliseconds;
    final mainReport = _buildMainResumoReport(
      strategy: executionStrategy,
      plan: plan,
      targetResults: mainResults,
      totalElapsedMs: mainElapsedMs,
    );
    final hasRunnableMainSuccess = mainResults.any(
      (result) => result.mainFailure == null,
    );
    final shouldLoadSections =
        sectionBatch != null &&
        (sectionRequest.runMainBatch
            ? plan.plannedTargets.isNotEmpty && hasRunnableMainSuccess
            : targets.isNotEmpty);

    if (sectionRequest.runMainBatch) {
      yield Success<OverviewBatchLoadResult, AppFailure>(
        OverviewBatchLoadResult(
          resolution: resolution,
          plan: plan,
          strategy: executionStrategy,
          targetResults: mainResults,
          mainResumoReport: mainReport,
          totalElapsedMs: mainElapsedMs,
          isFinal: !shouldLoadSections,
        ),
      );
    }

    if (!shouldLoadSections) {
      return;
    }

    final sectionTargets = sectionRequest.runMainBatch
        ? mainResults
              .where((result) => result.mainFailure == null)
              .map((result) => result.target)
              .toList(growable: false)
        : targets;
    final sectionResults = await _targetWaveRunner.run(
      targets: sectionTargets,
      waveConcurrencyCap: _targetWaveConcurrency,
      task: (target) => _sectionBatchRunner.loadForTarget(
        userId: userId,
        target: target,
        planBridgeTimeoutMs: plan.bridgeTimeoutMs,
        batch: sectionBatch,
        mensalFilter: mensalFilter,
        weekdayFilter: weekdayFilter,
        dailyTotalFilter: dailyTotalFilter,
        includeLucratividadeMensal: includeLucratividadeMensal,
        hubPresenceOnlineAgentIdsSnapshot:
            resolution.hubPresenceOnlineAgentIdsSnapshot,
        cancelScope: cancelScope,
        cachePolicy: cachePolicy,
        factsPersistedAgentIds: factsPersistedAgentIds,
      ),
    );
    final combinedResults = sectionRequest.runMainBatch
        ? _combineMainAndSectionResults(
            mainResults: mainResults,
            sectionResults: sectionResults,
          )
        : sectionResults;
    final totalElapsedMs = DateTime.now().difference(started).inMilliseconds;
    final report = _buildMainResumoReport(
      strategy: executionStrategy,
      plan: plan,
      targetResults: combinedResults,
      totalElapsedMs: totalElapsedMs,
    );

    yield Success<OverviewBatchLoadResult, AppFailure>(
      OverviewBatchLoadResult(
        resolution: resolution,
        plan: plan,
        strategy: executionStrategy,
        targetResults: combinedResults,
        mainResumoReport: report,
        totalElapsedMs: totalElapsedMs,
        factsPersistedAgentIds: Set<String>.unmodifiable(
          factsPersistedAgentIds ?? const <String>{},
        ),
      ),
    );
  }

  bool get _usesCachedDailyMonthlySections =>
      _cachedSectionLoader.usesDailyMonthly;

  bool get _usesCachedWeekdaySection => _cachedSectionLoader.usesWeekday;

  bool get _usesCachedLucratividadeSection =>
      _cachedSectionLoader.usesLucratividade;

  OverviewCachedSectionSqlOmission _cachedSectionSqlOmissionFor({
    required AgentQueryLoadPolicy cachePolicy,
  }) {
    if (cachePolicy != AgentQueryLoadPolicy.defaultLoad) {
      return const OverviewCachedSectionSqlOmission();
    }
    return OverviewCachedSectionSqlOmission(
      dailyMonthly: _usesCachedDailyMonthlySections,
      weekday: _usesCachedWeekdaySection,
      lucratividade: _usesCachedLucratividadeSection,
    );
  }

  bool _shouldLoadCachedSectionsViaUseCases({
    required bool loadsCachedSectionsViaUseCases,
    required OverviewCachedSectionSqlOmission omitCachedSectionsFromSqlBatch,
  }) {
    if (!loadsCachedSectionsViaUseCases) {
      return false;
    }
    return omitCachedSectionsFromSqlBatch.dailyMonthly ||
        omitCachedSectionsFromSqlBatch.weekday ||
        omitCachedSectionsFromSqlBatch.lucratividade;
  }

  Stream<AppResult<OverviewBatchLoadResult>>
  _loadProgressivelySingleBatchPerTarget({
    required String userId,
    required AgentQueryTargetResolution resolution,
    required AgentQueryPlan plan,
    required AgentQueryExecutionStrategy executionStrategy,
    required DateTime periodStart,
    required DateTime periodEnd,
    required ({DateTime dataVendaInicio, DateTime dataVendaFim}) last12Range,
    required ResumoParcelasMensalFilter mensalFilter,
    required ResumoParcelasDiaSemanaFilter weekdayFilter,
    required ResumoTotalDiarioVendasFilter dailyTotalFilter,
    required bool includeLucratividadeMensal,
    OverviewCachedSectionSqlOmission omitCachedSectionsFromSqlBatch =
        const OverviewCachedSectionSqlOmission(),
    bool skipCachedSectionUseCases = false,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
    Set<String>? factsPersistedAgentIds,
    OverviewSectionRequest sectionRequest = OverviewSectionRequest.full,
  }) async* {
    final batch = _commandBuilder.buildCommands(
      periodStart: periodStart,
      periodEnd: periodEnd,
      last12Range: last12Range,
      mensalFilter: mensalFilter,
      weekdayFilter: weekdayFilter,
      dailyTotalFilter: dailyTotalFilter,
      includeLucratividadeMensal: includeLucratividadeMensal,
      omitCachedSectionsFromSqlBatch: omitCachedSectionsFromSqlBatch,
      includedSectionBatchSections: sectionRequest.sectionBatchSections.isEmpty
          ? null
          : sectionRequest.sectionBatchSections,
      includeMainBatch: sectionRequest.runMainBatch,
    );
    final started = DateTime.now();
    final targets = plan.plannedTargets.toList();
    final results = await _targetWaveRunner.run(
      targets: targets,
      waveConcurrencyCap: _targetWaveConcurrency,
      task: (target) => _loadMergedBatchForTarget(
        userId: userId,
        target: target,
        planBridgeTimeoutMs: plan.bridgeTimeoutMs,
        batch: batch,
        mensalFilter: mensalFilter,
        weekdayFilter: weekdayFilter,
        dailyTotalFilter: dailyTotalFilter,
        includeLucratividadeMensal: includeLucratividadeMensal,
        hubPresenceOnlineAgentIdsSnapshot:
            resolution.hubPresenceOnlineAgentIdsSnapshot,
        cancelScope: cancelScope,
        cachePolicy: cachePolicy,
        skipCachedSectionUseCases: skipCachedSectionUseCases,
        factsPersistedAgentIds: factsPersistedAgentIds,
      ),
    );
    final totalElapsedMs = DateTime.now().difference(started).inMilliseconds;
    final report = _buildMainResumoReport(
      strategy: executionStrategy,
      plan: plan,
      targetResults: results,
      totalElapsedMs: totalElapsedMs,
    );
    yield Success<OverviewBatchLoadResult, AppFailure>(
      OverviewBatchLoadResult(
        resolution: resolution,
        plan: plan,
        strategy: executionStrategy,
        targetResults: results,
        mainResumoReport: report,
        totalElapsedMs: totalElapsedMs,
        factsPersistedAgentIds: Set<String>.unmodifiable(
          factsPersistedAgentIds ?? const <String>{},
        ),
      ),
    );
  }

  Future<OverviewBatchTargetResult> _loadMergedBatchForTarget({
    required String userId,
    required AgentQueryTarget target,
    required int planBridgeTimeoutMs,
    required OverviewBatchCommands batch,
    required ResumoParcelasMensalFilter mensalFilter,
    required ResumoParcelasDiaSemanaFilter weekdayFilter,
    required ResumoTotalDiarioVendasFilter dailyTotalFilter,
    required bool includeLucratividadeMensal,
    required Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool skipCachedSectionUseCases = false,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
    Set<String>? factsPersistedAgentIds,
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
          sqlTimeoutMs: overviewBatchSqlTimeoutMs,
          maxRows: overviewBatchMaxRows,
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
    OverviewCachedSections? cachedSections;
    if (!skipCachedSectionUseCases) {
      cachedSections = await _cachedSectionLoader.load(
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
    }
    if (execution == null) {
      return _sectionBatchRunner.targetResultWithSectionFailures(
        target: target,
        elapsedMs: elapsedMs,
        failure: result.exceptionOrNull()!,
        includeLucratividadeMensal: includeLucratividadeMensal,
        cachedSections: cachedSections,
        mainFailure: result.exceptionOrNull(),
      );
    }

    final mainMapped = _mainBatchRunner.mapExecution(
      target: target,
      elapsedMs: elapsedMs,
      execution: execution,
      indexes: OverviewMainBatchCommandIndexes(
        paymentResumo: batch.indexes.main,
        userRanking: batch.indexes.userRanking,
      ),
    );
    final sectionMapped = _sectionBatchRunner.mapExecution(
      target: target,
      elapsedMs: elapsedMs,
      execution: execution,
      indexes: OverviewSectionBatchCommandIndexes(
        monthly: batch.indexes.monthly,
        weekday: batch.indexes.weekday,
        daily: batch.indexes.daily,
        weekdayUser: batch.indexes.weekdayUser,
        lucratividade: batch.indexes.lucratividade,
        lucratividadeMensal: batch.indexes.lucratividadeMensal,
      ),
    );
    final merged = _sectionBatchRunner.mergeCachedSections(
      base: OverviewBatchTargetResult(
        target: target,
        elapsedMs: elapsedMs,
        mainRows: mainMapped.mainRows,
        userRankingRows: mainMapped.userRankingRows,
        monthlyRows: sectionMapped.monthlyRows,
        weekdayRows: sectionMapped.weekdayRows,
        dailyRows: sectionMapped.dailyRows,
        weekdayUserRows: sectionMapped.weekdayUserRows,
        lucratividadeRows: sectionMapped.lucratividadeRows,
        lucratividadeMensalRows: sectionMapped.lucratividadeMensalRows,
        mainFailure: mainMapped.mainFailure,
        userRankingFailure: mainMapped.userRankingFailure,
        monthlyFailure: sectionMapped.monthlyFailure,
        weekdayFailure: sectionMapped.weekdayFailure,
        dailyFailure: sectionMapped.dailyFailure,
        weekdayUserFailure: sectionMapped.weekdayUserFailure,
        lucratividadeFailure: sectionMapped.lucratividadeFailure,
        lucratividadeMensalFailure: sectionMapped.lucratividadeMensalFailure,
      ),
      cached: cachedSections,
    );
    await _sectionBatchRunner.persistFacts(
      userId: userId,
      target: target,
      mensalFilter: mensalFilter,
      dailyTotalFilter: dailyTotalFilter,
      monthlyRows: merged.monthlyRows,
      dailyRows: merged.dailyRows,
      cachePolicy: cachePolicy,
      factsPersistedAgentIds: factsPersistedAgentIds,
    );
    return merged;
  }

  List<OverviewBatchTargetResult> _combineMainAndSectionResults({
    required List<OverviewBatchTargetResult> mainResults,
    required List<OverviewBatchTargetResult> sectionResults,
  }) {
    final sectionsByAgentId = <String, OverviewBatchTargetResult>{
      for (final result in sectionResults) result.target.agentId: result,
    };
    return mainResults
        .map((main) {
          final sections = sectionsByAgentId[main.target.agentId];
          if (sections == null) {
            return main;
          }
          return OverviewBatchTargetResult(
            target: main.target,
            elapsedMs: main.elapsedMs + sections.elapsedMs,
            mainRows: main.mainRows,
            userRankingRows: main.userRankingRows,
            monthlyRows: sections.monthlyRows,
            weekdayRows: sections.weekdayRows,
            dailyRows: sections.dailyRows,
            weekdayUserRows: sections.weekdayUserRows,
            lucratividadeRows: sections.lucratividadeRows,
            lucratividadeMensalRows: sections.lucratividadeMensalRows,
            mainFailure: main.mainFailure,
            userRankingFailure: main.userRankingFailure,
            monthlyFailure: sections.monthlyFailure,
            weekdayFailure: sections.weekdayFailure,
            dailyFailure: sections.dailyFailure,
            weekdayUserFailure: sections.weekdayUserFailure,
            lucratividadeFailure: sections.lucratividadeFailure,
            lucratividadeMensalFailure: sections.lucratividadeMensalFailure,
          );
        })
        .toList(growable: false);
  }

  AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRowV2>
  _buildMainResumoReport({
    required AgentQueryExecutionStrategy strategy,
    required AgentQueryPlan plan,
    required List<OverviewBatchTargetResult> targetResults,
    required int totalElapsedMs,
  }) {
    return AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRowV2>(
      queryKey: AgentQueryKey.resumoParcelaFormaPagamentoV2,
      strategy: strategy,
      consideredApprovedAgentCount: plan.consideredApprovedAgentCount,
      plannedTargets: plan.plannedTargets,
      missingClientTokenTargets: plan.missingClientTokenTargets,
      skippedDueToHubPresenceTargets: plan.skippedDueToHubPresenceTargets,
      totalElapsedMs: totalElapsedMs,
      participants: targetResults
          .map(
            (result) =>
                AgentQueryExecutionParticipant<
                  ResumoParcelaFormaPagamentoRowV2
                >(
                  agentId: result.target.agentId,
                  displayName: result.target.displayName,
                  rows: result.mainRows,
                  elapsedMs: result.elapsedMs,
                  sourceRowCount: result.mainRows.length,
                  failure: result.mainFailure,
                ),
          )
          .toList(growable: false),
    );
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
}
