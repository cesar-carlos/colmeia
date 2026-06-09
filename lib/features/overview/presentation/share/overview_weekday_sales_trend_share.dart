import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/overview_weekday_display_order.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/charts/daily_sales_weekday_labels.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
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
  required List<OverviewWeekdaySalesTrendPoint> tablePoints,
  required bool isSalesCountMetric,
  required NumberFormat salesCountFormat,
}) {
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
  );
}
