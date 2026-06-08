import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/dashboard_lucratividade_percent_metrics.dart';
import 'package:colmeia/features/sales/domain/entities/sales_monthly_pnl_point.dart';
import 'package:colmeia/features/sales/domain/sales_monthly_pnl_bar_chart_preferences.dart';
import 'package:colmeia/features/sales/domain/sales_monthly_pnl_point_percent_metric.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_dashboard_comparison_bar_chart_preset.dart';
import 'package:colmeia/shared/widgets/charts/app_grouped_column_chart.dart';
import 'package:colmeia/shared/widgets/charts/chart_export_capture.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  return ChartShareMetadata(
    title: l10n.salesMonthlyPnlBarChartTitle,
    subtitle: l10n.salesMonthlyPnlBarChartSubtitle,
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
    chartExportBuilder: points.isEmpty
        ? null
        : (exportContext) => isPercent
            ? _monthlyPnlPercentExport(
                exportContext: exportContext,
                l10n: l10n,
                tokens: tokens,
                points: points,
                metric: metric,
                localeTag: localeTag,
                percentRatioFormat: percentRatioFormat,
              )
            : _monthlyPnlGroupedColumnExport(
                exportContext: exportContext,
                l10n: l10n,
                tokens: tokens,
                points: points,
                chartTheme: chartTheme,
                localeTag: localeTag,
                primaryMoney: primaryMoney,
                gridLineColor: gridLineColor,
              ),
  );
}

ChartShareMetadata buildSalesMonthlyPnlLineChartShareMetadata({
  required AppLocalizations l10n,
  required List<SalesMonthlyPnlPoint> points,
}) {
  return ChartShareMetadata(
    title: l10n.salesMonthlyPnlChartTitle,
    subtitle: l10n.salesMonthlyPnlChartSubtitle,
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
  );
}

Widget _monthlyPnlGroupedColumnExport({
  required BuildContext exportContext,
  required AppLocalizations l10n,
  required AppThemeTokens tokens,
  required List<SalesMonthlyPnlPoint> points,
  required AppChartTheme chartTheme,
  required String localeTag,
  required NumberFormat primaryMoney,
  required Color gridLineColor,
}) {
  final chartHeight = tokens.chartStandardHeight + tokens.contentSpacing * 2;
  return wrapCartesianChartForPdfExport(
    context: exportContext,
    itemCount: points.length,
    minSlotWidth: 72,
    height: chartHeight,
    chart: AppGroupedColumnChart<SalesMonthlyPnlPoint>(
      items: points,
      xLabelBuilder: (point) => _monthShort(point, localeTag),
      salesValue: (point) => point.venda,
      profitValue: (point) => point.lucro,
      costValue: (point) => point.custoMercadoria,
      salesLabel: l10n.salesMonthlyPnlSeriesSalesLabel,
      profitLabel: l10n.salesMonthlyPnlSeriesProfitLabel,
      costLabel: l10n.salesMonthlyPnlSeriesCostLabel,
      salesColor: chartTheme.primaryColor,
      profitColor: chartTheme.paletteColor(1),
      costColor: chartTheme.paletteColor(2),
      primaryAxisFormat: primaryMoney,
      secondaryAxisFormat: primaryMoney,
      height: chartHeight,
      gridLineColor: gridLineColor,
      tooltipBuilder: (data, point, series, pointIndex, seriesIndex) {
        final item = data as SalesMonthlyPnlPoint;
        final label = switch (seriesIndex) {
          1 => l10n.salesMonthlyPnlSeriesProfitLabel,
          2 => l10n.salesMonthlyPnlSeriesCostLabel,
          _ => l10n.salesMonthlyPnlSeriesSalesLabel,
        };
        final value = switch (seriesIndex) {
          1 => item.lucro,
          2 => item.custoMercadoria,
          _ => item.venda,
        };
        return Text('$label: ${primaryMoney.format(value)}');
      },
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
