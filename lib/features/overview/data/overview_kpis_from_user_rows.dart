import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_row.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';

/// Inputs for [overviewKpisAndAgentRankingsFromUserRankingRowsByAgent].
class OverviewKpisAndAgentRankingsSource {
  const OverviewKpisAndAgentRankingsSource({
    required this.rowsByAgentId,
    required this.agentDisplayNamesById,
    required this.paymentMethodCount,
  });

  /// Per-agent `ResumoParcelaPorUsuario` rows merged across branches by the
  /// repository.
  final Map<String, List<ResumoParcelaPorUsuarioRow>> rowsByAgentId;

  /// Display name to assign to each agent in the ranking output.
  final Map<String, String> agentDisplayNamesById;

  /// `paymentMethodCount` is the dimension count for the KPI bar; it stays
  /// derived from the payment-method breakdown because the per-user resumo has
  /// no payment-method axis.
  final int paymentMethodCount;
}

/// Result of [overviewKpisAndAgentRankingsFromUserRankingRowsByAgent].
class OverviewKpisAndAgentRankingsResult {
  const OverviewKpisAndAgentRankingsResult({
    required this.kpis,
    required this.agentRankings,
  });

  final OverviewPaymentKpis kpis;
  final List<OverviewAgentRanking> agentRankings;
}

/// Builds the home `OverviewPaymentKpis` and per-agent ranking from rows
/// emitted by `ResumoParcelaPorUsuarioSql`.
///
/// `ResumoParcelaPorUsuario` groups by `(CodEmpresa, CodFilial, NomeUsuario)`
/// and applies `COUNT(DISTINCT Id)` once per branch+user, so summing across
/// rows yields the correct distinct sale count for the period — unlike the
/// payment-method resumo, where a sale paid with N forma_pagamento appears in
/// N rows and naive `SUM(QtdVendas)` over-counts the sale by N − 1.
///
/// Caller must pass the per-agent rows already merged across branches (the
/// batch loader returns `userRankingRows` per target), so this helper just
/// folds per-agent and across agents. Average ticket is computed after both
/// aggregations to avoid the deflated ticket the payment-method aggregation
/// produced.
OverviewKpisAndAgentRankingsResult
overviewKpisAndAgentRankingsFromUserRankingRowsByAgent({
  required OverviewKpisAndAgentRankingsSource source,
}) {
  var totalSalesCount = 0;
  var totalAmount = 0.0;
  final agentRankings = <OverviewAgentRanking>[];
  for (final entry in source.rowsByAgentId.entries) {
    final agentId = entry.key;
    var sales = 0;
    var amount = 0.0;
    for (final row in entry.value) {
      sales += row.qtdVendas;
      amount += row.valorParcela;
    }
    totalSalesCount += sales;
    totalAmount += amount;
    agentRankings.add(
      OverviewAgentRanking(
        agentId: agentId,
        displayName: source.agentDisplayNamesById[agentId] ?? agentId.trim(),
        totalSalesCount: sales,
        totalAmount: amount,
      ),
    );
  }
  agentRankings.sort(_compareAgents);
  return OverviewKpisAndAgentRankingsResult(
    kpis: OverviewPaymentKpis(
      totalSalesCount: totalSalesCount,
      totalAmount: totalAmount,
      averageTicket: totalSalesCount == 0 ? 0 : totalAmount / totalSalesCount,
      paymentMethodCount: source.paymentMethodCount,
    ),
    agentRankings: agentRankings,
  );
}

int _compareAgents(OverviewAgentRanking left, OverviewAgentRanking right) {
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
