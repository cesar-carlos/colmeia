import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_lucratividade_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_use_case.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_read_only_batch_options.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcela_forma_pagamento_row_model_v2.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcela_por_usuario_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_dia_semana_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_dia_semana_usuario_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_mensal_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_produto_venda_lucratividade_mensal_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_produto_venda_lucratividade_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_total_diario_vendas_row_model.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_transport_policy.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_sql_batch_target_wave_runner.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcela_forma_pagamento_sql_v2.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcela_por_usuario_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_dia_semana_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_dia_semana_usuario_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_mensal_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_produto_venda_lucratividade_mensal_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_produto_venda_lucratividade_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_total_diario_vendas_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy_extensions.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_plan.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row_v2.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/overview/data/overview_batch_facts_persister.dart';
import 'package:colmeia/features/overview/data/overview_sql_batch_item_rows_mapper.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:result_dart/result_dart.dart';

/// SQL commands in the overview main batch before section-only batches.
///
/// Runs the payment-method parcel resumo and the per-user parcel resumo with
/// the same period params. The hub may execute read-only batch items in
/// parallel via `max_parallel_read_only_batch_items`. If the per-user item
/// fails or returns no rows, `overview_user_rankings_override_policy` falls
/// back to payment-method aggregation for operator rankings.
const int _overviewBatchMainCommandCount = 2;

final class OverviewBatchLoadResult {
  const OverviewBatchLoadResult({
    required this.resolution,
    required this.plan,
    required this.strategy,
    required this.targetResults,
    required this.mainResumoReport,
    required this.totalElapsedMs,
    this.isFinal = true,
  });

  final AgentQueryTargetResolution resolution;
  final AgentQueryPlan plan;
  final AgentQueryExecutionStrategy strategy;
  final List<OverviewBatchTargetResult> targetResults;
  final AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRowV2>
  mainResumoReport;
  final int totalElapsedMs;
  final bool isFinal;

  bool get hasTargetFailures =>
      targetResults.any((result) => result.hasAnyFailure);

  bool get hasSuccessfulMainTarget =>
      targetResults.any((result) => result.mainFailure == null);

  bool get completedWithOnlyTargetFailures =>
      targetResults.isNotEmpty &&
      targetResults.every((result) => result.hasAnyFailure) &&
      !hasSuccessfulMainTarget;
}

final class OverviewBatchTargetResult {
  const OverviewBatchTargetResult({
    required this.target,
    required this.elapsedMs,
    this.mainRows = const <ResumoParcelaFormaPagamentoRowV2>[],
    this.userRankingRows = const <ResumoParcelaPorUsuarioRow>[],
    this.monthlyRows = const <ResumoParcelasMensalRow>[],
    this.weekdayRows = const <ResumoParcelasDiaSemanaRow>[],
    this.dailyRows = const <ResumoTotalDiarioVendasRow>[],
    this.weekdayUserRows = const <ResumoParcelasDiaSemanaUsuarioRow>[],
    this.lucratividadeRows = const <ResumoProdutoVendaLucratividadeRow>[],
    this.lucratividadeMensalRows =
        const <ResumoProdutoVendaLucratividadeMensalRow>[],
    this.mainFailure,
    this.userRankingFailure,
    this.monthlyFailure,
    this.weekdayFailure,
    this.dailyFailure,
    this.weekdayUserFailure,
    this.lucratividadeFailure,
    this.lucratividadeMensalFailure,
  });

  final AgentQueryTarget target;
  final int elapsedMs;
  final List<ResumoParcelaFormaPagamentoRowV2> mainRows;
  final List<ResumoParcelaPorUsuarioRow> userRankingRows;
  final List<ResumoParcelasMensalRow> monthlyRows;
  final List<ResumoParcelasDiaSemanaRow> weekdayRows;
  final List<ResumoTotalDiarioVendasRow> dailyRows;
  final List<ResumoParcelasDiaSemanaUsuarioRow> weekdayUserRows;
  final List<ResumoProdutoVendaLucratividadeRow> lucratividadeRows;
  final List<ResumoProdutoVendaLucratividadeMensalRow> lucratividadeMensalRows;
  final AppFailure? mainFailure;
  final AppFailure? userRankingFailure;
  final AppFailure? monthlyFailure;
  final AppFailure? weekdayFailure;
  final AppFailure? dailyFailure;
  final AppFailure? weekdayUserFailure;
  final AppFailure? lucratividadeFailure;
  final AppFailure? lucratividadeMensalFailure;

  bool get hasAnyFailure =>
      mainFailure != null ||
      userRankingFailure != null ||
      monthlyFailure != null ||
      weekdayFailure != null ||
      dailyFailure != null ||
      weekdayUserFailure != null ||
      lucratividadeFailure != null ||
      lucratividadeMensalFailure != null;

  bool get hasSectionFailure =>
      monthlyFailure != null ||
      weekdayFailure != null ||
      dailyFailure != null ||
      weekdayUserFailure != null ||
      lucratividadeFailure != null ||
      lucratividadeMensalFailure != null;
}


final class _CachedSectionSqlOmission {
  const _CachedSectionSqlOmission({
    this.dailyMonthly = false,
    this.weekday = false,
    this.lucratividade = false,
  });

  final bool dailyMonthly;
  final bool weekday;
  final bool lucratividade;
}

final class _OverviewCachedSections {
  const _OverviewCachedSections({
    this.dailyRows = const <ResumoTotalDiarioVendasRow>[],
    this.monthlyRows = const <ResumoParcelasMensalRow>[],
    this.weekdayRows = const <ResumoParcelasDiaSemanaRow>[],
    this.lucratividadeRows = const <ResumoProdutoVendaLucratividadeRow>[],
    this.dailyFailure,
    this.monthlyFailure,
    this.weekdayFailure,
    this.lucratividadeFailure,
  });

  final List<ResumoTotalDiarioVendasRow> dailyRows;
  final List<ResumoParcelasMensalRow> monthlyRows;
  final List<ResumoParcelasDiaSemanaRow> weekdayRows;
  final List<ResumoProdutoVendaLucratividadeRow> lucratividadeRows;
  final AppFailure? dailyFailure;
  final AppFailure? monthlyFailure;
  final AppFailure? weekdayFailure;
  final AppFailure? lucratividadeFailure;
}

final class _OverviewBatchCommandIndexes {
  const _OverviewBatchCommandIndexes({
    required this.main,
    required this.userRanking,
    required this.monthly,
    required this.weekday,
    required this.daily,
    required this.weekdayUser,
    required this.lucratividade,
    this.lucratividadeMensal,
  });

  final int main;
  final int userRanking;
  final int? monthly;
  final int? weekday;
  final int? daily;
  final int weekdayUser;
  final int? lucratividade;
  final int? lucratividadeMensal;
}

final class _OverviewMainBatchCommandIndexes {
  const _OverviewMainBatchCommandIndexes({
    required this.main,
    required this.userRanking,
  });

  final int main;
  final int userRanking;
}

final class _OverviewSectionBatchCommandIndexes {
  const _OverviewSectionBatchCommandIndexes({
    required this.weekday, required this.weekdayUser, required this.lucratividade, this.monthly,
    this.daily,
    this.lucratividadeMensal,
  });

  final int? monthly;
  final int? weekday;
  final int? daily;
  final int weekdayUser;
  final int? lucratividade;
  final int? lucratividadeMensal;
}

final class _OverviewBatchCommands {
  const _OverviewBatchCommands({
    required this.commands,
    required this.indexes,
  });

  final List<AgentSqlExecuteBatchCommand> commands;
  final _OverviewBatchCommandIndexes indexes;
}

final class _OverviewMainBatchCommands {
  const _OverviewMainBatchCommands({
    required this.commands,
    required this.indexes,
  });

  final List<AgentSqlExecuteBatchCommand> commands;
  final _OverviewMainBatchCommandIndexes indexes;
}

final class _OverviewSectionBatchCommands {
  const _OverviewSectionBatchCommands({
    required this.commands,
    required this.indexes,
  });

  final List<AgentSqlExecuteBatchCommand> commands;
  final _OverviewSectionBatchCommandIndexes indexes;
}

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
    int maxParallelReadOnlyBatchItems = 4,
    int? targetWaveConcurrency,
    AgentQueryTransportPolicy? transportPolicy,
  }) : _targetResolver = targetResolver,
       _planBuilder = planBuilder,
       _agentQueriesRepository = agentQueriesRepository,
       _factsPersister = factsPersister,
       _loadDaily = loadDaily,
       _loadMonthly = loadMonthly,
       _loadWeekday = loadWeekday,
       _loadLucratividade = loadLucratividade,
       _maxParallelReadOnlyBatchItems = maxParallelReadOnlyBatchItems,
       _targetWaveConcurrency =
           targetWaveConcurrency ?? AppEnvironment.overviewTargetWaveConcurrency,
       _transportPolicy = transportPolicy ??
           AgentQueryTransportPolicy(
             mode: AppEnvironment.agentQueryTransportPolicyMode,
           );

  final AgentQueryTargetResolver _targetResolver;
  final AgentQueryPlanBuilder _planBuilder;
  final AgentQueriesRepository _agentQueriesRepository;
  final OverviewBatchFactsPersister? _factsPersister;
  final LoadResumoTotalDiarioVendasUseCase? _loadDaily;
  final LoadResumoParcelasMensalUseCase? _loadMonthly;
  final LoadResumoParcelasDiaSemanaUseCase? _loadWeekday;
  final LoadResumoProdutoVendaLucratividadeUseCase? _loadLucratividade;
  final int _maxParallelReadOnlyBatchItems;
  final int _targetWaveConcurrency;
  final AgentQueryTransportPolicy _transportPolicy;

  static const _targetWaveRunner = AgentSqlBatchTargetWaveRunner();

  /// Hub validates `sql.executeBatch` `options.timeout_ms` at <= 300_000.
  static const int overviewBatchBridgeTimeoutMs = 300000;
  static const int overviewBatchSqlTimeoutMs = 300000;
  static const int overviewBatchMaxRows =
      AgentQueriesBoundedResultMaxRows.resumoParcelasMensal;

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
    final omitCachedSectionsFromSqlBatch = _cachedSectionSqlOmissionFor(
      cachePolicy: cachePolicy,
    );
    if (mergeSqlBatchesPerTarget) {
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
        cancelScope: cancelScope,
        cachePolicy: cachePolicy,
      );
      return;
    }
    final mainBatch = _buildMainCommands(
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
    final sectionBatch = _buildSectionCommands(
      last12Range: last12Range,
      mensalFilter: mensalFilter,
      weekdayFilter: weekdayFilter,
      dailyTotalFilter: dailyTotalFilter,
      includeLucratividadeMensal: includeLucratividadeMensal,
      omitCachedSectionsFromSqlBatch: omitCachedSectionsFromSqlBatch,
    );
    final started = DateTime.now();
    final targets = plan.plannedTargets.toList();
    final mainResults = await _targetWaveRunner.run(
      targets: targets,
      waveConcurrencyCap: _targetWaveConcurrency,
      task: (target) => _loadMainForTarget(
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
        plan.plannedTargets.isNotEmpty && hasRunnableMainSuccess;

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

    if (!shouldLoadSections) {
      return;
    }

    final sectionTargets = mainResults
        .where((result) => result.mainFailure == null)
        .map((result) => result.target)
        .toList(growable: false);
    final sectionResults = await _targetWaveRunner.run(
      targets: sectionTargets,
      waveConcurrencyCap: _targetWaveConcurrency,
      task: (target) => _loadSectionsForTarget(
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
      ),
    );
    final combinedResults = _combineMainAndSectionResults(
      mainResults: mainResults,
      sectionResults: sectionResults,
    );
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
      ),
    );
  }

  Future<OverviewBatchTargetResult> _loadMainForTarget({
    required String userId,
    required AgentQueryTarget target,
    required int planBridgeTimeoutMs,
    required _OverviewMainBatchCommands batch,
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
    if (execution == null) {
      final failure = result.exceptionOrNull()!;
      return OverviewBatchTargetResult(
        target: target,
        elapsedMs: elapsedMs,
        mainFailure: failure,
      );
    }

    return _mapMainExecution(
      target: target,
      elapsedMs: elapsedMs,
      execution: execution,
      indexes: batch.indexes,
    );
  }

  Future<OverviewBatchTargetResult> _loadSectionsForTarget({
    required String userId,
    required AgentQueryTarget target,
    required int planBridgeTimeoutMs,
    required _OverviewSectionBatchCommands batch,
    required ResumoParcelasMensalFilter mensalFilter,
    required ResumoParcelasDiaSemanaFilter weekdayFilter,
    required ResumoTotalDiarioVendasFilter dailyTotalFilter,
    required bool includeLucratividadeMensal,
    required Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) async {
    final started = DateTime.now();
    final batchOutcome = await _executeSectionSqlBatch(
      userId: userId,
      target: target,
      planBridgeTimeoutMs: planBridgeTimeoutMs,
      batch: batch,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      cancelScope: cancelScope,
      cachePolicy: cachePolicy,
    );
    final cachedSections = await _loadCachedSectionsViaUseCases(
      userId: userId,
      target: target,
      mensalFilter: mensalFilter,
      weekdayFilter: weekdayFilter,
      dailyTotalFilter: dailyTotalFilter,
      planBridgeTimeoutMs: planBridgeTimeoutMs,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      cancelScope: cancelScope,
      cachePolicy: cachePolicy,
    );
    final elapsedMs = DateTime.now().difference(started).inMilliseconds;
    if (batchOutcome.failure != null) {
      return _targetResultWithSectionFailures(
        target: target,
        elapsedMs: elapsedMs,
        failure: batchOutcome.failure!,
        includeLucratividadeMensal: includeLucratividadeMensal,
        cachedSections: cachedSections,
      );
    }

    final mapped = _mergeCachedSections(
      base: _mapSectionExecution(
      target: target,
      elapsedMs: elapsedMs,
      execution: batchOutcome.execution!,
      indexes: batch.indexes,
      ),
      cached: cachedSections,
    );
    await _persistSectionFacts(
      userId: userId,
      target: target,
      mensalFilter: mensalFilter,
      dailyTotalFilter: dailyTotalFilter,
      monthlyRows: mapped.monthlyRows,
      dailyRows: mapped.dailyRows,
      cachePolicy: cachePolicy,
    );
    return mapped;
  }


  bool get _usesCachedDailyMonthlySections =>
      _loadDaily != null && _loadMonthly != null;

  bool get _usesCachedWeekdaySection => _loadWeekday != null;

  bool get _usesCachedLucratividadeSection => _loadLucratividade != null;

  _CachedSectionSqlOmission _cachedSectionSqlOmissionFor({
    required AgentQueryLoadPolicy cachePolicy,
  }) {
    if (cachePolicy != AgentQueryLoadPolicy.defaultLoad) {
      return const _CachedSectionSqlOmission();
    }
    return _CachedSectionSqlOmission(
      dailyMonthly: _usesCachedDailyMonthlySections,
      weekday: _usesCachedWeekdaySection,
      lucratividade: _usesCachedLucratividadeSection,
    );
  }

  bool _loadsCachedSectionsViaUseCases(AgentQueryLoadPolicy cachePolicy) {
    if (cachePolicy != AgentQueryLoadPolicy.defaultLoad) {
      return false;
    }
    return _usesCachedDailyMonthlySections ||
        _usesCachedWeekdaySection ||
        _usesCachedLucratividadeSection;
  }

  Future<_OverviewCachedSections?> _loadCachedSectionsViaUseCases({
    required String userId,
    required AgentQueryTarget target,
    required ResumoParcelasMensalFilter mensalFilter,
    required ResumoParcelasDiaSemanaFilter weekdayFilter,
    required ResumoTotalDiarioVendasFilter dailyTotalFilter,
    required int planBridgeTimeoutMs,
    required AgentQueryLoadPolicy cachePolicy,
    required Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    if (!_loadsCachedSectionsViaUseCases(cachePolicy)) {
      return null;
    }

    final loadDaily = _loadDaily;
    final loadMonthly = _loadMonthly;
    final loadWeekday = _loadWeekday;
    final loadLucratividade = _loadLucratividade;
    if (loadDaily == null &&
        loadMonthly == null &&
        loadWeekday == null &&
        loadLucratividade == null) {
      return null;
    }

    final lucratividadeFilter = ResumoProdutoVendaLucratividadeFilter(
      dataVendaInicio: dailyTotalFilter.dataVendaInicio,
      dataVendaFim: dailyTotalFilter.dataVendaFim,
    );

    AppResult<List<ResumoTotalDiarioVendasRow>>? dailyResult;
    AppResult<List<ResumoParcelasMensalRow>>? monthlyResult;
    AppResult<List<ResumoParcelasDiaSemanaRow>>? weekdayResult;
    AppResult<List<ResumoProdutoVendaLucratividadeRow>>? lucratividadeResult;

    if (loadDaily != null) {
      dailyResult = await loadDaily.call(
        userId: userId,
        agentId: target.agentId,
        filter: dailyTotalFilter,
        clientToken: target.clientToken,
        bridgeTimeoutMs: planBridgeTimeoutMs,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow:
            target.hubConnectedFromApprovedCatalogRow,
        cancelScope: cancelScope,
        cachePolicy: cachePolicy,
      );
    }
    if (loadMonthly != null) {
      monthlyResult = await loadMonthly.call(
        userId: userId,
        agentId: target.agentId,
        filter: mensalFilter,
        clientToken: target.clientToken,
        bridgeTimeoutMs: planBridgeTimeoutMs,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow:
            target.hubConnectedFromApprovedCatalogRow,
        cancelScope: cancelScope,
        cachePolicy: cachePolicy,
      );
    }
    if (loadWeekday != null) {
      weekdayResult = await loadWeekday.call(
        userId: userId,
        agentId: target.agentId,
        filter: weekdayFilter,
        clientToken: target.clientToken,
        bridgeTimeoutMs: planBridgeTimeoutMs,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow:
            target.hubConnectedFromApprovedCatalogRow,
        cancelScope: cancelScope,
        cachePolicy: cachePolicy,
      );
    }
    if (loadLucratividade != null) {
      lucratividadeResult = await loadLucratividade.call(
        userId: userId,
        agentId: target.agentId,
        filter: lucratividadeFilter,
        clientToken: target.clientToken,
        bridgeTimeoutMs: planBridgeTimeoutMs,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow:
            target.hubConnectedFromApprovedCatalogRow,
        cancelScope: cancelScope,
        cachePolicy: cachePolicy,
      );
    }

    return _OverviewCachedSections(
      dailyRows: dailyResult?.getOrNull() ?? const <ResumoTotalDiarioVendasRow>[],
      monthlyRows:
          monthlyResult?.getOrNull() ?? const <ResumoParcelasMensalRow>[],
      weekdayRows:
          weekdayResult?.getOrNull() ?? const <ResumoParcelasDiaSemanaRow>[],
      lucratividadeRows: lucratividadeResult?.getOrNull() ??
          const <ResumoProdutoVendaLucratividadeRow>[],
      dailyFailure: dailyResult?.exceptionOrNull(),
      monthlyFailure: monthlyResult?.exceptionOrNull(),
      weekdayFailure: weekdayResult?.exceptionOrNull(),
      lucratividadeFailure: lucratividadeResult?.exceptionOrNull(),
    );
  }

  OverviewBatchTargetResult _mergeCachedSections({
    required OverviewBatchTargetResult base,
    required _OverviewCachedSections? cached,
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
      lucratividadeMensalRows: base.lucratividadeMensalRows,
      mainFailure: base.mainFailure,
      userRankingFailure: base.userRankingFailure,
      monthlyFailure: cached.monthlyFailure ?? base.monthlyFailure,
      weekdayFailure: cached.weekdayFailure ?? base.weekdayFailure,
      dailyFailure: cached.dailyFailure ?? base.dailyFailure,
      weekdayUserFailure: base.weekdayUserFailure,
      lucratividadeFailure:
          cached.lucratividadeFailure ?? base.lucratividadeFailure,
      lucratividadeMensalFailure: base.lucratividadeMensalFailure,
    );
  }

  Stream<AppResult<OverviewBatchLoadResult>> _loadProgressivelySingleBatchPerTarget({
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
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) async* {
    final batch = _buildCommands(
      periodStart: periodStart,
      periodEnd: periodEnd,
      last12Range: last12Range,
      mensalFilter: mensalFilter,
      weekdayFilter: weekdayFilter,
      dailyTotalFilter: dailyTotalFilter,
      includeLucratividadeMensal: includeLucratividadeMensal,
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
      ),
    );
  }

  Future<OverviewBatchTargetResult> _loadMergedBatchForTarget({
    required String userId,
    required AgentQueryTarget target,
    required int planBridgeTimeoutMs,
    required _OverviewBatchCommands batch,
    required ResumoParcelasMensalFilter mensalFilter,
    required ResumoParcelasDiaSemanaFilter weekdayFilter,
    required ResumoTotalDiarioVendasFilter dailyTotalFilter,
    required bool includeLucratividadeMensal,
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
    if (execution == null) {
      return _targetResultWithSectionFailures(
        target: target,
        elapsedMs: elapsedMs,
        failure: result.exceptionOrNull()!,
        includeLucratividadeMensal: includeLucratividadeMensal,
        mainFailure: result.exceptionOrNull(),
      );
    }

    final mainMapped = _mapMainExecution(
      target: target,
      elapsedMs: elapsedMs,
      execution: execution,
      indexes: _OverviewMainBatchCommandIndexes(
        main: batch.indexes.main,
        userRanking: batch.indexes.userRanking,
      ),
    );
    final sectionMapped = _mapSectionExecution(
      target: target,
      elapsedMs: elapsedMs,
      execution: execution,
      indexes: _OverviewSectionBatchCommandIndexes(
        monthly: batch.indexes.monthly,
        weekday: batch.indexes.weekday,
        daily: batch.indexes.daily,
        weekdayUser: batch.indexes.weekdayUser,
        lucratividade: batch.indexes.lucratividade,
        lucratividadeMensal: batch.indexes.lucratividadeMensal,
      ),
    );
    final merged = OverviewBatchTargetResult(
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
    );
    await _persistSectionFacts(
      userId: userId,
      target: target,
      mensalFilter: mensalFilter,
      dailyTotalFilter: dailyTotalFilter,
      monthlyRows: merged.monthlyRows,
      dailyRows: merged.dailyRows,
      cachePolicy: cachePolicy,
    );
    return merged;
  }

  _OverviewSectionBatchCommandIndexes _sectionIndexesFromFull(
    _OverviewBatchCommandIndexes full,
  ) {
    const mainOffset = _overviewBatchMainCommandCount;
    int? subtract(int? index) =>
        index == null ? null : index - mainOffset;
    return _OverviewSectionBatchCommandIndexes(
      monthly: subtract(full.monthly),
      weekday: subtract(full.weekday),
      daily: subtract(full.daily),
      weekdayUser: full.weekdayUser - mainOffset,
      lucratividade: subtract(full.lucratividade),
      lucratividadeMensal: subtract(full.lucratividadeMensal),
    );
  }


  Future<void> _persistSectionFacts({
    required String userId,
    required AgentQueryTarget target,
    required ResumoParcelasMensalFilter mensalFilter,
    required ResumoTotalDiarioVendasFilter dailyTotalFilter,
    required List<ResumoParcelasMensalRow> monthlyRows,
    required List<ResumoTotalDiarioVendasRow> dailyRows,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
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
  }

  Future<({AgentSqlBatchExecutionResult? execution, AppFailure? failure})>
  _executeSectionSqlBatch({
    required String userId,
    required AgentQueryTarget target,
    required int planBridgeTimeoutMs,
    required _OverviewSectionBatchCommands batch,
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
    final execution = result.getOrNull();
    if (execution == null) {
      return (execution: null, failure: result.exceptionOrNull());
    }
    return (execution: execution, failure: null);
  }

  _OverviewMainBatchCommands _buildMainCommands({
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final commands = <AgentSqlExecuteBatchCommand>[];
    final parcelPeriodParams = _parcelPeriodSqlParamsFromPeriodo(
      ResumoParcelaFormaPagamentoFilter(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
      ),
    );
    final main = commands.length;
    commands.add(
      AgentSqlExecuteBatchCommand(
        sql: ResumoParcelaFormaPagamentoSqlV2.query,
        namedParams: parcelPeriodParams,
        executionOrder: main,
      ),
    );
    final userRanking = commands.length;
    commands.add(
      AgentSqlExecuteBatchCommand(
        sql: ResumoParcelaPorUsuarioSql.query,
        namedParams: parcelPeriodParams,
        executionOrder: userRanking,
      ),
    );
    return _OverviewMainBatchCommands(
      commands: commands,
      indexes: _OverviewMainBatchCommandIndexes(
        main: main,
        userRanking: userRanking,
      ),
    );
  }

  _OverviewSectionBatchCommands _buildSectionCommands({
    required ({DateTime dataVendaInicio, DateTime dataVendaFim}) last12Range,
    required ResumoParcelasMensalFilter mensalFilter,
    required ResumoParcelasDiaSemanaFilter weekdayFilter,
    required ResumoTotalDiarioVendasFilter dailyTotalFilter,
    required bool includeLucratividadeMensal,
    _CachedSectionSqlOmission omitCachedSectionsFromSqlBatch =
        const _CachedSectionSqlOmission(),
  }) {
    final full = _buildCommands(
      periodStart: dailyTotalFilter.dataVendaInicio,
      periodEnd: dailyTotalFilter.dataVendaFim,
      last12Range: last12Range,
      mensalFilter: mensalFilter,
      weekdayFilter: weekdayFilter,
      dailyTotalFilter: dailyTotalFilter,
      includeLucratividadeMensal: includeLucratividadeMensal,
      omitCachedSectionsFromSqlBatch: omitCachedSectionsFromSqlBatch,
    );
    final commands = full.commands
        .skip(_overviewBatchMainCommandCount)
        .toList(growable: false);
    for (var i = 0; i < commands.length; i++) {
      final command = commands[i];
      commands[i] = AgentSqlExecuteBatchCommand(
        sql: command.sql,
        namedParams: command.namedParams,
        executionOrder: i,
      );
    }
    return _OverviewSectionBatchCommands(
      commands: commands,
      indexes: _sectionIndexesFromFull(full.indexes),
    );
  }

  _OverviewBatchCommands _buildCommands({
    required DateTime periodStart,
    required DateTime periodEnd,
    required ({DateTime dataVendaInicio, DateTime dataVendaFim}) last12Range,
    required ResumoParcelasMensalFilter mensalFilter,
    required ResumoParcelasDiaSemanaFilter weekdayFilter,
    required ResumoTotalDiarioVendasFilter dailyTotalFilter,
    required bool includeLucratividadeMensal,
    _CachedSectionSqlOmission omitCachedSectionsFromSqlBatch =
        const _CachedSectionSqlOmission(),
  }) {
    final commands = <AgentSqlExecuteBatchCommand>[];

    int add(String sql, Map<String, Object?> namedParams) {
      final index = commands.length;
      commands.add(
        AgentSqlExecuteBatchCommand(
          sql: sql,
          namedParams: namedParams,
          executionOrder: index,
        ),
      );
      return index;
    }

    final main = add(
      ResumoParcelaFormaPagamentoSqlV2.query,
      _parcelPeriodSqlParamsFromPeriodo(
        ResumoParcelaFormaPagamentoFilter(
          dataVendaInicio: periodStart,
          dataVendaFim: periodEnd,
        ),
      ),
    );
    final userRanking = add(
      ResumoParcelaPorUsuarioSql.query,
      _parcelPeriodSqlParamsFromPeriodo(
        ResumoParcelaFormaPagamentoFilter(
          dataVendaInicio: periodStart,
          dataVendaFim: periodEnd,
        ),
      ),
    );
    final int? monthly;
    if (!omitCachedSectionsFromSqlBatch.dailyMonthly) {
      monthly = add(
      ResumoParcelasMensalSql.query(
        codEmpresa: mensalFilter.codEmpresa,
        codFilial: mensalFilter.codFilial,
        codVendedor: mensalFilter.codVendedor,
      ),
      _parcelPeriodSqlParamsFromMensal(mensalFilter),
    );
    } else {
      monthly = null;
    }
    final int? weekday;
    if (!omitCachedSectionsFromSqlBatch.weekday) {
      weekday = add(
      ResumoParcelasDiaSemanaSql.query(
        codEmpresa: weekdayFilter.codEmpresa,
        codFilial: weekdayFilter.codFilial,
        codVendedor: weekdayFilter.codVendedor,
      ),
      _parcelPeriodSqlParamsFromWeekday(weekdayFilter),
    );
    } else {
      weekday = null;
    }
    final int? daily;
    if (!omitCachedSectionsFromSqlBatch.dailyMonthly) {
      daily = add(
      ResumoTotalDiarioVendasSql.query,
      _produtoVendidoPeriodParams(dailyTotalFilter),
    );
    } else {
      daily = null;
    }
    final weekdayUser = add(
      ResumoParcelasDiaSemanaUsuarioSql.query(
        codEmpresa: weekdayFilter.codEmpresa,
        codFilial: weekdayFilter.codFilial,
        codVendedor: weekdayFilter.codVendedor,
      ),
      _parcelPeriodSqlParamsFromWeekday(weekdayFilter),
    );
    final int? lucratividade;
    if (!omitCachedSectionsFromSqlBatch.lucratividade) {
      lucratividade = add(
      ResumoProdutoVendaLucratividadeSql.query,
      _lucratividadeParams(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
      ),
    );
    } else {
      lucratividade = null;
    }
    final lucratividadeMensal = includeLucratividadeMensal
        ? add(
            ResumoProdutoVendaLucratividadeMensalSql.query,
            _lucratividadeParams(
              dataVendaInicio: last12Range.dataVendaInicio,
              dataVendaFim: last12Range.dataVendaFim,
            ),
          )
        : null;

    return _OverviewBatchCommands(
      commands: commands,
      indexes: _OverviewBatchCommandIndexes(
        main: main,
        userRanking: userRanking,
        monthly: monthly,
        weekday: weekday,
        daily: daily,
        weekdayUser: weekdayUser,
        lucratividade: lucratividade,
        lucratividadeMensal: lucratividadeMensal,
      ),
    );
  }

  Map<String, Object?> _parcelPeriodSqlParamsFromPeriodo(
    ResumoParcelasPeriodoFilter filter,
  ) {
    return <String, Object?>{
      'dataVendaInicio': AgentQueriesSqlLocalDate.format(
        filter.dataVendaInicio,
      ),
      'dataVendaFim': AgentQueriesSqlLocalDate.format(filter.dataVendaFim),
      'origem': filter.trimmedOrigem,
      'geraFinanceiro': filter.trimmedGeraFinanceiro,
      'preVenda': filter.trimmedPreVenda,
    };
  }

  Map<String, Object?> _parcelPeriodSqlParamsFromMensal(
    ResumoParcelasMensalFilter filter,
  ) {
    return _parcelPeriodSqlParamsFromPeriodo(
      ResumoParcelasPeriodoFilter(
        dataVendaInicio: filter.dataVendaInicio,
        dataVendaFim: filter.dataVendaFim,
        origem: filter.origem,
        geraFinanceiro: filter.geraFinanceiro,
        preVenda: filter.preVenda,
      ),
    );
  }

  Map<String, Object?> _parcelPeriodSqlParamsFromWeekday(
    ResumoParcelasDiaSemanaFilter filter,
  ) {
    return _parcelPeriodSqlParamsFromPeriodo(
      ResumoParcelasPeriodoFilter(
        dataVendaInicio: filter.dataVendaInicio,
        dataVendaFim: filter.dataVendaFim,
        origem: filter.origem,
        geraFinanceiro: filter.geraFinanceiro,
        preVenda: filter.preVenda,
      ),
    );
  }

  Map<String, Object?> _produtoVendidoPeriodParams(
    ResumoTotalDiarioVendasFilter filter,
  ) {
    return <String, Object?>{
      'dataVendaInicio': AgentQueriesSqlLocalDate.format(
        filter.dataVendaInicio,
      ),
      'dataVendaFim': AgentQueriesSqlLocalDate.format(filter.dataVendaFim),
      'origem': filter.trimmedOrigem,
      'geraFinanceiro': filter.trimmedGeraFinanceiro,
      'preVenda': filter.trimmedPreVenda,
    };
  }

  Map<String, Object?> _lucratividadeParams({
    required DateTime dataVendaInicio,
    required DateTime dataVendaFim,
  }) {
    return <String, Object?>{
      'dataVendaInicio': AgentQueriesSqlLocalDate.format(dataVendaInicio),
      'dataVendaFim': AgentQueriesSqlLocalDate.format(dataVendaFim),
      'origem': 'FrenteLoja',
    };
  }

  OverviewBatchTargetResult _targetResultWithSectionFailures({
    required AgentQueryTarget target,
    required int elapsedMs,
    required AppFailure failure,
    required bool includeLucratividadeMensal,
    _OverviewCachedSections? cachedSections,
    AppFailure? mainFailure,
  }) {
    final cached = cachedSections;
    return OverviewBatchTargetResult(
      target: target,
      elapsedMs: elapsedMs,
      monthlyRows: cached?.monthlyRows ?? const <ResumoParcelasMensalRow>[],
      weekdayRows: cached?.weekdayRows ?? const <ResumoParcelasDiaSemanaRow>[],
      dailyRows: cached?.dailyRows ?? const <ResumoTotalDiarioVendasRow>[],
      lucratividadeRows: cached?.lucratividadeRows ??
          const <ResumoProdutoVendaLucratividadeRow>[],
      mainFailure: mainFailure,
      monthlyFailure: _usesCachedDailyMonthlySections
          ? cached?.monthlyFailure
          : failure,
      weekdayFailure:
          _usesCachedWeekdaySection ? cached?.weekdayFailure : failure,
      dailyFailure:
          _usesCachedDailyMonthlySections ? cached?.dailyFailure : failure,
      weekdayUserFailure: failure,
      lucratividadeFailure: _usesCachedLucratividadeSection
          ? cached?.lucratividadeFailure
          : failure,
      lucratividadeMensalFailure: includeLucratividadeMensal ? failure : null,
    );
  }

  OverviewBatchTargetResult _mapMainExecution({
    required AgentQueryTarget target,
    required int elapsedMs,
    required AgentSqlBatchExecutionResult execution,
    required _OverviewMainBatchCommandIndexes indexes,
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

  OverviewBatchTargetResult _mapSectionExecution({
    required AgentQueryTarget target,
    required int elapsedMs,
    required AgentSqlBatchExecutionResult execution,
    required _OverviewSectionBatchCommandIndexes indexes,
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
    final weekdayUser = OverviewSqlBatchItemRowsMapper.mapRowsForIndex(
      byIndex,
      indexes.weekdayUser,
      (row) => ResumoParcelasDiaSemanaUsuarioRowModel.fromMap(row).toEntity(),
    );
    _warnIfReachedMaxRows(
      target: target,
      section: 'weekdayUser',
      rowCount: weekdayUser.rows.length,
      maxRows: AgentQueriesBoundedResultMaxRows.resumoParcelasDiaSemanaUsuario,
    );
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
    final lucratividadeMensal = indexes.lucratividadeMensal == null
        ? const OverviewSqlBatchItemRowsResult<
            ResumoProdutoVendaLucratividadeMensalRow
          >(
            rows: <ResumoProdutoVendaLucratividadeMensalRow>[],
          )
        : OverviewSqlBatchItemRowsMapper.mapRowsForIndex(
            byIndex,
            indexes.lucratividadeMensal!,
            (row) => ResumoProdutoVendaLucratividadeMensalRowModel.fromMap(
              row,
            ).toEntity(),
          );
    if (indexes.lucratividadeMensal != null) {
      _warnIfReachedMaxRows(
        target: target,
        section: 'lucratividadeMensal',
        rowCount: lucratividadeMensal.rows.length,
        maxRows: AgentQueriesBoundedResultMaxRows
            .resumoProdutoVendaLucratividadeMensal,
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
      lucratividadeMensalRows: lucratividadeMensal.rows,
      monthlyFailure: monthly.failure,
      weekdayFailure: weekday.failure,
      dailyFailure: daily.failure,
      weekdayUserFailure: weekdayUser.failure,
      lucratividadeFailure: lucratividade.failure,
      lucratividadeMensalFailure: lucratividadeMensal.failure,
    );
  }

  /// Logs a warning when a batch item returns exactly [maxRows] rows. The
  /// hub caps result sets at the request's `max_rows`; reaching that bound
  /// means the section probably got truncated silently. Standalone repos
  /// (`resumoProdutoVendaLucratividade`, etc.) already do this; the overview
  /// section batch needs the same guard so deployments with many filiais are
  /// not surprised by missing rows.
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
                AgentQueryExecutionParticipant<ResumoParcelaFormaPagamentoRowV2>(
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
