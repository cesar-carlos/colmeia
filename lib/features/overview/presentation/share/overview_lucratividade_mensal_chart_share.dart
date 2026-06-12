import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_combo_chart.dart';
import 'package:colmeia/shared/widgets/charts/chart_export_capture.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

String overviewLucratividadeMensalXLabel(
  ResumoProdutoVendaLucratividadeMensalRow row,
) => row.anoMes;

@immutable
class OverviewLucratividadeMensalComboShareSeries {
  const OverviewLucratividadeMensalComboShareSeries({
    required this.barValueBuilder,
    required this.lineValueBuilder,
    required this.barDataLabelBuilder,
    required this.barSeriesLabel,
    required this.lineSeriesLabel,
  });

  final num Function(ResumoProdutoVendaLucratividadeMensalRow) barValueBuilder;
  final num Function(ResumoProdutoVendaLucratividadeMensalRow) lineValueBuilder;
  final String Function(ResumoProdutoVendaLucratividadeMensalRow, num)
  barDataLabelBuilder;
  final String barSeriesLabel;
  final String lineSeriesLabel;
}

ChartShareMetadata buildOverviewLucratividadeMensalChartShareMetadata({
  required AppLocalizations l10n,
  required List<ResumoProdutoVendaLucratividadeMensalRow> sortedPoints,
  required AppComboChartStyle exportBaseStyle,
  required OverviewLucratividadeMensalComboShareSeries series,
  ChartShareExportHeaderContext? exportHeaderContext,
}) {
  final tableLimit = applyChartShareTableRowLimit(
    tableData: ChartShareTableData(
      headers: <String>[
        l10n.chartSharePdfColumnMonth,
        l10n.chartSharePdfColumnRevenue,
        l10n.chartSharePdfColumnCost,
        l10n.chartSharePdfColumnProfit,
      ],
      rows: <List<String>>[
        for (final row in sortedPoints)
          <String>[
            row.anoMes,
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
    title: l10n.overviewLucratividadeMensalTitle,
    subtitle: l10n.overviewLucratividadeMensalSubtitle,
    filterSummary: buildChartSharePdfFilterSummary(
      exportHeaderContext: exportHeaderContext,
      truncationNotice: tableLimit.truncationNotice,
    ),
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
              chart: AppComboChart<ResumoProdutoVendaLucratividadeMensalRow>(
                items: sortedPoints,
                xLabelBuilder: overviewLucratividadeMensalXLabel,
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
