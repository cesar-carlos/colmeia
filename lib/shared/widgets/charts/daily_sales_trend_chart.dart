import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_chart_labels.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_point.dart';
import 'package:colmeia/shared/charts/daily_sales_weekday_labels.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_fullscreen_request.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/app_dashboard_comparison_bar_chart_preset.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:colmeia/shared/widgets/charts/metric_toggle_comparison_bar_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Daily sales totals (bar chart) for the overview period or Sales branch/month scope.
class DailySalesTrendChart extends StatelessWidget {
  const DailySalesTrendChart({
    required this.l10n,
    required this.points,
    required this.emptyMessage,
    this.isLoading = false,
    this.emptyPlaceholder,
    this.useSalesDailyTotalsLabels = false,
    this.salesSubtitleOverride,
    this.salesScopeHintOverride,
    this.onRequestFullscreen,
    this.onRequestShare,
    super.key,
  });

  final AppLocalizations l10n;
  final List<DailySalesTrendPoint> points;
  final String emptyMessage;
  final bool isLoading;
  final Widget? emptyPlaceholder;
  final bool useSalesDailyTotalsLabels;
  final String? salesSubtitleOverride;
  final String? salesScopeHintOverride;
  final AppChartFullscreenRequestCallback? onRequestFullscreen;
  final AppChartShareRequestCallback? onRequestShare;

  List<DailySalesTrendPoint> _filterItems(
    List<DailySalesTrendPoint> source,
    MetricToggleComparisonBarMetric metric,
  ) {
    if (metric == MetricToggleComparisonBarMetric.count) {
      return [
        for (final point in source)
          if (point.salesCount > 0) point,
      ];
    }
    return [
      for (final point in source)
        if (point.salesAmount > 0) point,
    ];
  }

  String _dayAxisLabel(DailySalesTrendPoint point) {
    final dateLine = AppBrFormatters.shortDate(point.saleDate);
    final dowLine = dailySalesShortWeekdayFromDateTime(l10n, point.saleDate);
    return '$dateLine\n$dowLine';
  }

  String _tooltipDateLine(DailySalesTrendPoint point) {
    return '${AppBrFormatters.shortDate(point.saleDate)} · ${dailySalesShortWeekdayFromDateTime(l10n, point.saleDate)}';
  }

  @override
  Widget build(BuildContext context) {
    final labels = DailySalesTrendChartLabels.resolve(
      l10n,
      salesBranchMonth: useSalesDailyTotalsLabels,
    );
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final localeName = Localizations.localeOf(context).toString();
    final salesCountFormat = NumberFormat.decimalPattern(localeName);
    final compactSalesCountFormat = NumberFormat.compact(locale: localeName);
    final resolvedSubtitle = salesSubtitleOverride ?? labels.subtitle;
    final resolvedScopeHint = salesScopeHintOverride ?? labels.scopeHint;
    final resolvedEmptyPlaceholder = emptyPlaceholder ??
        Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.contentSpacing),
          child: Center(
            child: Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );

    ChartShareMetadata shareMetadata({
      required bool isSalesCountMetric,
    }) {
      final shareTitle = labels.titleForMetric(
        isSalesCount: isSalesCountMetric,
      );
      final tableLimit = applyChartShareTableRowLimit(
        tableData: ChartShareTableData(
          headers: <String>[
            l10n.chartSharePdfColumnDate,
            l10n.chartSharePdfColumnWeekday,
            labels.metricCountLabel,
            labels.metricAmountLabel,
          ],
          rows: <List<String>>[
            for (final point in points)
              <String>[
                AppBrFormatters.shortDate(point.saleDate),
                dailySalesShortWeekdayFromDateTime(l10n, point.saleDate),
                salesCountFormat.format(point.salesCount),
                AppBrFormatters.currency(point.salesAmount),
              ],
          ],
        ),
        truncationNoticeBuilder: l10n.chartSharePdfTableRowsTruncated,
      );

      return ChartShareMetadata(
        title: shareTitle,
        subtitle: resolvedSubtitle,
        filterSummary: tableLimit.truncationNotice,
        pdfOrientation: ChartSharePdfOrientation.landscape,
        tableData: tableLimit.tableData,
        subject: shareTitle,
      );
    }

    return MetricToggleComparisonBarCard<DailySalesTrendPoint>(
      items: points,
      countMetricLabel: labels.metricCountLabel,
      amountMetricLabel: labels.metricAmountLabel,
      filterItems: _filterItems,
      titleForMetric: (metric) => labels.titleForMetric(
        isSalesCount: metric == MetricToggleComparisonBarMetric.count,
      ),
      subtitle: resolvedSubtitle,
      semanticsLabelForMetric: (metric) => labels.semanticsForMetric(
        isSalesCount: metric == MetricToggleComparisonBarMetric.count,
      ),
      semanticsHint: resolvedScopeHint,
      labelBuilder: _dayAxisLabel,
      valueBuilder: (point, metric) =>
          metric == MetricToggleComparisonBarMetric.count
          ? point.salesCount
          : point.salesAmount,
      tooltipLabelBuilder: (point, _, metric) => labels.tooltip(
        _tooltipDateLine(point),
        salesCountFormat.format(point.salesCount),
        AppBrFormatters.currency(point.salesAmount),
      ),
      dataLabelBuilder: (point, value, metric) =>
          metric == MetricToggleComparisonBarMetric.count
          ? compactSalesCountFormat.format(value)
          : AppBrFormatters.compactCurrency(value),
      styleBuilder: (chartContext, metric, {heightOverride}) {
        final isSalesCount = metric == MetricToggleComparisonBarMetric.count;
        return appDashboardComparisonBarChartStyle(
          tokens: tokens,
          kind: AppDashboardComparisonBarChartKind.daily,
          l10n: l10n,
          weekdayUsesCurrencyAxis: !isSalesCount,
          weekdayRevenueDataLabelBackground: isSalesCount
              ? null
              : Theme.of(chartContext).colorScheme.surface,
          heightOverride: heightOverride,
        );
      },
      shareMetadataBuilder: (metric) => shareMetadata(
        isSalesCountMetric: metric == MetricToggleComparisonBarMetric.count,
      ),
      plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
      extremeSpreadAccessibilityNotice:
          l10n.chartComparisonExtremeValueSpreadNotice,
      emptyPlaceholder: resolvedEmptyPlaceholder,
      isLoading: isLoading,
      onRequestFullscreen: onRequestFullscreen,
      onRequestShare: onRequestShare,
      shareEnabled: !isLoading,
    );
  }
}
