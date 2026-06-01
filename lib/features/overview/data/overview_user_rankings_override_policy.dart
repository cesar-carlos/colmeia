import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row_v2.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_row.dart';
import 'package:colmeia/features/overview/data/mappers/overview_user_ranking_mapper.dart';
import 'package:colmeia/features/overview/data/overview_batch_loader.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';

int overviewPaymentMergedRowCountV2(
  List<ResumoParcelaFormaPagamentoRowV2> paymentMergedRows,
) {
  return paymentMergedRows.length;
}

List<OverviewUserRanking>? overviewUserRankingsOverrideFromAcrossAgentsResult({
  required AppResult<AgentQueryExecutionReport<ResumoParcelaPorUsuarioRow>>
  userPorResult,
  required List<ResumoParcelaFormaPagamentoRowV2> paymentMergedRows,
  required String userId,
  required OverviewLoadLabels rowLabels,
  required String operation,
}) {
  final report = userPorResult.getOrNull();
  if (report != null) {
    if (report.mergedRows.isEmpty) {
      AppLogger.info(
        'Overview: per-user ranking resumo returned no rows; '
        'using payment-method aggregation for operator rankings',
        context: <String, Object?>{
          'operation': operation,
          'userId': userId,
          'queryKey': AgentQueryKey.resumoParcelaPorUsuario.name,
          'paymentRowCount': paymentMergedRows.length,
          'paymentRowCountV2': overviewPaymentMergedRowCountV2(paymentMergedRows),
        },
      );
      return null;
    }
    return overviewUserRankingsFromResumoParcelaPorUsuarioRows(
      report.mergedRows,
      rowLabels: rowLabels,
    );
  }
  final failure = userPorResult.exceptionOrNull();
  if (failure != null) {
    AppLogger.warning(
      'Overview: user ranking resumo failed; '
      'falling back to payment-method aggregation for operator rankings',
      context: <String, Object?>{
        'operation': operation,
        'userId': userId,
        'queryKey': AgentQueryKey.resumoParcelaPorUsuario.name,
        'failureType': failure.runtimeType.toString(),
      },
      error: failure,
    );
  }
  return null;
}

List<OverviewUserRanking>? overviewUserRankingsOverrideFromBatchTargetResults({
  required List<OverviewBatchTargetResult> batchResults,
  required List<ResumoParcelaFormaPagamentoRowV2> paymentMergedRows,
  required String userId,
  required OverviewLoadLabels rowLabels,
  required String operation,
}) {
  final merged = <ResumoParcelaPorUsuarioRow>[];
  var userRankingFailureTargets = 0;
  for (final result in batchResults) {
    if (result.mainFailure != null) {
      continue;
    }
    if (result.userRankingFailure != null) {
      userRankingFailureTargets++;
      continue;
    }
    merged.addAll(result.userRankingRows);
  }
  if (userRankingFailureTargets > 0 && merged.isEmpty) {
    AppLogger.warning(
      'Overview batch: user ranking SQL failed for every agent with a '
      'successful payment resumo; falling back to payment-method aggregation '
      'for operator rankings',
      context: <String, Object?>{
        'operation': operation,
        'userId': userId,
        'queryKey': AgentQueryKey.resumoParcelaPorUsuario.name,
        'userRankingFailureTargets': userRankingFailureTargets,
        'paymentRowCount': paymentMergedRows.length,
      },
    );
    return null;
  }
  if (userRankingFailureTargets > 0) {
    AppLogger.warning(
      'Overview batch: partial user ranking SQL failures; '
      'operator rankings omit failed agents',
      context: <String, Object?>{
        'operation': operation,
        'userId': userId,
        'queryKey': AgentQueryKey.resumoParcelaPorUsuario.name,
        'userRankingFailureTargets': userRankingFailureTargets,
        'mergedUserRowCount': merged.length,
      },
    );
  }
  if (merged.isEmpty) {
    AppLogger.info(
      'Overview batch: per-user ranking resumo returned no rows; '
      'using payment-method aggregation for operator rankings',
      context: <String, Object?>{
        'operation': operation,
        'userId': userId,
        'queryKey': AgentQueryKey.resumoParcelaPorUsuario.name,
        'paymentRowCount': paymentMergedRows.length,
        'paymentRowCountV2': overviewPaymentMergedRowCountV2(paymentMergedRows),
      },
    );
    return null;
  }
  return overviewUserRankingsFromResumoParcelaPorUsuarioRows(
    merged,
    rowLabels: rowLabels,
  );
}
