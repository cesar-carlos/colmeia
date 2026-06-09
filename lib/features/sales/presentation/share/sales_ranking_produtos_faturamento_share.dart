import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_ranking_produtos_faturamento_grid_columns.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';

ChartShareMetadata buildSalesRankingProdutosFaturamentoShareMetadata({
  required AppLocalizations l10n,
  required String branchTitle,
  required String metricSubtitle,
  required List<RankingProdutosFaturamentoRow> displayRows,
}) {
  final tableLimit = applyChartShareTableRowLimit(
    tableData: ChartShareTableData.fromReportColumns(
      columns: rankingProdutosFaturamentoGridColumns(l10n),
      rows: displayRows,
    ),
    truncationNoticeBuilder: (shownRows, totalRows) =>
        l10n.chartSharePdfTableRowsTruncated(shownRows, totalRows),
  );

  return ChartShareMetadata(
    title: branchTitle,
    subtitle: metricSubtitle,
    filterSummary: tableLimit.truncationNotice,
    tableData: tableLimit.tableData,
  );
}
