import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/overview_weekday_display_order.dart';
import 'package:colmeia/features/overview/presentation/share/overview_chart_share_export_filter.dart';
import 'package:colmeia/features/overview/presentation/share/overview_weekday_sales_trend_share.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_chart_load_failure_helpers.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/charts/daily_sales_weekday_labels.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_fullscreen_request.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/app_dashboard_comparison_bar_chart_preset.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:colmeia/shared/widgets/charts/metric_toggle_comparison_bar_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OverviewWeekdaySalesTrendChart extends StatefulWidget {
  const OverviewWeekdaySalesTrendChart({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    this.loadFailure,
    this.loadFailureMessage,
    this.onViewAgentFailureDetails,
    this.onRequestFullscreen,
    this.onRequestShare,
    this.exportHeaderContext,
    super.key,
  });

  final AppLocalizations l10n;
  final ChartShareExportHeaderContext? exportHeaderContext;
  final List<OverviewWeekdaySalesTrendPoint> points;
  final bool loadFailed;
  final AppFailure? loadFailure;
  final String? loadFailureMessage;
  final VoidCallback? onViewAgentFailureDetails;
  final AppChartFullscreenRequestCallback? onRequestFullscreen;
  final AppChartShareRequestCallback? onRequestShare;

  @override
  State<OverviewWeekdaySalesTrendChart> createState() =>
      _OverviewWeekdaySalesTrendChartState();
}

class _OverviewWeekdaySalesTrendChartState
    extends State<OverviewWeekdaySalesTrendChart> {
  List<OverviewWeekdaySalesTrendPoint>? _semanticsPointsRef;
  MetricToggleComparisonBarMetric? _semanticsMetric;
  bool? _semanticsLoadFailed;
  String? _semanticsSummaryCache;

  @override
  void didUpdateWidget(covariant OverviewWeekdaySalesTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.points, oldWidget.points) ||
        widget.loadFailed != oldWidget.loadFailed ||
        widget.l10n.localeName != oldWidget.l10n.localeName) {
      _semanticsSummaryCache = null;
      _semanticsPointsRef = null;
      _semanticsMetric = null;
      _semanticsLoadFailed = null;
    }
  }

  List<OverviewWeekdaySalesTrendPoint> _filterItems(
    List<OverviewWeekdaySalesTrendPoint> source,
    MetricToggleComparisonBarMetric metric,
  ) {
    List<OverviewWeekdaySalesTrendPoint> filtered;
    if (metric == MetricToggleComparisonBarMetric.count) {
      filtered = [
        for (final point in source)
          if (point.salesCount > 0) point,
      ];
    } else {
      filtered = [
        for (final point in source)
          if (point.salesAmount > 0) point,
      ];
    }
    filtered.sort(
      (left, right) => compareOverviewApiWeekdayDisplayOrder(
        left.weekdayNumber,
        right.weekdayNumber,
      ),
    );
    return filtered;
  }

  String _semanticsSummaryForMetric(MetricToggleComparisonBarMetric metric) {
    if (_semanticsSummaryCache != null &&
        identical(widget.points, _semanticsPointsRef) &&
        metric == _semanticsMetric &&
        widget.loadFailed == _semanticsLoadFailed) {
      return _semanticsSummaryCache!;
    }
    _semanticsPointsRef = widget.points;
    _semanticsMetric = metric;
    _semanticsLoadFailed = widget.loadFailed;
    _semanticsSummaryCache = _buildSemanticsSummary(metric: metric);
    return _semanticsSummaryCache!;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final localeName = Localizations.localeOf(context).toString();
    final salesCountFormat = NumberFormat.decimalPattern(localeName);
    final compactSalesCountFormat = NumberFormat.compact(locale: localeName);
    final emptyMessage = overviewChartLoadFailureMessage(
      l10n: l10n,
      loadFailed: widget.loadFailed,
      loadFailure: widget.loadFailure,
      legacyMessage: widget.loadFailureMessage,
      genericFallback: widget.loadFailed
          ? l10n.overviewWeekdaySalesLoadFailed
          : l10n.overviewWeekdaySalesEmpty,
    );

    return MetricToggleComparisonBarCard<OverviewWeekdaySalesTrendPoint>(
      items: widget.points,
      countMetricLabel: l10n.overviewWeekdayMetricSalesCountLabel,
      amountMetricLabel: l10n.overviewWeekdayMetricSalesAmountLabel,
      filterItems: _filterItems,
      titleForMetric: (metric) =>
          metric == MetricToggleComparisonBarMetric.count
          ? l10n.overviewWeekdaySalesTitle
          : l10n.overviewWeekdayRevenueTitle,
      subtitle: l10n.overviewWeekdaySalesSubtitle,
      semanticsLabelForMetric: (metric) =>
          metric == MetricToggleComparisonBarMetric.count
          ? l10n.overviewWeekdaySalesChartSemantics
          : l10n.overviewWeekdayRevenueChartSemantics,
      semanticsHint: l10n.overviewWeekdayChartScopeHint,
      semanticsValueBuilder: _semanticsSummaryForMetric,
      labelBuilder: (point) =>
          dailySalesWeekdayLabel(point.weekdayNumber, l10n),
      valueBuilder: (point, metric) =>
          metric == MetricToggleComparisonBarMetric.count
          ? point.salesCount
          : point.salesAmount,
      tooltipLabelBuilder: (point, _, metric) =>
          l10n.overviewWeekdaySalesTooltip(
            dailySalesWeekdayLabel(point.weekdayNumber, l10n),
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
          kind: AppDashboardComparisonBarChartKind.weekday,
          l10n: l10n,
          weekdayUsesCurrencyAxis: !isSalesCount,
          weekdayRevenueDataLabelBackground: isSalesCount
              ? null
              : Theme.of(chartContext).colorScheme.surface,
          heightOverride: heightOverride,
        );
      },
      landscapeStyleOverride: (base, height) => base.forLandscapeFullscreen(
        height: height,
      ),
      fullscreenSemanticsLabelBuilder: (metric) =>
          metric == MetricToggleComparisonBarMetric.count
          ? l10n.overviewWeekdaySalesChartSemantics
          : l10n.overviewWeekdayRevenueChartSemantics,
      shareMetadataBuilder: (metric) {
        final isSalesCountMetric =
            metric == MetricToggleComparisonBarMetric.count;
        return buildOverviewWeekdaySalesTrendShareMetadata(
          l10n: l10n,
          tablePoints: overviewWeekdaySalesTrendTableRows(widget.points),
          isSalesCountMetric: isSalesCountMetric,
          salesCountFormat: salesCountFormat,
          exportHeaderContext: overviewWeekdayChartShareExportHeaderContext(
            base: widget.exportHeaderContext,
            l10n: l10n,
            isSalesCountMetric: isSalesCountMetric,
          ),
        );
      },
      plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
      extremeSpreadAccessibilityNotice:
          l10n.chartComparisonExtremeValueSpreadNotice,
      emptyPlaceholder: overviewChartEmptyPlaceholder(
        emptyMessage: emptyMessage,
        textStyle: Theme.of(context).textTheme.bodyMedium,
        verticalPadding: tokens.contentSpacing,
        onViewAgentFailureDetails: widget.onViewAgentFailureDetails,
        loadFailure: widget.loadFailed ? widget.loadFailure : null,
      ),
      onRequestFullscreen: widget.onRequestFullscreen,
      onRequestShare: widget.onRequestShare,
    );
  }

  String _buildSemanticsSummary({
    required MetricToggleComparisonBarMetric metric,
  }) {
    final l10n = widget.l10n;
    final localeName = Localizations.localeOf(context).toString();
    final salesCountFormat = NumberFormat.decimalPattern(localeName);
    final points = widget.points;
    if (points.isEmpty) {
      return overviewChartLoadFailureMessage(
        l10n: l10n,
        loadFailed: widget.loadFailed,
        loadFailure: widget.loadFailure,
        legacyMessage: widget.loadFailureMessage,
        genericFallback: widget.loadFailed
            ? l10n.overviewWeekdaySalesLoadFailed
            : l10n.overviewWeekdaySalesEmpty,
      );
    }

    final totalSalesCount = points.fold<int>(
      0,
      (total, point) => total + point.salesCount,
    );
    final totalSalesAmount = points.fold<double>(
      0,
      (total, point) => total + point.salesAmount,
    );
    final topPoint = points.reduce((left, right) {
      final leftValue = metric == MetricToggleComparisonBarMetric.count
          ? left.salesCount.toDouble()
          : left.salesAmount;
      final rightValue = metric == MetricToggleComparisonBarMetric.count
          ? right.salesCount.toDouble()
          : right.salesAmount;
      return rightValue > leftValue ? right : left;
    });

    final topLabel = dailySalesWeekdayLabel(topPoint.weekdayNumber, l10n);
    return metric == MetricToggleComparisonBarMetric.count
        ? l10n.overviewWeekdaySalesSummarySemantics(
            salesCountFormat.format(totalSalesCount),
            AppBrFormatters.currency(totalSalesAmount),
            topLabel,
            salesCountFormat.format(topPoint.salesCount),
          )
        : l10n.overviewWeekdayRevenueSummarySemantics(
            AppBrFormatters.currency(totalSalesAmount),
            salesCountFormat.format(totalSalesCount),
            topLabel,
            AppBrFormatters.currency(topPoint.salesAmount),
          );
  }
}
