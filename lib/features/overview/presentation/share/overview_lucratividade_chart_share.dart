import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_combo_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart'
    show formatComparisonBarXAxisLabelWrapped;
import 'package:colmeia/shared/widgets/charts/chart_export_capture.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

String overviewLucratividadeAgentXLabel(
  ResumoProdutoVendaLucratividadeRow row,
) => formatComparisonBarXAxisLabelWrapped(
  row.filialLabel,
  maxCharsPerLine: 11,
  maxLines: 3,
);

@immutable
class OverviewLucratividadeComboShareSeries {
  const OverviewLucratividadeComboShareSeries({
    required this.barValueBuilder,
    required this.lineValueBuilder,
    required this.barDataLabelBuilder,
    required this.barSeriesLabel,
    required this.lineSeriesLabel,
  });

  final num Function(ResumoProdutoVendaLucratividadeRow) barValueBuilder;
  final num Function(ResumoProdutoVendaLucratividadeRow) lineValueBuilder;
  final String Function(ResumoProdutoVendaLucratividadeRow, num)
  barDataLabelBuilder;
  final String barSeriesLabel;
  final String lineSeriesLabel;
}

ChartShareMetadata buildOverviewLucratividadeChartShareMetadata({
  required AppLocalizations l10n,
  required List<ResumoProdutoVendaLucratividadeRow> sortedPoints,
  required AppComboChartStyle exportBaseStyle,
  required OverviewLucratividadeComboShareSeries series,
}) {
  final tableLimit = applyChartShareTableRowLimit(
    tableData: ChartShareTableData(
      headers: <String>[
        l10n.chartSharePdfColumnAgent,
        l10n.chartSharePdfColumnRevenue,
        l10n.chartSharePdfColumnCost,
        l10n.chartSharePdfColumnProfit,
      ],
      rows: <List<String>>[
        for (final row in sortedPoints)
          <String>[
            row.filialLabel,
            AppBrFormatters.currency(row.valorTotalItem),
            AppBrFormatters.currency(row.custoReposicao),
            AppBrFormatters.currency(row.lucro),
          ],
      ],
    ),
    truncationNoticeBuilder: (shownRows, totalRows) =>
        l10n.chartSharePdfTableRowsTruncated(shownRows, totalRows),
  );

  return ChartShareMetadata(
    title: l10n.overviewLucratividadeTitle,
    subtitle: l10n.overviewLucratividadeSubtitle,
    filterSummary: tableLimit.truncationNotice,
    tableData: tableLimit.tableData,
    pdfOrientation: ChartSharePdfOrientation.landscape,
    chartExportBuilder: sortedPoints.isEmpty
        ? null
        : (exportContext) {
            final exportStyle = exportBaseStyle.forPdfExport();
            return wrapCartesianChartForPdfExport(
              context: exportContext,
              itemCount: sortedPoints.length,
              minSlotWidth: exportStyle.minCategorySlotWidth,
              height: exportStyle.height,
              chart: AppComboChart<ResumoProdutoVendaLucratividadeRow>(
                items: sortedPoints,
                xLabelBuilder: overviewLucratividadeAgentXLabel,
                barValueBuilder: series.barValueBuilder,
                barSeriesLabel: series.barSeriesLabel,
                lineValueBuilder: series.lineValueBuilder,
                lineSeriesLabel: series.lineSeriesLabel,
                barDataLabelBuilder: series.barDataLabelBuilder,
                style: exportStyle,
              ),
            );
          },
  );
}
