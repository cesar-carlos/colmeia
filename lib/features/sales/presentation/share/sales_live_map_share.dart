import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter/material.dart';

const double _kLiveMapPdfExportWidth = 880;
const double _kLiveMapPdfExportHeight = 440;

ChartShareMetadata buildSalesLiveMapShareMetadata({
  required AppLocalizations l10n,
  required String title,
  required List<AppBrazilStoreSalesPoint> chartPoints,
  String? subtitle,
  AppBrazilStoreSalesMapMetric? exportMetric,
  AppBrazilStoreSalesMapStyle? exportStyle,
  Set<String>? filterBranchIds,
}) {
  final tableLimit = applyChartShareTableRowLimit(
    tableData: ChartShareTableData(
      headers: <String>[
        l10n.chartSharePdfColumnStore,
        l10n.chartSharePdfColumnSalesCount,
        l10n.chartSharePdfColumnAmount,
      ],
      rows: <List<String>>[
        for (final point in chartPoints)
          <String>[
            point.name,
            point.salesCount.toString(),
            AppBrFormatters.currency(point.salesAmount),
          ],
      ],
    ),
    truncationNoticeBuilder: (shownRows, totalRows) =>
        l10n.chartSharePdfTableRowsTruncated(shownRows, totalRows),
  );

  final resolvedExportMetric = exportMetric;
  final resolvedExportStyle = exportStyle;
  final resolvedFilterBranchIds = filterBranchIds;

  return ChartShareMetadata(
    title: title,
    subtitle: subtitle,
    filterSummary: tableLimit.truncationNotice,
    tableData: tableLimit.tableData,
    pdfOrientation: ChartSharePdfOrientation.landscape,
    chartExportBuilder:
        chartPoints.isEmpty ||
            resolvedExportMetric == null ||
            resolvedExportStyle == null ||
            resolvedFilterBranchIds == null
        ? null
        : (exportContext) => _liveMapPdfExport(
            exportContext: exportContext,
            points: chartPoints,
            metric: resolvedExportMetric,
            style: resolvedExportStyle,
            filterBranchIds: resolvedFilterBranchIds,
          ),
  );
}

Widget _liveMapPdfExport({
  required BuildContext exportContext,
  required List<AppBrazilStoreSalesPoint> points,
  required AppBrazilStoreSalesMapMetric metric,
  required AppBrazilStoreSalesMapStyle style,
  required Set<String> filterBranchIds,
}) {
  return ColoredBox(
    color: Theme.of(exportContext).colorScheme.surface,
    child: SizedBox(
      width: _kLiveMapPdfExportWidth,
      height: _kLiveMapPdfExportHeight,
      child: AppBrazilStoreSalesMapChart(
        points: points,
        initialMetric: metric,
        filterBranchIds: filterBranchIds,
        fixedBranchIds: filterBranchIds,
        style: style.copyWith(height: _kLiveMapPdfExportHeight),
        presentationMode: AppBrazilStoreSalesMapPresentationMode.cleanFullscreen,
      ),
    ),
  );
}
