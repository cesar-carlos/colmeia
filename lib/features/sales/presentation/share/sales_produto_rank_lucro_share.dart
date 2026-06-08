import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_sort_by.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:intl/intl.dart';

ChartShareMetadata buildSalesProdutoRankLucroShareMetadata({
  required AppLocalizations l10n,
  required List<ProdutoVendidoProdutoRankLucroRow> rows,
  required ProdutoVendidoProdutoRankLucroSortBy sortBy,
  required String periodSubtitle,
  required String branchName,
  required String metricLabel,
}) {
  final metricProfit =
      sortBy == ProdutoVendidoProdutoRankLucroSortBy.totalValorLucro;
  final quantityFormat = NumberFormat.decimalPattern(l10n.localeName);

  return ChartShareMetadata(
    title: l10n.salesProdutoRankLucroChartTitle,
    subtitle: periodSubtitle,
    filterSummary:
        '${l10n.salesBranchFilterLabel}: $branchName • '
        '${l10n.salesProdutoRankLucroFilterSortBy}: $metricLabel',
    tableData: ChartShareTableData.fromRanking(
      rankHeader: l10n.chartSharePdfColumnRank,
      nameHeader: l10n.chartSharePdfColumnName,
      amountHeader: metricProfit
          ? l10n.chartSharePdfColumnProfit
          : l10n.salesProdutoRankLucroSortQuantity,
      items: <({String name, String amount})>[
        for (final row in rows)
          (
            name: row.nomeProduto.trim(),
            amount: metricProfit
                ? AppBrFormatters.currency(row.totalValorLucro)
                : quantityFormat.format(row.qtdItensVendido),
          ),
      ],
    ),
  );
}
