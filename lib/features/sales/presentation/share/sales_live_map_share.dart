import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_store_sales_display_helpers.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
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
  ChartShareExportHeaderContext? exportHeaderContext,
  String? additionalFilterSummary,
}) {
  final orderedPoints = _orderedSharePoints(chartPoints);
  final tableLimit = applyChartShareTableRowLimit(
    tableData: ChartShareTableData(
      headers: <String>[
        l10n.chartSharePdfColumnStore,
        l10n.chartSharePdfColumnMunicipality,
        l10n.chartSharePdfColumnState,
        l10n.chartSharePdfColumnSalesCount,
        l10n.chartSharePdfColumnAmount,
      ],
      rows: <List<String>>[
        for (final point in orderedPoints) _shareRowForPoint(point),
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
    filterSummary: buildChartSharePdfFilterSummary(
      exportHeaderContext: exportHeaderContext,
      additionalFilterSummary: additionalFilterSummary,
      truncationNotice: tableLimit.truncationNotice,
    ),
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

/// Same ranking order as the desktop sidebar cards: revenue desc, then name.
List<AppBrazilStoreSalesPoint> _orderedSharePoints(
  List<AppBrazilStoreSalesPoint> chartPoints,
) {
  if (chartPoints.length < 2) {
    return chartPoints;
  }
  return List<AppBrazilStoreSalesPoint>.of(chartPoints, growable: false)
    ..sort(_compareSharePoints);
}

int _compareSharePoints(
  AppBrazilStoreSalesPoint left,
  AppBrazilStoreSalesPoint right,
) {
  final amount = right.salesAmount.compareTo(left.salesAmount);
  if (amount != 0) {
    return amount;
  }
  final salesCount = right.salesCount.compareTo(left.salesCount);
  if (salesCount != 0) {
    return salesCount;
  }
  return brazilMapBranchOrdinalName(left).compareTo(
    brazilMapBranchOrdinalName(right),
  );
}

List<String> _shareRowForPoint(AppBrazilStoreSalesPoint point) {
  final display = brazilMapBranchDisplayModel(point);
  final storeName = display.primaryName.trim().isEmpty
      ? (brazilMapTrimmedOrNull(point.name) ?? point.id)
      : display.primaryName;
  return <String>[
    storeName,
    brazilMapTrimmedOrNull(point.city) ?? '',
    AppBrazilStoreSalesMapData.normalizeUf(point.uf),
    point.salesCount.toString(),
    AppBrFormatters.currency(point.salesAmount),
  ];
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
        presentationMode:
            AppBrazilStoreSalesMapPresentationMode.cleanFullscreen,
      ),
    ),
  );
}
