import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_read_only_batch_options.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcela_forma_pagamento_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcela_por_usuario_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_dia_semana_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_dia_semana_usuario_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_mensal_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_produto_venda_lucratividade_mensal_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_produto_venda_lucratividade_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_total_diario_vendas_row_model.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_transport_policy.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcela_forma_pagamento_sql.dart';
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
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_plan.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
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
  final AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>
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
    this.mainRows = const <ResumoParcelaFormaPagamentoRow>[],
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
  final List<ResumoParcelaFormaPagamentoRow> mainRows;
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
  final int monthly;
  final int weekday;
  final int daily;
  final int weekdayUser;
  final int lucratividade;
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
    required this.monthly,
    required this.weekday,
    required this.daily,
    required this.weekdayUser,
    required this.lucratividade,
    this.lucratividadeMensal,
  });

  final int monthly;
  final int weekday;
  final int daily;
  final int weekdayUser;
  final int lucratividade;
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
    int maxParallelReadOnlyBatchItems = 4,
    AgentQueryTransportPolicy? transportPolicy,
  }) : _targetResolver = targetResolver,
       _planBuilder = planBuilder,
       _agentQueriesRepository = agentQueriesRepository,
       _maxParallelReadOnlyBatchItems = maxParallelReadOnlyBatchItems,
       _transportPolicy = transportPolicy ??
           AgentQueryTransportPolicy(
             mode: AppEnvironment.agentQueryTransportPolicyMode,
           );

  final AgentQueryTargetResolver _targetResolver;
  final AgentQueryPlanBuilder _planBuilder;
  final AgentQueriesRepository _agentQueriesRepository;
  final int _maxParallelReadOnlyBatchItems;
  final AgentQueryTransportPolicy _transportPolicy;

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
  }) async* {
    final resolutionResult = await _targetResolver.resolve(
      userId: userId,
      selectedAgentIds: filter.selectedAgentIds,
    );
    final resolution = resolutionResult.getOrNull();
    if (resolution == null) {
      yield Failure<OverviewBatchLoadResult, AppFailure>(
        resolutionResult.exceptionOrNull()!,
      );
      return;
    }

    final planResult = _planBuilder.build(
      queryKey: AgentQueryKey.resumoParcelaFormaPagamento,
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
    );
    final started = DateTime.now();
    final targets = plan.plannedTargets.toList();
    final pendingPairs =
        await Future.wait<
          (OverviewBatchTargetResult, Future<OverviewBatchTargetResult>?)
        >(
          targets.map((target) async {
            final mainR = await _loadMainForTarget(
              userId: userId,
              target: target,
              planBridgeTimeoutMs: plan.bridgeTimeoutMs,
              batch: mainBatch,
              hubPresenceOnlineAgentIdsSnapshot:
                  resolution.hubPresenceOnlineAgentIdsSnapshot,
              cancelScope: cancelScope,
            );
            final sectionFuture =
                mainR.mainFailure == null
                ? _loadSectionsForTarget(
                    userId: userId,
                    target: target,
                    planBridgeTimeoutMs: plan.bridgeTimeoutMs,
                    batch: sectionBatch,
                    includeLucratividadeMensal: includeLucratividadeMensal,
                    hubPresenceOnlineAgentIdsSnapshot:
                        resolution.hubPresenceOnlineAgentIdsSnapshot,
                    cancelScope: cancelScope,
                  )
                : null;
            return (mainR, sectionFuture);
          }),
        );
    final mainResults = pendingPairs
        .map((pair) => pair.$1)
        .toList(growable: false);
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

    final combinedResults = await Future.wait(
      pendingPairs.map((pair) async {
        final mainR = pair.$1;
        final sectionFuture = pair.$2;
        if (sectionFuture == null) {
          return mainR;
        }
        final sections = await sectionFuture;
        return _combineMainAndSectionResults(
          mainResults: <OverviewBatchTargetResult>[mainR],
          sectionResults: <OverviewBatchTargetResult>[sections],
        ).single;
      }),
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
    required bool includeLucratividadeMensal,
    required Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    AgentQueriesCancelScope? cancelScope,
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
      return _targetResultWithSectionFailures(
        target: target,
        elapsedMs: elapsedMs,
        failure: failure,
        includeLucratividadeMensal: includeLucratividadeMensal,
      );
    }

    return _mapSectionExecution(
      target: target,
      elapsedMs: elapsedMs,
      execution: execution,
      indexes: batch.indexes,
    );
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
        sql: ResumoParcelaFormaPagamentoSql.query,
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
  }) {
    final full = _buildCommands(
      periodStart: dailyTotalFilter.dataVendaInicio,
      periodEnd: dailyTotalFilter.dataVendaFim,
      last12Range: last12Range,
      mensalFilter: mensalFilter,
      weekdayFilter: weekdayFilter,
      dailyTotalFilter: dailyTotalFilter,
      includeLucratividadeMensal: includeLucratividadeMensal,
    );
    final commands = full.commands
        .skip(_overviewBatchMainCommandCount)
        .toList(growable: false);
    const mainOffset = _overviewBatchMainCommandCount;
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
      indexes: _OverviewSectionBatchCommandIndexes(
        monthly: full.indexes.monthly - mainOffset,
        weekday: full.indexes.weekday - mainOffset,
        daily: full.indexes.daily - mainOffset,
        weekdayUser: full.indexes.weekdayUser - mainOffset,
        lucratividade: full.indexes.lucratividade - mainOffset,
        lucratividadeMensal: full.indexes.lucratividadeMensal == null
            ? null
            : full.indexes.lucratividadeMensal! - mainOffset,
      ),
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
      ResumoParcelaFormaPagamentoSql.query,
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
    final monthly = add(
      ResumoParcelasMensalSql.query(
        codEmpresa: mensalFilter.codEmpresa,
        codFilial: mensalFilter.codFilial,
        codVendedor: mensalFilter.codVendedor,
      ),
      _parcelPeriodSqlParamsFromMensal(mensalFilter),
    );
    final weekday = add(
      ResumoParcelasDiaSemanaSql.query(
        codEmpresa: weekdayFilter.codEmpresa,
        codFilial: weekdayFilter.codFilial,
        codVendedor: weekdayFilter.codVendedor,
      ),
      _parcelPeriodSqlParamsFromWeekday(weekdayFilter),
    );
    final daily = add(
      ResumoTotalDiarioVendasSql.query,
      _produtoVendidoPeriodParams(dailyTotalFilter),
    );
    final weekdayUser = add(
      ResumoParcelasDiaSemanaUsuarioSql.query(
        codEmpresa: weekdayFilter.codEmpresa,
        codFilial: weekdayFilter.codFilial,
        codVendedor: weekdayFilter.codVendedor,
      ),
      _parcelPeriodSqlParamsFromWeekday(weekdayFilter),
    );
    final lucratividade = add(
      ResumoProdutoVendaLucratividadeSql.query,
      _lucratividadeParams(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
      ),
    );
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
  }) {
    return OverviewBatchTargetResult(
      target: target,
      elapsedMs: elapsedMs,
      monthlyFailure: failure,
      weekdayFailure: failure,
      dailyFailure: failure,
      weekdayUserFailure: failure,
      lucratividadeFailure: failure,
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
      (row) => ResumoParcelaFormaPagamentoRowModel.fromMap(row).toEntity(),
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

    final monthly = OverviewSqlBatchItemRowsMapper.mapRowsForIndex(
      byIndex,
      indexes.monthly,
      (row) => ResumoParcelasMensalRowModel.fromMap(row).toEntity(),
    );
    final weekday = OverviewSqlBatchItemRowsMapper.mapRowsForIndex(
      byIndex,
      indexes.weekday,
      (row) => ResumoParcelasDiaSemanaRowModel.fromMap(row).toEntity(),
    );
    final daily = OverviewSqlBatchItemRowsMapper.mapRowsForIndex(
      byIndex,
      indexes.daily,
      (row) => ResumoTotalDiarioVendasRowModel.fromMap(row).toEntity(),
    );
    final weekdayUser = OverviewSqlBatchItemRowsMapper.mapRowsForIndex(
      byIndex,
      indexes.weekdayUser,
      (row) => ResumoParcelasDiaSemanaUsuarioRowModel.fromMap(row).toEntity(),
    );
    final lucratividade = OverviewSqlBatchItemRowsMapper.mapRowsForIndex(
      byIndex,
      indexes.lucratividade,
      (row) => ResumoProdutoVendaLucratividadeRowModel.fromMap(row).toEntity(),
    );
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

  AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>
  _buildMainResumoReport({
    required AgentQueryExecutionStrategy strategy,
    required AgentQueryPlan plan,
    required List<OverviewBatchTargetResult> targetResults,
    required int totalElapsedMs,
  }) {
    return AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>(
      queryKey: AgentQueryKey.resumoParcelaFormaPagamento,
      strategy: strategy,
      consideredApprovedAgentCount: plan.consideredApprovedAgentCount,
      plannedTargets: plan.plannedTargets,
      missingClientTokenTargets: plan.missingClientTokenTargets,
      skippedDueToHubPresenceTargets: plan.skippedDueToHubPresenceTargets,
      totalElapsedMs: totalElapsedMs,
      participants: targetResults
          .map(
            (result) =>
                AgentQueryExecutionParticipant<ResumoParcelaFormaPagamentoRow>(
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
