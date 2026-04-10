import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_row_merger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row_merger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row_merger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_anual_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_anual_row_merger.dart';

extension AgentQueryExecutionReportResumoParcelasAnualRowsX
    on AgentQueryExecutionReport<ResumoParcelasAnualRow> {
  /// Per-year totals aggregated from all successful participant rows.
  ///
  /// Import this library so the getter is in scope for the UI layer.
  List<ResumoParcelasAnualRow> get aggregatedMergedRows =>
      ResumoParcelasAnualRowMerger.merge(mergedRows);
}

extension AgentQueryExecutionReportResumoParcelasFormaPagamentoAnualRowsX
    on AgentQueryExecutionReport<ResumoParcelasFormaPagamentoAnualRow> {
  /// Per year and payment method, aggregated from participant rows.
  ///
  /// Import this library so the getter is in scope for the UI layer.
  List<ResumoParcelasFormaPagamentoAnualRow> get aggregatedMergedRows =>
      ResumoParcelasFormaPagamentoAnualRowMerger.merge(mergedRows);
}

extension AgentQueryExecutionReportResumoParcelaFormaPagamentoDiarioRowsX
    on AgentQueryExecutionReport<ResumoParcelaFormaPagamentoDiarioRow> {
  /// Per calendar day and payment method, aggregated from participant rows.
  ///
  /// Import this library so the getter is in scope for the UI layer.
  List<ResumoParcelaFormaPagamentoDiarioRow> get aggregatedMergedRows =>
      ResumoParcelaFormaPagamentoDiarioRowMerger.merge(mergedRows);
}

extension AgentQueryExecutionReportResumoParcelasDiaSemanaRowsX
    on AgentQueryExecutionReport<ResumoParcelasDiaSemanaRow> {
  /// Per weekday bucket, aggregated from participant rows.
  ///
  /// Import this library so the getter is in scope for the UI layer.
  List<ResumoParcelasDiaSemanaRow> get aggregatedMergedRows =>
      ResumoParcelasDiaSemanaRowMerger.merge(mergedRows);
}
