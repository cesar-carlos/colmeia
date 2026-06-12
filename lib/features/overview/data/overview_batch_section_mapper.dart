import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/mappers/daily_sales_trend_point_mapper.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report_resumo_parcelas.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row_v2.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/overview/data/mappers/overview_agent_resumo_mapper.dart';
import 'package:colmeia/features/overview/data/mappers/overview_monthly_parcel_mapper.dart';
import 'package:colmeia/features/overview/data/mappers/overview_weekday_sales_trend_mapper.dart';
import 'package:colmeia/features/overview/data/mappers/overview_weekday_user_sales_trend_mapper.dart';
import 'package:colmeia/features/overview/data/overview_batch_load_result.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_query_failure_detail.dart';
import 'package:colmeia/features/overview/domain/entities/overview_monthly_parcel_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_resumo_row.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_user_sales_trend_point.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_point.dart';

class OverviewBatchSectionFailure {
  const OverviewBatchSectionFailure({
    required this.loadFailed,
    this.failure,
  });

  final bool loadFailed;
  final AppFailure? failure;
}

/// Maps per-target batch SQL results into overview chart series and partial
/// failure details. Pure transformation — no I/O or cache side effects.
class OverviewBatchSectionMapper {
  const OverviewBatchSectionMapper();

  List<OverviewMonthlyParcelPoint> monthlyPoints(
    List<OverviewBatchTargetResult> results,
    ResumoParcelasMensalFilter filter, {
    required bool sectionLoadFailed,
    required AgentQueryExecutionStrategy strategy,
  }) {
    if (sectionLoadFailed) {
      return const <OverviewMonthlyParcelPoint>[];
    }
    final report = batchReport<ResumoParcelasMensalRow>(
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

  List<OverviewWeekdaySalesTrendPoint> weekdayPoints(
    List<OverviewBatchTargetResult> results, {
    required AgentQueryExecutionStrategy strategy,
  }) {
    final report = batchReport<ResumoParcelasDiaSemanaRow>(
      results,
      (result) => result.weekdayRows,
      (result) => result.weekdayFailure,
      queryKey: AgentQueryKey.resumoParcelasDiaSemana,
      strategy: strategy,
    );
    return overviewWeekdaySalesTrendPointsFromRows(report.chartRowsWeek);
  }

  List<DailySalesTrendPoint> dailyPoints(
    List<OverviewBatchTargetResult> results,
    ResumoTotalDiarioVendasFilter filter, {
    required bool sectionLoadFailed,
    required AgentQueryExecutionStrategy strategy,
  }) {
    if (sectionLoadFailed) {
      return const <DailySalesTrendPoint>[];
    }
    final report = batchReport<ResumoTotalDiarioVendasRow>(
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

  List<OverviewWeekdayUserSalesTrendPoint> weekdayUserPoints(
    List<OverviewBatchTargetResult> results, {
    required AgentQueryExecutionStrategy strategy,
  }) {
    final report = batchReport<ResumoParcelasDiaSemanaUsuarioRow>(
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

  List<ResumoProdutoVendaLucratividadeRow> lucratividadePoints(
    List<OverviewBatchTargetResult> results,
  ) {
    final rows = <ResumoProdutoVendaLucratividadeRow>[];
    for (final result in results) {
      if (result.lucratividadeFailure != null) {
        continue;
      }
      rows.add(
        aggregateLucratividadeBranchesForAgent(
          branches: result.lucratividadeRows,
          chartAxisLabel: result.target.displayName,
        ),
      );
    }
    return rows;
  }

  List<ResumoProdutoVendaLucratividadeMensalRow> lucratividadeMensalRows(
    List<OverviewBatchTargetResult> results,
  ) {
    return results
        .where((result) => result.lucratividadeMensalFailure == null)
        .expand((result) => result.lucratividadeMensalRows)
        .toList(growable: false);
  }

  Map<String, List<ResumoParcelaPorUsuarioRow>> userRankingRowsByAgentId(
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

  List<String> lucratividadePartialFailureAgentNames(
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

  List<OverviewAgentQueryFailureDetail> lucratividadePartialFailureDetails(
    List<OverviewBatchTargetResult> results,
  ) {
    return sectionPartialFailureDetails(
      results,
      failureOf: (result) => result.lucratividadeFailure,
      source: OverviewAgentQueryFailureSource.lucratividadePeriod,
    );
  }

  List<OverviewAgentQueryFailureDetail> sectionPartialFailureDetails(
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

  AgentQueryExecutionReport<Row> batchReport<Row>(
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
      missingClientTokenTargets: const [],
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

  OverviewBatchSectionFailure sectionFailure(
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
      return OverviewBatchSectionFailure(
        loadFailed: true,
        failure: firstFailure,
      );
    }
    return const OverviewBatchSectionFailure(loadFailed: false);
  }

  List<OverviewPaymentResumoRow> mapOverviewRows(
    List<ResumoParcelaFormaPagamentoRowV2> rows,
  ) {
    return rows
        .map(overviewPaymentResumoRowFromResumoParcelaFormaPagamentoRowV2)
        .toList(growable: false);
  }

  Map<String, List<OverviewPaymentResumoRow>> mapRowsByAgentId(
    Map<String, List<ResumoParcelaFormaPagamentoRowV2>> rowsByAgentId,
  ) {
    return <String, List<OverviewPaymentResumoRow>>{
      for (final entry in rowsByAgentId.entries)
        entry.key: mapOverviewRows(entry.value),
    };
  }

  ResumoProdutoVendaLucratividadeRow aggregateLucratividadeBranchesForAgent({
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
}
