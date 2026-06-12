import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_user_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/overview_weekday_display_order.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:colmeia/shared/widgets/charts/daily_sales_weekday_labels.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

ChartShareMetadata buildOverviewWeekdayUserSalesTrendShareMetadata({
  required AppLocalizations l10n,
  required List<OverviewWeekdayUserSalesTrendPoint> points,
  required bool isSalesCount,
  required String title,
  required NumberFormat salesCountFormat,
  ChartShareExportHeaderContext? exportHeaderContext,
  String? seriesTruncationNotice,
  WidgetBuilder? chartExportBuilder,
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

  return ChartShareMetadata(
    title: title,
    subtitle: l10n.overviewWeekdayUserSalesSubtitle,
    filterSummary: buildChartSharePdfFilterSummary(
      exportHeaderContext: exportHeaderContext,
      additionalFilterSummary: seriesTruncationNotice,
      truncationNotice: tableLimit.truncationNotice,
    ),
    tableData: tableLimit.tableData,
    pdfOrientation: ChartSharePdfOrientation.landscape,
    chartExportBuilder: chartExportBuilder,
  );
}
