import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_row_merger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row_merger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_complete_week.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row_merger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_row_merger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_complete_period.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row_merger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_row_merger.dart';

extension AgentQueryExecutionReportResumoParcelasAnualRowsX
    on AgentQueryExecutionReport<ResumoParcelasAnualRow> {
  /// Per company, branch, and sale calendar year, aggregated from all
  /// successful participant rows.
  ///
  /// Summing `qtdVendas` across agents can overcount distinct sales if the
  /// same sale appears in more than one agent result. See
  /// `ResumoParcelasAnualRowMerger`.
  ///
  /// Import this library so the getter is in scope for the UI layer.
  List<ResumoParcelasAnualRow> get aggregatedMergedRows =>
      ResumoParcelasAnualRowMerger.merge(mergedRows);
}

extension AgentQueryExecutionReportResumoParcelasFormaPagamentoPorMesRowsX
    on AgentQueryExecutionReport<ResumoParcelasFormaPagamentoPorMesRow> {
  /// Per company, branch, user, `YYYY/MM`, and payment method, aggregated
  /// from participant rows.
  ///
  /// Import this library so the getter is in scope for the UI layer.
  List<ResumoParcelasFormaPagamentoPorMesRow> get aggregatedMergedRows =>
      ResumoParcelasFormaPagamentoPorMesRowMerger.merge(mergedRows);
}

extension AgentQueryExecutionReportResumoParcelasMensalRowsX
    on AgentQueryExecutionReport<ResumoParcelasMensalRow> {
  /// Per company, branch, and calendar month, aggregated from participant rows.
  ///
  /// See [ResumoParcelasMensalRowMerger] for semantics when multiple agents
  /// contribute rows for the same key.
  ///
  /// Import this library so the getter is in scope for the UI layer.
  List<ResumoParcelasMensalRow> get aggregatedMergedRows =>
      ResumoParcelasMensalRowMerger.merge(mergedRows);

  /// [aggregatedMergedRows] with every month in the [filter] sale range
  /// present (zeros for gaps). Branch-level rows are summed per month; see
  /// `ResumoParcelasMensalCompletePeriod.fill`. Use for charts and sparklines.
  List<ResumoParcelasMensalRow> chartRowsFilledPeriod(
    ResumoParcelasMensalFilter filter,
  ) {
    return ResumoParcelasMensalCompletePeriod.fill(
      dataVendaInicio: filter.dataVendaInicio,
      dataVendaFim: filter.dataVendaFim,
      rows: aggregatedMergedRows,
    );
  }
}

extension AgentQueryExecutionReportResumoVendaProdutoDiarioRowsX
    on AgentQueryExecutionReport<ResumoVendaProdutoDiarioRow> {
  /// Per sold product line and calendar day (and related dimensions),
  /// aggregated from participant rows. See
  /// [ResumoVendaProdutoDiarioRowMerger] for merge semantics across agents.
  ///
  /// Import this library so the getter is in scope for the UI layer.
  List<ResumoVendaProdutoDiarioRow> get aggregatedMergedRows =>
      ResumoVendaProdutoDiarioRowMerger.merge(mergedRows);
}

extension AgentQueryExecutionReportResumoVendasDiariasPorVendedorRowsX
    on AgentQueryExecutionReport<ResumoVendasDiariasPorVendedorRow> {
  /// Per company, branch, calendar day, month label, and seller dimensions,
  /// aggregated from participant rows. See
  /// [ResumoVendasDiariasPorVendedorRowMerger] for merge semantics across
  /// agents.
  ///
  /// Import this library so the getter is in scope for the UI layer.
  List<ResumoVendasDiariasPorVendedorRow> get aggregatedMergedRows =>
      ResumoVendasDiariasPorVendedorRowMerger.merge(mergedRows);
}

extension AgentQueryExecutionReportResumoParcelasDiaSemanaRowsX
    on AgentQueryExecutionReport<ResumoParcelasDiaSemanaRow> {
  /// Per company, branch, and weekday bucket, aggregated from participant rows.
  ///
  /// See [ResumoParcelasDiaSemanaRowMerger] for semantics when multiple agents
  /// contribute rows for the same key.
  ///
  /// Import this library so the getter is in scope for the UI layer.
  List<ResumoParcelasDiaSemanaRow> get aggregatedMergedRows =>
      ResumoParcelasDiaSemanaRowMerger.merge(mergedRows);

  /// Seven rows (Sunday–Saturday), zeros for missing weekdays.
  ///
  /// Unlike [aggregatedMergedRows], this builds one weekly series for the
  /// whole result set: `ResumoParcelasDiaSemanaCompleteWeek.fill` sums
  /// `qtdVendas` and `valorParcela` per weekday across all companies and
  /// branches and sets company and branch codes to
  /// `ResumoParcelasDiaSemanaRow.aggregatedBranchSentinel`. Use for charts
  /// that need a single line per weekday (not per filial).
  List<ResumoParcelasDiaSemanaRow> get chartRowsWeek =>
      ResumoParcelasDiaSemanaCompleteWeek.fill(aggregatedMergedRows);
}
