import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_row.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';

class _UserTotals {
  _UserTotals({required this.userName});

  final String userName;
  int totalSalesCount = 0;
  double totalAmount = 0;

  void add(int salesCount, double amount) {
    totalSalesCount += salesCount;
    totalAmount += amount;
  }

  double get averageTicket =>
      totalSalesCount == 0 ? 0 : totalAmount / totalSalesCount;
}

/// Builds [OverviewUserRanking] from per-branch user resumo rows.
///
/// Merges rows across branches by normalized user key (trim + lowercase).
/// Average ticket is `sum(amount) / sum(sales)` after merge.
List<OverviewUserRanking> overviewUserRankingsFromResumoParcelaPorUsuarioRows(
  List<ResumoParcelaPorUsuarioRow> rows, {
  required OverviewLoadLabels rowLabels,
}) {
  final buckets = <String, _UserTotals>{};
  for (final row in rows) {
    final displayName = overviewUserRankingDisplayName(
      row.nomeUsuario,
      rowLabels,
    );
    final key = overviewUserRankingNormalizeKey(row.nomeUsuario, rowLabels);
    buckets
        .putIfAbsent(key, () => _UserTotals(userName: displayName))
        .add(
          row.qtdVendas,
          row.valorParcela,
        );
  }
  final rankings =
      buckets.values
          .map(
            (t) => OverviewUserRanking(
              userName: t.userName,
              totalSalesCount: t.totalSalesCount,
              totalAmount: t.totalAmount,
              averageTicket: t.averageTicket,
            ),
          )
          .toList(growable: false)
        ..sort(_compareUsers);
  return rankings;
}

String overviewUserRankingDisplayName(
  String rawUserName,
  OverviewLoadLabels labels,
) {
  final normalized = rawUserName.trim();
  return normalized.isEmpty ? labels.unknownUserNameLabel : normalized;
}

String overviewUserRankingNormalizeKey(
  String rawUserName,
  OverviewLoadLabels labels,
) {
  return overviewUserRankingDisplayName(
    rawUserName,
    labels,
  ).toLowerCase();
}

int _compareUsers(OverviewUserRanking left, OverviewUserRanking right) {
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
