import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_row.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';

const double kRankingProdutosFaturamentoPercentSumTolerance = 0.5;

class BranchLeadProductInsight {
  const BranchLeadProductInsight({
    required this.productName,
    required this.percentual,
  });

  final String productName;
  final double percentual;
}

double branchRevenueTotal(List<RankingProdutosFaturamentoRow> rows) {
  return rows.fold<double>(0, (sum, row) => sum + row.valorVenda);
}

BranchLeadProductInsight? branchLeadProductInsight(
  List<RankingProdutosFaturamentoRow> rows,
) {
  for (final row in rows) {
    if (row.isDiversos) {
      continue;
    }
    final productName = row.nomeProduto.trim();
    return BranchLeadProductInsight(
      productName: productName.isEmpty
          ? RankingProdutosFaturamentoRow.diversosNomeProduto
          : productName,
      percentual: row.percentual,
    );
  }
  return null;
}

double branchPercentSum(List<RankingProdutosFaturamentoRow> rows) {
  return rows.fold<double>(0, (sum, row) => sum + row.percentual);
}

bool branchPercentSumDiverges(
  List<RankingProdutosFaturamentoRow> rows, {
  double tolerance = kRankingProdutosFaturamentoPercentSumTolerance,
}) {
  if (rows.isEmpty) {
    return false;
  }
  return (branchPercentSum(rows) - 100).abs() > tolerance;
}

List<RankingProdutosFaturamentoRow> sortRankingProdutosFaturamentoRows(
  List<RankingProdutosFaturamentoRow> rows,
  List<AppReportSortDescriptor> sorts,
) {
  final ranked = rows.where((row) => !row.isDiversos).toList(growable: false);
  final diversos = rows.where((row) => row.isDiversos).toList(growable: false);

  if (sorts.isEmpty) {
    return <RankingProdutosFaturamentoRow>[...ranked, ...diversos];
  }

  final sort = sorts.first;
  final sortedRanked = List<RankingProdutosFaturamentoRow>.from(ranked)
    ..sort((a, b) {
      final comparison = switch (sort.columnKey) {
        'venda' => a.valorVenda.compareTo(b.valorVenda),
        'percent' => a.percentual.compareTo(b.percentual),
        _ => 0,
      };
      if (comparison == 0) {
        return (a.posicao ?? 0).compareTo(b.posicao ?? 0);
      }
      return sort.direction == AppReportSortDirection.ascending
          ? comparison
          : -comparison;
    });

  return <RankingProdutosFaturamentoRow>[...sortedRanked, ...diversos];
}
