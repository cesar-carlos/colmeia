import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/dashboard_lucratividade_percent_metrics.dart';
import 'package:colmeia/features/sales/domain/entities/sales_monthly_pnl_point.dart';
import 'package:colmeia/features/sales/domain/sales_monthly_pnl_bar_chart_preferences.dart';
import 'package:colmeia/features/sales/domain/sales_monthly_pnl_point_percent_metric.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_dashboard_comparison_bar_chart_preset.dart';
import 'package:colmeia/shared/widgets/charts/chart_export_capture.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

ChartShareMetadata buildSalesMonthlyPnlBarChartShareMetadata({
  required AppLocalizations l10n,
  required List<SalesMonthlyPnlPoint> points,
  required SalesMonthlyPnlBarChartPreferences session,
  required AppThemeTokens tokens,
  required AppChartTheme chartTheme,
  required String localeTag,
  required NumberFormat primaryMoney,
  required Color gridLineColor,
  required NumberFormat percentRatioFormat,
}) {
  final isPercent =
      session.displayMode == SalesMonthlyPnlBarDisplayMode.percent;
  final metric = session.percentMetric;

  final tableLimit = applyChartShareTableRowLimit(
    tableData: ChartShareTableData(
      headers: <String>[
        l10n.chartSharePdfColumnMonth,
        l10n.chartSharePdfColumnRevenue,
        l10n.chartSharePdfColumnCost,
        l10n.chartSharePdfColumnProfit,
      ],
      rows: <List<String>>[
        for (final point in points)
          <String>[
            point.anoMes,
            AppBrFormatters.currency(point.venda),
            AppBrFormatters.currency(point.custoMercadoria),
            AppBrFormatters.currency(point.lucro),
          ],
      ],
    ),
    truncationNoticeBuilder: (shownRows, totalRows) =>
        l10n.chartSharePdfTableRowsTruncated(shownRows, totalRows),
  );

  return ChartShareMetadata(
    title: l10n.salesMonthlyPnlBarChartTitle,
    subtitle: l10n.salesMonthlyPnlBarChartSubtitle,
    filterSummary: tableLimit.truncationNotice,
    tableData: tableLimit.tableData,
    pdfOrientation: ChartSharePdfOrientation.landscape,
    chartExportBuilder: points.isEmpty || !isPercent
        ? null
        : (exportContext) => _monthlyPnlPercentExport(
            exportContext: exportContext,
            l10n: l10n,
            tokens: tokens,
            points: points,
            metric: metric,
            localeTag: localeTag,
            percentRatioFormat: percentRatioFormat,
          ),
  );
}

ChartShareMetadata buildSalesMonthlyPnlLineChartShareMetadata({
  required AppLocalizations l10n,
  required List<SalesMonthlyPnlPoint> points,
}) {
  final tableLimit = applyChartShareTableRowLimit(
    tableData: ChartShareTableData(
      headers: <String>[
        l10n.chartSharePdfColumnMonth,
        l10n.chartSharePdfColumnRevenue,
        l10n.chartSharePdfColumnProfit,
      ],
      rows: <List<String>>[
        for (final point in points)
          <String>[
            point.anoMes,
            AppBrFormatters.currency(point.venda),
            AppBrFormatters.currency(point.lucro),
          ],
      ],
    ),
    truncationNoticeBuilder: (shownRows, totalRows) =>
        l10n.chartSharePdfTableRowsTruncated(shownRows, totalRows),
  );

  return ChartShareMetadata(
    title: l10n.salesMonthlyPnlChartTitle,
    subtitle: l10n.salesMonthlyPnlChartSubtitle,
    filterSummary: tableLimit.truncationNotice,
    tableData: tableLimit.tableData,
    pdfOrientation: ChartSharePdfOrientation.landscape,
    chartExportBuilder: points.isEmpty
        ? null
        : (exportContext) => _monthlyPnlLineExport(
            exportContext: exportContext,
            l10n: l10n,
            points: points,
          ),
  );
}

Widget _monthlyPnlPercentExport({
  required BuildContext exportContext,
  required AppLocalizations l10n,
  required AppThemeTokens tokens,
  required List<SalesMonthlyPnlPoint> points,
  required LucratividadePercentMetric metric,
  required String localeTag,
  required NumberFormat percentRatioFormat,
}) {
  final exportStyle = appDashboardComparisonBarChartStyle(
    tokens: tokens,
    kind: AppDashboardComparisonBarChartKind.weekday,
    l10n: l10n,
    heightOverride: tokens.chartStandardHeight + tokens.contentSpacing * 2,
  ).forPdfExport();

  return wrapCartesianChartForPdfExport(
    context: exportContext,
    itemCount: points.length,
    minSlotWidth: comparisonBarMinSlotWidth(
      minBarWidth: exportStyle.minBarWidth,
    ),
    height: exportStyle.height,
    chart: AppComparisonBarChart<SalesMonthlyPnlPoint>(
      items: points,
      labelBuilder: (point) => _monthShort(point, localeTag),
      valueBuilder: (point) => point.metricBarValue(metric) / 100.0,
      plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
      extremeSpreadAccessibilityNotice:
          l10n.chartComparisonExtremeValueSpreadNotice,
      style: exportStyle,
      dataLabelBuilder: (_, ratio) => percentRatioFormat.format(ratio),
      tooltipLabelBuilder: (point, ratio) =>
          '${_monthLong(point, localeTag)}: ${percentRatioFormat.format(ratio)}',
    ),
  );
}

String _monthShort(SalesMonthlyPnlPoint point, String locale) {
  return DateFormat('MMM/yy', locale).format(
    DateTime(point.year, point.month),
  );
}

String _monthLong(SalesMonthlyPnlPoint point, String locale) {
  return DateFormat.yMMM(locale).format(DateTime(point.year, point.month));
}

const double _kMonthlyPnlLineExportMonthSlotWidth = 72;
const double _kMonthlyPnlLineExportHorizontalPadding = 24;

Widget _monthlyPnlLineExport({
  required BuildContext exportContext,
  required AppLocalizations l10n,
  required List<SalesMonthlyPnlPoint> points,
}) {
  final localeTag = l10n.localeName;
  final theme = Theme.of(exportContext);
  final colors = theme.appColors;
  final chartTheme = AppChartTheme.fromContext(
    exportContext,
    preset: AppChartPreset.standard,
  );
  final yAxisFormat = AppBrFormatters.compactCurrencyFormatForLocale(localeTag);
  final gridLineColor = colors.outlineVariant.withValues(alpha: 0.35);
  final chartHeight = exportContext.appTokens.chartStandardHeight;
  final exportWidth =
      cartesianChartExportWidth(
        itemCount: points.length,
        minSlotWidth: _kMonthlyPnlLineExportMonthSlotWidth,
      ) +
      _kMonthlyPnlLineExportHorizontalPadding;

  return ColoredBox(
    color: theme.colorScheme.surface,
    child: SizedBox(
      width: exportWidth,
      height: chartHeight,
      child: SfCartesianChart(
        margin: EdgeInsets.zero,
        plotAreaBorderWidth: 0,
        legend: const Legend(
          isVisible: true,
          position: LegendPosition.bottom,
          overflowMode: LegendItemOverflowMode.wrap,
        ),
        primaryXAxis: const CategoryAxis(
          majorGridLines: MajorGridLines(width: 0),
        ),
        primaryYAxis: NumericAxis(
          numberFormat: yAxisFormat,
          axisLine: const AxisLine(width: 0),
          majorGridLines: MajorGridLines(
            color: gridLineColor,
            width: 1,
          ),
        ),
        series: <CartesianSeries<SalesMonthlyPnlPoint, String>>[
          LineSeries<SalesMonthlyPnlPoint, String>(
            dataSource: points,
            xValueMapper: (point, _) => _monthShort(point, localeTag),
            yValueMapper: (point, _) => point.venda,
            name: l10n.salesMonthlyPnlSeriesSalesLabel,
            color: chartTheme.primaryColor,
            width: 3,
            animationDuration: 0,
            markerSettings: MarkerSettings(
              isVisible: true,
              height: 6,
              width: 6,
              color: chartTheme.primaryColor,
              borderColor: theme.colorScheme.surface,
            ),
          ),
          LineSeries<SalesMonthlyPnlPoint, String>(
            dataSource: points,
            xValueMapper: (point, _) => _monthShort(point, localeTag),
            yValueMapper: (point, _) => point.lucro,
            name: l10n.salesMonthlyPnlSeriesProfitLabel,
            color: chartTheme.paletteColor(1),
            width: 3,
            animationDuration: 0,
            markerSettings: MarkerSettings(
              isVisible: true,
              height: 6,
              width: 6,
              color: chartTheme.paletteColor(1),
              borderColor: theme.colorScheme.surface,
            ),
          ),
          LineSeries<SalesMonthlyPnlPoint, String>(
            dataSource: points,
            xValueMapper: (point, _) => _monthShort(point, localeTag),
            yValueMapper: (point, _) => point.custoMercadoria,
            name: l10n.salesMonthlyPnlSeriesCostLabel,
            color: chartTheme.paletteColor(2),
            width: 3,
            animationDuration: 0,
            markerSettings: MarkerSettings(
              isVisible: true,
              height: 6,
              width: 6,
              color: chartTheme.paletteColor(2),
              borderColor: theme.colorScheme.surface,
            ),
          ),
        ],
      ),
    ),
  );
}
