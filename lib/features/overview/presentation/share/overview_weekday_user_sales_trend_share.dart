import 'dart:math' as math;

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_user_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/overview_weekday_display_order.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_weekday_user_grouped_bar_chart.dart';
import 'package:colmeia/features/overview/presentation/widgets/weekday_user_grouped_chart_data.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/charts/daily_sales_weekday_labels.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/chart_export_capture.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Mirrors [OverviewWeekdayUserGroupedBarChart] slot geometry for PDF export.
const double _kGroupedPerBarSlot = 18;
const double _kGroupedMinCategoryWidthFloor = 88;

List<OverviewWeekdayUserSalesTrendPoint> overviewWeekdayUserSalesTrendTableRows(
  List<OverviewWeekdayUserSalesTrendPoint> points,
) {
  final rows = List<OverviewWeekdayUserSalesTrendPoint>.of(points)
    ..sort((a, b) {
      final byWeekday = compareOverviewApiWeekdayDisplayOrder(
        a.weekdayNumber,
        b.weekdayNumber,
      );
      if (byWeekday != 0) {
        return byWeekday;
      }
      return a.userName.compareTo(b.userName);
    });
  return rows;
}

double _groupedChartMinCategoryWidth(int seriesCount) {
  return math.max(
    _kGroupedMinCategoryWidthFloor,
    math.max(1, seriesCount) * _kGroupedPerBarSlot,
  );
}

ChartShareMetadata buildOverviewWeekdayUserSalesTrendShareMetadata({
  required AppLocalizations l10n,
  required AppThemeTokens tokens,
  required List<OverviewWeekdayUserSalesTrendPoint> points,
  required List<OverviewWeekdayUserSalesTrendPoint> chartPoints,
  required bool isSalesCount,
  required String title,
  required NumberFormat salesCountFormat,
}) {
  final tableRows = overviewWeekdayUserSalesTrendTableRows(points);
  final tableLimit = applyChartShareTableRowLimit(
    tableData: ChartShareTableData(
      headers: <String>[
        l10n.chartSharePdfColumnWeekday,
        l10n.chartSharePdfColumnUser,
        l10n.overviewWeekdayMetricSalesCountLabel,
        l10n.overviewWeekdayMetricSalesAmountLabel,
      ],
      rows: <List<String>>[
        for (final point in tableRows)
          <String>[
            dailySalesWeekdayLabel(point.weekdayNumber, l10n),
            point.userName,
            salesCountFormat.format(point.salesCount),
            AppBrFormatters.currency(point.salesAmount),
          ],
      ],
    ),
    truncationNoticeBuilder: (shownRows, totalRows) =>
        l10n.chartSharePdfTableRowsTruncated(shownRows, totalRows),
  );

  final model = chartPoints.isEmpty
      ? null
      : buildWeekdayUserGroupedChartModel(
          points: chartPoints,
          l10n: l10n,
          useSalesCount: isSalesCount,
        );

  final seriesTruncationNotice = model != null && model.combinedRemainingUsers
      ? l10n.overviewWeekdayUserGroupedTruncationFootnote(
          kWeekdayUserGroupedMaxSeries - 1,
          l10n.overviewWeekdayUserGroupedOthersLabel,
        )
      : null;

  final exportPlotHeight =
      tokens.chartStandardHeight + tokens.contentSpacing * 2 + tokens.gapMd;

  return ChartShareMetadata(
    title: title,
    subtitle: l10n.overviewWeekdayUserSalesSubtitle,
    filterSummary: joinChartShareFilterSummary(
      filterSummary: seriesTruncationNotice,
      truncationNotice: tableLimit.truncationNotice,
    ),
    tableData: tableLimit.tableData,
    pdfOrientation: ChartSharePdfOrientation.landscape,
    chartExportBuilder: model == null
        ? null
        : (exportContext) {
            final exportTokens =
                Theme.of(exportContext).extension<AppThemeTokens>() ?? tokens;
            final categoryCount = math.max(
              1,
              model.weekdayCategoryLabels.length,
            );
            final minSlotWidth = _groupedChartMinCategoryWidth(
              model.userNames.length,
            );
            return wrapCartesianChartForPdfExport(
              context: exportContext,
              itemCount: categoryCount,
              minSlotWidth: minSlotWidth,
              height: exportPlotHeight + tokens.gapSm * 2 + 48,
              chart: OverviewWeekdayUserGroupedBarChart(
                l10n: l10n,
                model: model,
                isSalesCount: isSalesCount,
                title: title,
                subtitle: l10n.overviewWeekdayUserSalesSubtitle,
                belowSubtitle: const SizedBox.shrink(),
                plotFloorAccessibilityNotice:
                    l10n.chartComparisonPlotFloorNotice,
                extremeSpreadAccessibilityNotice:
                    l10n.chartComparisonExtremeValueSpreadNotice,
                tokens: exportTokens,
                useChartShell: false,
                chartHeightOverride: exportPlotHeight,
                animationDurationMs: 0,
              ),
            );
          },
  );
}
