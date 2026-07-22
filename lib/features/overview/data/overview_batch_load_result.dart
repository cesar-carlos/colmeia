import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_plan.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row_v2.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';

final class OverviewBatchLoadResult {
  const OverviewBatchLoadResult({
    required this.resolution,
    required this.plan,
    required this.strategy,
    required this.targetResults,
    required this.mainResumoReport,
    required this.totalElapsedMs,
    this.isFinal = true,
    this.factsPersistedAgentIds = const <String>{},
  });

  final AgentQueryTargetResolution resolution;
  final AgentQueryPlan plan;
  final AgentQueryExecutionStrategy strategy;
  final List<OverviewBatchTargetResult> targetResults;
  final AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRowV2>
  mainResumoReport;
  final int totalElapsedMs;
  final bool isFinal;

  /// Agents whose daily/monthly fact buckets were written during this load.
  final Set<String> factsPersistedAgentIds;

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
    this.mainFailure,
    this.userRankingFailure,
    this.monthlyFailure,
    this.weekdayFailure,
    this.dailyFailure,
    this.weekdayUserFailure,
    this.lucratividadeFailure,
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
  final AppFailure? mainFailure;
  final AppFailure? userRankingFailure;
  final AppFailure? monthlyFailure;
  final AppFailure? weekdayFailure;
  final AppFailure? dailyFailure;
  final AppFailure? weekdayUserFailure;
  final AppFailure? lucratividadeFailure;

  bool get hasAnyFailure =>
      mainFailure != null ||
      userRankingFailure != null ||
      monthlyFailure != null ||
      weekdayFailure != null ||
      dailyFailure != null ||
      weekdayUserFailure != null ||
      lucratividadeFailure != null;

  bool get hasSectionFailure =>
      monthlyFailure != null ||
      weekdayFailure != null ||
      dailyFailure != null ||
      weekdayUserFailure != null ||
      lucratividadeFailure != null;
}
