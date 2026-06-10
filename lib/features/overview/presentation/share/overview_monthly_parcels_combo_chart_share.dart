import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_monthly_parcel_point.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_monthly_parcels_combo_chart.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_combo_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart'
    show formatComparisonBarXAxisLabelWrapped;
import 'package:colmeia/shared/widgets/charts/chart_export_capture.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:intl/intl.dart';

String overviewMonthlyParcelsXLabel(OverviewMonthlyParcelPoint point) =>
    formatComparisonBarXAxisLabelWrapped(
      point.anoMes,
      maxCharsPerLine: 11,
      maxLines: 3,
    );

num overviewMonthlyParcelsBarBySales(OverviewMonthlyParcelPoint point) =>
    point.qtdVendas;

num overviewMonthlyParcelsLineBySales(OverviewMonthlyParcelPoint point) =>
    point.valorParcela;

num overviewMonthlyParcelsBarByValue(OverviewMonthlyParcelPoint point) =>
    point.valorParcela;

num overviewMonthlyParcelsLineByValue(OverviewMonthlyParcelPoint point) =>
    point.qtdVendas;

ChartShareMetadata buildOverviewMonthlyParcelsComboShareMetadata({
  required AppLocalizations l10n,
  required List<OverviewMonthlyParcelPoint> points,
  required AppComboChartStyle exportBaseStyle,
  required bool valuePrimary,
  required MonthlyParcelsComboChartStrings? copy,
  required String title,
  required String subtitle,
  required NumberFormat decimalFormat,
  required NumberFormat compactCurrencyFormat,
}) {
  final salesHeader =
      copy?.seriesSalesLabel ?? l10n.overviewMonthlyParcelsSalesSeriesLabel;
  final amountHeader =
      copy?.seriesParcelAmountLabel ??
      l10n.overviewMonthlyParcelsAmountSeriesLabel;

  final tableLimit = applyChartShareTableRowLimit(
    tableData: ChartShareTableData(
      headers: <String>[
        l10n.chartSharePdfColumnMonth,
        salesHeader,
        amountHeader,
      ],
      rows: <List<String>>[
        for (final point in points)
          <String>[
            point.anoMes,
            decimalFormat.format(point.qtdVendas),
            AppBrFormatters.currency(point.valorParcela),
          ],
      ],
    ),
    truncationNoticeBuilder: (shownRows, totalRows) =>
        l10n.chartSharePdfTableRowsTruncated(shownRows, totalRows),
  );

  return ChartShareMetadata(
    title: title,
    subtitle: subtitle,
    filterSummary: tableLimit.truncationNotice,
    tableData: tableLimit.tableData,
    pdfOrientation: ChartSharePdfOrientation.landscape,
    chartExportBuilder: points.isEmpty
        ? null
        : (exportContext) {
            final exportStyle = exportBaseStyle.forPdfExport();
            String barDataLabel(OverviewMonthlyParcelPoint _, num value) =>
                valuePrimary
                ? compactCurrencyFormat.format(value)
                : decimalFormat.format(value);
            return wrapCartesianChartForPdfExport(
              context: exportContext,
              itemCount: points.length,
              minSlotWidth: exportStyle.minCategorySlotWidth,
              height: exportStyle.height,
              chart: AppComboChart<OverviewMonthlyParcelPoint>(
                items: points,
                xLabelBuilder: overviewMonthlyParcelsXLabel,
                barValueBuilder: valuePrimary
                    ? overviewMonthlyParcelsBarByValue
                    : overviewMonthlyParcelsBarBySales,
                barSeriesLabel: valuePrimary ? amountHeader : salesHeader,
                lineValueBuilder: valuePrimary
                    ? overviewMonthlyParcelsLineByValue
                    : overviewMonthlyParcelsLineBySales,
                lineSeriesLabel: valuePrimary ? salesHeader : amountHeader,
                barDataLabelBuilder: barDataLabel,
                style: exportStyle,
              ),
            );
          },
  );
}
