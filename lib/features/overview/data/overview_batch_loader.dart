import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcela_forma_pagamento_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_dia_semana_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_dia_semana_usuario_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_mensal_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_produto_venda_lucratividade_mensal_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_produto_venda_lucratividade_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_total_diario_vendas_row_model.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcela_forma_pagamento_sql.dart';
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
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/overview/data/overview_sql_batch_item_rows_mapper.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:result_dart/result_dart.dart';

final class OverviewBatchLoadResult {
  const OverviewBatchLoadResult({
    required this.resolution,
    required this.plan,
    required this.strategy,
    required this.targetResults,
    required this.mainResumoReport,
    required this.totalElapsedMs,
  });

  final AgentQueryTargetResolution resolution;
  final AgentQueryPlan plan;
  final AgentQueryExecutionStrategy strategy;
  final List<OverviewBatchTargetResult> targetResults;
  final AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>
  mainResumoReport;
  final int totalElapsedMs;
}

final class OverviewBatchTargetResult {
  const OverviewBatchTargetResult({
    required this.target,
    required this.elapsedMs,
    this.mainRows = const <ResumoParcelaFormaPagamentoRow>[],
    this.monthlyRows = const <ResumoParcelasMensalRow>[],
    this.weekdayRows = const <ResumoParcelasDiaSemanaRow>[],
    this.dailyRows = const <ResumoTotalDiarioVendasRow>[],
    this.weekdayUserRows = const <ResumoParcelasDiaSemanaUsuarioRow>[],
    this.lucratividadeRows = const <ResumoProdutoVendaLucratividadeRow>[],
    this.lucratividadeMensalRows =
        const <ResumoProdutoVendaLucratividadeMensalRow>[],
    this.mainFailure,
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
  final List<ResumoParcelasMensalRow> monthlyRows;
  final List<ResumoParcelasDiaSemanaRow> weekdayRows;
  final List<ResumoTotalDiarioVendasRow> dailyRows;
  final List<ResumoParcelasDiaSemanaUsuarioRow> weekdayUserRows;
  final List<ResumoProdutoVendaLucratividadeRow> lucratividadeRows;
  final List<ResumoProdutoVendaLucratividadeMensalRow> lucratividadeMensalRows;
  final AppFailure? mainFailure;
  final AppFailure? monthlyFailure;
  final AppFailure? weekdayFailure;
  final AppFailure? dailyFailure;
  final AppFailure? weekdayUserFailure;
  final AppFailure? lucratividadeFailure;
  final AppFailure? lucratividadeMensalFailure;
}

final class _OverviewBatchCommandIndexes {
  const _OverviewBatchCommandIndexes({
    required this.main,
    required this.monthly,
    required this.weekday,
    required this.daily,
    required this.weekdayUser,
    required this.lucratividade,
    this.lucratividadeMensal,
  });

  final int main;
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

class OverviewBatchLoader {
  const OverviewBatchLoader({
    required AgentQueryTargetResolver targetResolver,
    required AgentQueryPlanBuilder planBuilder,
    required AgentQueriesRepository agentQueriesRepository,
  }) : _targetResolver = targetResolver,
       _planBuilder = planBuilder,
       _agentQueriesRepository = agentQueriesRepository;

  final AgentQueryTargetResolver _targetResolver;
  final AgentQueryPlanBuilder _planBuilder;
  final AgentQueriesRepository _agentQueriesRepository;

  static const int overviewBatchBridgeTimeoutMs = 360000;
  static const int overviewBatchSqlTimeoutMs = 360000;
  static const int overviewBatchMaxRows =
      AgentQueriesBoundedResultMaxRows.resumoParcelasMensal;

  Future<AppResult<OverviewBatchLoadResult>> load({
    required String userId,
    required OverviewFilter filter,
    required DateTime periodStart,
    required DateTime periodEnd,
    required ({DateTime dataVendaInicio, DateTime dataVendaFim}) last12Range,
    required ResumoParcelasMensalFilter mensalFilter,
    required ResumoParcelasDiaSemanaFilter weekdayFilter,
    required ResumoTotalDiarioVendasFilter dailyTotalFilter,
    required AgentQueryExecutionStrategy executionStrategy,
  }) async {
    final resolutionResult = await _targetResolver.resolve(
      userId: userId,
      selectedAgentIds: filter.selectedAgentIds,
    );
    final resolution = resolutionResult.getOrNull();
    if (resolution == null) {
      return Failure<OverviewBatchLoadResult, AppFailure>(
        resolutionResult.exceptionOrNull()!,
      );
    }

    final planResult = _planBuilder.build(
      queryKey: AgentQueryKey.resumoParcelaFormaPagamento,
      strategy: executionStrategy,
      resolution: resolution,
      bridgeTimeoutMs: overviewBatchBridgeTimeoutMs,
    );
    final plan = planResult.getOrNull();
    if (plan == null) {
      return Failure<OverviewBatchLoadResult, AppFailure>(
        planResult.exceptionOrNull()!,
      );
    }

    final selectedNorm = _normalizeSelectedAgentIds(filter.selectedAgentIds);
    final includeLucratividadeMensal =
        selectedNorm != null && selectedNorm.length == 1;
    final started = DateTime.now();
    final targetResults = await Future.wait(
      plan.plannedTargets.map(
        (target) => _loadForTarget(
          userId: userId,
          target: target,
          planBridgeTimeoutMs: plan.bridgeTimeoutMs,
          periodStart: periodStart,
          periodEnd: periodEnd,
          last12Range: last12Range,
          mensalFilter: mensalFilter,
          weekdayFilter: weekdayFilter,
          dailyTotalFilter: dailyTotalFilter,
          includeLucratividadeMensal: includeLucratividadeMensal,
          hubPresenceOnlineAgentIdsSnapshot:
              resolution.hubPresenceOnlineAgentIdsSnapshot,
        ),
      ),
    );
    final totalElapsedMs = DateTime.now().difference(started).inMilliseconds;
    final report = _buildMainResumoReport(
      strategy: executionStrategy,
      plan: plan,
      targetResults: targetResults,
      totalElapsedMs: totalElapsedMs,
    );

    return Success<OverviewBatchLoadResult, AppFailure>(
      OverviewBatchLoadResult(
        resolution: resolution,
        plan: plan,
        strategy: executionStrategy,
        targetResults: targetResults,
        mainResumoReport: report,
        totalElapsedMs: totalElapsedMs,
      ),
    );
  }

  Future<OverviewBatchTargetResult> _loadForTarget({
    required String userId,
    required AgentQueryTarget target,
    required int planBridgeTimeoutMs,
    required DateTime periodStart,
    required DateTime periodEnd,
    required ({DateTime dataVendaInicio, DateTime dataVendaFim}) last12Range,
    required ResumoParcelasMensalFilter mensalFilter,
    required ResumoParcelasDiaSemanaFilter weekdayFilter,
    required ResumoTotalDiarioVendasFilter dailyTotalFilter,
    required bool includeLucratividadeMensal,
    required Set<String>? hubPresenceOnlineAgentIdsSnapshot,
  }) async {
    final started = DateTime.now();
    final batch = _buildCommands(
      periodStart: periodStart,
      periodEnd: periodEnd,
      last12Range: last12Range,
      mensalFilter: mensalFilter,
      weekdayFilter: weekdayFilter,
      dailyTotalFilter: dailyTotalFilter,
      includeLucratividadeMensal: includeLucratividadeMensal,
    );
    // `sql.executeBatch` is a unary bridge call. Keep the overview on the
    // configured base transport (REST or `agents:command`) until relay batch
    // has the same real-world timeout behaviour for the full home command set.
    final result = await _agentQueriesRepository.executeSqlBatch(
      AgentSqlExecuteBatchRequest(
        agentId: target.agentId,
        requestingUserId: userId,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow:
            target.hubConnectedFromApprovedCatalogRow,
        commands: batch.commands,
        clientToken: target.clientToken,
        bridgeTimeoutMs: planBridgeTimeoutMs,
        options: const AgentSqlExecuteBatchOptions(
          sqlTimeoutMs: overviewBatchSqlTimeoutMs,
          maxRows: overviewBatchMaxRows,
          transaction: false,
        ),
      ),
    );
    final elapsedMs = DateTime.now().difference(started).inMilliseconds;
    final execution = result.getOrNull();
    if (execution == null) {
      final failure = result.exceptionOrNull()!;
      return _targetResultWithAllFailures(
        target: target,
        elapsedMs: elapsedMs,
        failure: failure,
        includeLucratividadeMensal: includeLucratividadeMensal,
      );
    }

    return _mapExecution(
      target: target,
      elapsedMs: elapsedMs,
      execution: execution,
      indexes: batch.indexes,
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

  OverviewBatchTargetResult _targetResultWithAllFailures({
    required AgentQueryTarget target,
    required int elapsedMs,
    required AppFailure failure,
    required bool includeLucratividadeMensal,
  }) {
    return OverviewBatchTargetResult(
      target: target,
      elapsedMs: elapsedMs,
      mainFailure: failure,
      monthlyFailure: failure,
      weekdayFailure: failure,
      dailyFailure: failure,
      weekdayUserFailure: failure,
      lucratividadeFailure: failure,
      lucratividadeMensalFailure: includeLucratividadeMensal ? failure : null,
    );
  }

  OverviewBatchTargetResult _mapExecution({
    required AgentQueryTarget target,
    required int elapsedMs,
    required AgentSqlBatchExecutionResult execution,
    required _OverviewBatchCommandIndexes indexes,
  }) {
    final byIndex = <int, AgentSqlBatchExecutionItem>{
      for (final item in execution.items) item.index: item,
    };

    final main = OverviewSqlBatchItemRowsMapper.mapRowsForIndex(
      byIndex,
      indexes.main,
      (row) => ResumoParcelaFormaPagamentoRowModel.fromMap(row).toEntity(),
    );
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
      mainRows: main.rows,
      monthlyRows: monthly.rows,
      weekdayRows: weekday.rows,
      dailyRows: daily.rows,
      weekdayUserRows: weekdayUser.rows,
      lucratividadeRows: lucratividade.rows,
      lucratividadeMensalRows: lucratividadeMensal.rows,
      mainFailure: main.failure,
      monthlyFailure: monthly.failure,
      weekdayFailure: weekday.failure,
      dailyFailure: daily.failure,
      weekdayUserFailure: weekdayUser.failure,
      lucratividadeFailure: lucratividade.failure,
      lucratividadeMensalFailure: lucratividadeMensal.failure,
    );
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
