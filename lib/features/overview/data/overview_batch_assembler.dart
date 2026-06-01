import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/overview/data/mappers/overview_user_ranking_mapper.dart';
import 'package:colmeia/features/overview/data/overview_kpis_from_user_rows.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_query_failure_detail.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_monthly_parcel_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_resumo_row.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_user_sales_trend_point.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_point.dart';

/// Pure assembly of the [Overview] entity from already-mapped payment/user
/// rows and pre-computed chart series. Extracted from `OverviewRepositoryImpl`
/// so the (large) aggregation math lives in one focused, side-effect-free place
/// — no I/O, no clock, no cache. The repository keeps orchestration, failure
/// mapping and cache decisions.
class OverviewBatchAssembler {
  const OverviewBatchAssembler();

  Overview buildOverview(
    List<OverviewPaymentResumoRow> rows, {
    required Map<String, List<OverviewPaymentResumoRow>> rowsByAgentId,
    required Map<String, String> agentDisplayNamesById,
    required DateTime periodStart,
    required DateTime periodEnd,
    required int approvedAgentCount,
    required OverviewLoadLabels rowLabels,
    List<String> agentIdsExcludedFromQueryFailure = const <String>[],
    List<String> agentNamesExcludedFromQueryFailure = const <String>[],
    List<String> agentIdsMissingClientToken = const <String>[],
    List<String> agentNamesMissingClientToken = const <String>[],
    List<String> agentIdsSkippedDueToHubPresence = const <String>[],
    List<String> agentNamesSkippedDueToHubPresence = const <String>[],
    List<OverviewMonthlyParcelPoint> monthlyParcelTrend =
        const <OverviewMonthlyParcelPoint>[],
    bool monthlyParcelTrendLoadFailed = false,
    AppFailure? monthlyParcelTrendLoadFailure,
    String? monthlyParcelTrendLoadFailureMessage,
    List<OverviewWeekdaySalesTrendPoint> weekdaySalesTrend =
        const <OverviewWeekdaySalesTrendPoint>[],
    bool weekdaySalesTrendLoadFailed = false,
    AppFailure? weekdaySalesTrendLoadFailure,
    String? weekdaySalesTrendLoadFailureMessage,
    List<DailySalesTrendPoint> dailySalesTrend =
        const <DailySalesTrendPoint>[],
    bool dailySalesTrendLoadFailed = false,
    AppFailure? dailySalesTrendLoadFailure,
    String? dailySalesTrendLoadFailureMessage,
    List<OverviewWeekdayUserSalesTrendPoint> weekdayUserSalesTrend =
        const <OverviewWeekdayUserSalesTrendPoint>[],
    bool weekdayUserSalesTrendLoadFailed = false,
    AppFailure? weekdayUserSalesTrendLoadFailure,
    String? weekdayUserSalesTrendLoadFailureMessage,
    List<ResumoProdutoVendaLucratividadeMensalRow> lucratividadeMensalTrend =
        const <ResumoProdutoVendaLucratividadeMensalRow>[],
    bool lucratividadeMensalTrendLoadFailed = false,
    AppFailure? lucratividadeMensalTrendLoadFailure,
    String? lucratividadeMensalTrendLoadFailureMessage,
    List<ResumoProdutoVendaLucratividadeRow> lucratividadeTrend =
        const <ResumoProdutoVendaLucratividadeRow>[],
    bool lucratividadeTrendLoadFailed = false,
    AppFailure? lucratividadeTrendLoadFailure,
    String? lucratividadeTrendLoadFailureMessage,
    List<String> lucratividadePartialFailureAgentNames = const <String>[],
    bool mainResumoHadPlannedTargets = false,
    List<OverviewAgentQueryFailureDetail> partialQueryFailureDetails =
        const <OverviewAgentQueryFailureDetail>[],
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    List<OverviewUserRanking>? userRankingsOverride,
    Map<String, List<ResumoParcelaPorUsuarioRow>>? userRankingRowsByAgentId,
  }) {
    final paymentBuckets = <String, _PaymentMethodAggregate>{};
    final userBuckets = <String, _UserAggregate>{};

    var paymentTotalSalesCount = 0;
    var paymentTotalAmount = 0.0;

    for (final row in rows) {
      paymentTotalSalesCount += row.qtdVendas;
      paymentTotalAmount += row.valorParcela;

      final paymentKey =
          '${row.codFormaPagamento.trim()}'
          '|${row.descricaoFormaPagamento.trim()}';
      paymentBuckets
          .putIfAbsent(
            paymentKey,
            () => _PaymentMethodAggregate(
              code: row.codFormaPagamento.trim(),
              label: _resolvePaymentMethodLabel(row, rowLabels),
            ),
          )
          .add(row.qtdVendas, row.valorParcela);

      if (userRankingsOverride == null) {
        final userKey = overviewUserRankingNormalizeKey(
          row.nomeUsuario,
          rowLabels,
        );
        userBuckets
            .putIfAbsent(
              userKey,
              () => _UserAggregate(
                userName: overviewUserRankingDisplayName(
                  row.nomeUsuario,
                  rowLabels,
                ),
              ),
            )
            .add(row.qtdVendas, row.valorParcela);
      }
    }

    final paymentMethods =
        paymentBuckets.values
            .map(
              (item) => OverviewPaymentMethodBreakdown(
                code: item.code,
                label: item.label,
                totalSalesCount: item.totalSalesCount,
                totalAmount: item.totalAmount,
                averageTicket: item.averageTicket,
                sharePercent: paymentTotalAmount <= 0
                    ? 0
                    : item.totalAmount / paymentTotalAmount * 100,
              ),
            )
            .toList(growable: false)
          ..sort(_compareBreakdowns);

    // Prefer per-user resumo rows for KPIs and agent rankings: the
    // payment-method resumo over-counts sales paid with multiple forma_pagamento
    // (a single sale appears in N rows, one per method used). The per-user
    // resumo groups by `(branch, user)` only, so `COUNT(DISTINCT Id)` is
    // applied once per sale and sums are exact.
    final OverviewPaymentKpis kpis;
    final List<OverviewAgentRanking> agentRankings;
    if (userRankingRowsByAgentId != null &&
        userRankingRowsByAgentId.isNotEmpty) {
      final exact = overviewKpisAndAgentRankingsFromUserRankingRowsByAgent(
        source: OverviewKpisAndAgentRankingsSource(
          rowsByAgentId: userRankingRowsByAgentId,
          agentDisplayNamesById: agentDisplayNamesById,
          paymentMethodCount: paymentMethods.length,
        ),
      );
      kpis = exact.kpis;
      agentRankings = exact.agentRankings;
    } else {
      kpis = OverviewPaymentKpis(
        totalSalesCount: paymentTotalSalesCount,
        totalAmount: paymentTotalAmount,
        averageTicket: paymentTotalSalesCount == 0
            ? 0
            : paymentTotalAmount / paymentTotalSalesCount,
        paymentMethodCount: paymentMethods.length,
      );
      agentRankings =
          rowsByAgentId.entries
              .map((entry) {
                final agentId = entry.key;
                var sales = 0;
                var amount = 0.0;
                for (final row in entry.value) {
                  sales += row.qtdVendas;
                  amount += row.valorParcela;
                }
                return OverviewAgentRanking(
                  agentId: agentId,
                  displayName:
                      agentDisplayNamesById[agentId] ?? agentId.trim(),
                  totalSalesCount: sales,
                  totalAmount: amount,
                );
              })
              .toList(growable: false)
            ..sort(_compareAgents);
    }

    final userRankings =
        userRankingsOverride ??
              userBuckets.values
                  .map(
                    (item) => OverviewUserRanking(
                      userName: item.userName,
                      totalSalesCount: item.totalSalesCount,
                      totalAmount: item.totalAmount,
                      averageTicket: item.averageTicket,
                    ),
                  )
                  .toList(growable: false)
          ..sort(_compareUsers);

    return Overview(
      periodStart: periodStart,
      periodEnd: periodEnd,
      kpis: kpis,
      paymentMethods: paymentMethods,
      agentRankings: agentRankings,
      userRankings: userRankings,
      monthlyParcelTrend: monthlyParcelTrend,
      monthlyParcelTrendLoadFailed: monthlyParcelTrendLoadFailed,
      monthlyParcelTrendLoadFailure: monthlyParcelTrendLoadFailure,
      monthlyParcelTrendLoadFailureMessage:
          monthlyParcelTrendLoadFailureMessage,
      weekdaySalesTrend: weekdaySalesTrend,
      weekdaySalesTrendLoadFailed: weekdaySalesTrendLoadFailed,
      weekdaySalesTrendLoadFailure: weekdaySalesTrendLoadFailure,
      weekdaySalesTrendLoadFailureMessage: weekdaySalesTrendLoadFailureMessage,
      dailySalesTrend: dailySalesTrend,
      dailySalesTrendLoadFailed: dailySalesTrendLoadFailed,
      dailySalesTrendLoadFailure: dailySalesTrendLoadFailure,
      dailySalesTrendLoadFailureMessage: dailySalesTrendLoadFailureMessage,
      weekdayUserSalesTrend: weekdayUserSalesTrend,
      weekdayUserSalesTrendLoadFailed: weekdayUserSalesTrendLoadFailed,
      weekdayUserSalesTrendLoadFailure: weekdayUserSalesTrendLoadFailure,
      weekdayUserSalesTrendLoadFailureMessage:
          weekdayUserSalesTrendLoadFailureMessage,
      lucratividadeMensalTrend: lucratividadeMensalTrend,
      lucratividadeMensalTrendLoadFailed: lucratividadeMensalTrendLoadFailed,
      lucratividadeMensalTrendLoadFailure: lucratividadeMensalTrendLoadFailure,
      lucratividadeMensalTrendLoadFailureMessage:
          lucratividadeMensalTrendLoadFailureMessage,
      lucratividadeTrend: lucratividadeTrend,
      lucratividadeTrendLoadFailed: lucratividadeTrendLoadFailed,
      lucratividadeTrendLoadFailure: lucratividadeTrendLoadFailure,
      lucratividadeTrendLoadFailureMessage:
          lucratividadeTrendLoadFailureMessage,
      lucratividadePartialFailureAgentNames:
          lucratividadePartialFailureAgentNames,
      approvedAgentCount: approvedAgentCount,
      agentIdsExcludedFromQueryFailure: agentIdsExcludedFromQueryFailure,
      agentNamesExcludedFromQueryFailure: agentNamesExcludedFromQueryFailure,
      agentIdsMissingClientToken: agentIdsMissingClientToken,
      agentNamesMissingClientToken: agentNamesMissingClientToken,
      agentIdsSkippedDueToHubPresence: agentIdsSkippedDueToHubPresence,
      agentNamesSkippedDueToHubPresence: agentNamesSkippedDueToHubPresence,
      mainResumoHadPlannedTargets: mainResumoHadPlannedTargets,
      partialQueryFailureDetails: partialQueryFailureDetails,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
    );
  }

  String _resolvePaymentMethodLabel(
    OverviewPaymentResumoRow row,
    OverviewLoadLabels labels,
  ) {
    final description = row.descricaoFormaPagamento.trim();
    if (description.isNotEmpty) {
      return description;
    }
    final code = row.codFormaPagamento.trim();
    return code.isEmpty ? labels.unknownPaymentMethodLabel : code;
  }

  static int _compareBreakdowns(
    OverviewPaymentMethodBreakdown left,
    OverviewPaymentMethodBreakdown right,
  ) {
    final amount = right.totalAmount.compareTo(left.totalAmount);
    if (amount != 0) {
      return amount;
    }
    final sales = right.totalSalesCount.compareTo(left.totalSalesCount);
    if (sales != 0) {
      return sales;
    }
    return left.label.compareTo(right.label);
  }

  static int _compareAgents(
    OverviewAgentRanking left,
    OverviewAgentRanking right,
  ) {
    final amount = right.totalAmount.compareTo(left.totalAmount);
    if (amount != 0) {
      return amount;
    }
    final sales = right.totalSalesCount.compareTo(left.totalSalesCount);
    if (sales != 0) {
      return sales;
    }
    return left.displayName.compareTo(right.displayName);
  }

  static int _compareUsers(
    OverviewUserRanking left,
    OverviewUserRanking right,
  ) {
    final amount = right.totalAmount.compareTo(left.totalAmount);
    if (amount != 0) {
      return amount;
    }
    final sales = right.totalSalesCount.compareTo(left.totalSalesCount);
    if (sales != 0) {
      return sales;
    }
    return left.userName.compareTo(right.userName);
  }
}

class _PaymentMethodAggregate {
  _PaymentMethodAggregate({
    required this.code,
    required this.label,
  });

  final String code;
  final String label;
  int totalSalesCount = 0;
  double totalAmount = 0;

  double get averageTicket =>
      totalSalesCount == 0 ? 0 : totalAmount / totalSalesCount;

  void add(int salesCount, double amount) {
    totalSalesCount += salesCount;
    totalAmount += amount;
  }
}

class _UserAggregate {
  _UserAggregate({required this.userName});

  final String userName;
  int totalSalesCount = 0;
  double totalAmount = 0;

  double get averageTicket =>
      totalSalesCount == 0 ? 0 : totalAmount / totalSalesCount;

  void add(int salesCount, double amount) {
    totalSalesCount += salesCount;
    totalAmount += amount;
  }
}
