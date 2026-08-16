import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_columns.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';

ChartShareMetadata buildSalesMargemProdutoShareMetadata({
  required AppLocalizations l10n,
  required List<MargemProdutoRow> rows,
  ChartShareExportHeaderContext? exportHeaderContext,
}) {
  final tableLimit = applyChartShareTableRowLimit(
    tableData: ChartShareTableData.fromReportColumns(
      columns: buildSalesMargemProdutoColumns(
        labels: SalesMargemProdutoColumnLabels.fromL10n(l10n),
      ),
      rows: rows,
    ),
    truncationNoticeBuilder: (shownRows, totalRows) =>
        l10n.chartSharePdfTableRowsTruncated(shownRows, totalRows),
  );

  return ChartShareMetadata(
    title: l10n.salesCardMargemProdutoTitle,
    subtitle: l10n.salesMargemProdutoIntroSubtitle,
    includeChartImage: false,
    filterSummary: buildChartSharePdfFilterSummary(
      exportHeaderContext: exportHeaderContext,
      truncationNotice: tableLimit.truncationNotice,
    ),
    tableData: tableLimit.tableData,
  );
}
