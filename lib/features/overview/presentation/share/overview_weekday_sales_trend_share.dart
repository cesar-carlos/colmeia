import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/overview_weekday_display_order.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/charts/daily_sales_weekday_labels.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_dashboard_comparison_bar_chart_preset.dart';
import 'package:colmeia/shared/widgets/charts/chart_export_capture.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

List<OverviewWeekdaySalesTrendPoint> overviewWeekdaySalesTrendTableRows(
  List<OverviewWeekdaySalesTrendPoint> points,
) {
  final rows = List<OverviewWeekdaySalesTrendPoint>.of(points)
    ..sort(
      (a, b) => compareOverviewApiWeekdayDisplayOrder(
        a.weekdayNumber,
        b.weekdayNumber,
      ),
    );
  return rows;
}

ChartShareMetadata buildOverviewWeekdaySalesTrendShareMetadata({
  required AppLocalizations l10n,
  required AppThemeTokens tokens,
  required List<OverviewWeekdaySalesTrendPoint> chartPoints,
  required List<OverviewWeekdaySalesTrendPoint> tablePoints,
  required bool isSalesCountMetric,
  required NumberFormat salesCountFormat,
  required NumberFormat compactSalesCountFormat,
  required BuildContext styleContext,
}) {
  final inlineStyle = appDashboardComparisonBarChartStyle(
    tokens: tokens,
    kind: AppDashboardComparisonBarChartKind.weekday,
    l10n: l10n,
    weekdayUsesCurrencyAxis: !isSalesCountMetric,
    weekdayRevenueDataLabelBackground: isSalesCountMetric
        ? null
        : Theme.of(styleContext).colorScheme.surface,
  );

  final tableLimit = applyChartShareTableRowLimit(
    tableData: ChartShareTableData(
      headers: <String>[
        l10n.chartSharePdfColumnWeekday,
        l10n.overviewWeekdayMetricSalesCountLabel,
        l10n.overviewWeekdayMetricSalesAmountLabel,
      ],
      rows: <List<String>>[
        for (final point in tablePoints)
          <String>[
            dailySalesWeekdayLabel(point.weekdayNumber, l10n),
            salesCountFormat.format(point.salesCount),
            AppBrFormatters.currency(point.salesAmount),
          ],
      ],
    ),
    truncationNoticeBuilder: (shownRows, totalRows) =>
        l10n.chartSharePdfTableRowsTruncated(shownRows, totalRows),
  );

  return ChartShareMetadata(
    title: isSalesCountMetric
        ? l10n.overviewWeekdaySalesTitle
        : l10n.overviewWeekdayRevenueTitle,
    subtitle: l10n.overviewWeekdaySalesSubtitle,
    filterSummary: tableLimit.truncationNotice,
    tableData: tableLimit.tableData,
    pdfOrientation: ChartSharePdfOrientation.landscape,
    chartExportBuilder: chartPoints.isEmpty
        ? null
        : (exportContext) {
            final exportStyle = inlineStyle.forPdfExport();
            return wrapCartesianChartForPdfExport(
              context: exportContext,
              itemCount: chartPoints.length,
              minSlotWidth: comparisonBarMinSlotWidth(
                minBarWidth: exportStyle.minBarWidth,
              ),
              height: exportStyle.height,
              chart: AppComparisonBarChart<OverviewWeekdaySalesTrendPoint>(
                items: chartPoints,
                plotFloorAccessibilityNotice:
                    l10n.chartComparisonPlotFloorNotice,
                extremeSpreadAccessibilityNotice:
                    l10n.chartComparisonExtremeValueSpreadNotice,
                labelBuilder: (point) =>
                    dailySalesWeekdayLabel(point.weekdayNumber, l10n),
                valueBuilder: (point) => isSalesCountMetric
                    ? point.salesCount
                    : point.salesAmount,
                tooltipLabelBuilder: (point, value) =>
                    l10n.overviewWeekdaySalesTooltip(
                  dailySalesWeekdayLabel(point.weekdayNumber, l10n),
                  salesCountFormat.format(point.salesCount),
                  AppBrFormatters.currency(point.salesAmount),
                ),
                dataLabelBuilder: (_, value) => isSalesCountMetric
                    ? compactSalesCountFormat.format(value)
                    : AppBrFormatters.compactCurrency(value),
                style: exportStyle,
              ),
            );
          },
  );
}
