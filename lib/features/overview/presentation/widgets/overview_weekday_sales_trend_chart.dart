import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/overview_weekday_display_order.dart';
import 'package:colmeia/features/overview/presentation/share/overview_weekday_sales_trend_share.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_chart_load_failure_helpers.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/charts/daily_sales_weekday_labels.dart';
import 'package:colmeia/shared/charts/metric_toggle_comparison_bar_fullscreen_body.dart'
    show buildMetricToggleComparisonBarFullscreenBody, isLandscapeChartViewport;
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_fullscreen_request.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_dashboard_comparison_bar_chart_preset.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_actions.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
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
    super.key,
  });

  final AppLocalizations l10n;
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

enum _OverviewWeekdayMetric {
  salesCount,
  salesAmount,
}

class _OverviewWeekdaySalesTrendChartState
    extends State<OverviewWeekdaySalesTrendChart> {
  final GlobalKey _shareKey = GlobalKey();

  _OverviewWeekdayMetric _metric = _OverviewWeekdayMetric.salesCount;

  List<OverviewWeekdaySalesTrendPoint> _chartPointsNonZero() {
    List<OverviewWeekdaySalesTrendPoint> filtered;
    if (_metric == _OverviewWeekdayMetric.salesCount) {
      filtered = [
        for (final p in widget.points)
          if (p.salesCount > 0) p,
      ];
    } else {
      filtered = [
        for (final p in widget.points)
          if (p.salesAmount > 0) p,
      ];
    }
    filtered.sort(
      (a, b) => compareOverviewApiWeekdayDisplayOrder(
        a.weekdayNumber,
        b.weekdayNumber,
      ),
    );
    return filtered;
  }

  List<OverviewWeekdaySalesTrendPoint>? _semanticsPointsRef;
  _OverviewWeekdayMetric? _semanticsMetric;
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

  String _semanticsSummaryForBuild({
    required AppLocalizations l10n,
    required NumberFormat salesCountFormat,
  }) {
    if (_semanticsSummaryCache != null &&
        identical(widget.points, _semanticsPointsRef) &&
        _metric == _semanticsMetric &&
        widget.loadFailed == _semanticsLoadFailed) {
      return _semanticsSummaryCache!;
    }
    _semanticsPointsRef = widget.points;
    _semanticsMetric = _metric;
    _semanticsLoadFailed = widget.loadFailed;
    _semanticsSummaryCache = _buildSemanticsSummary(
      l10n: l10n,
      salesCountFormat: salesCountFormat,
    );
    return _semanticsSummaryCache!;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final localeName = Localizations.localeOf(context).toString();
    final salesCountFormat = NumberFormat.decimalPattern(localeName);
    final compactSalesCountFormat = NumberFormat.compact(locale: localeName);
    final isSalesCount = _metric == _OverviewWeekdayMetric.salesCount;
    final emptyMessage = overviewChartLoadFailureMessage(
      l10n: l10n,
      loadFailed: widget.loadFailed,
      loadFailure: widget.loadFailure,
      legacyMessage: widget.loadFailureMessage,
      genericFallback: widget.loadFailed
          ? l10n.overviewWeekdaySalesLoadFailed
          : l10n.overviewWeekdaySalesEmpty,
    );
    final summary = _semanticsSummaryForBuild(
      l10n: l10n,
      salesCountFormat: salesCountFormat,
    );
    final chartPoints = _chartPointsNonZero();
    final showEmptyPlaceholder = widget.points.isEmpty || chartPoints.isEmpty;
    final shareTitle = isSalesCount
        ? l10n.overviewWeekdaySalesTitle
        : l10n.overviewWeekdayRevenueTitle;
    final onRequestFullscreen = widget.onRequestFullscreen;
    final onRequestShare = widget.onRequestShare;

    ChartShareMetadata shareMetadata({required bool isSalesCountMetric}) {
      return buildOverviewWeekdaySalesTrendShareMetadata(
        l10n: l10n,
        tablePoints: overviewWeekdaySalesTrendTableRows(widget.points),
        isSalesCountMetric: isSalesCountMetric,
        salesCountFormat: salesCountFormat,
      );
    }

    final shareActions = ChartShareActions(
      context: context,
      captureKey: _shareKey,
      metadata: shareMetadata(isSalesCountMetric: isSalesCount),
      onRequestShare: onRequestShare,
      onRequestFullscreen: onRequestFullscreen,
    );

    void openFullscreen() {
      final chartPointsSnapshot = List<OverviewWeekdaySalesTrendPoint>.of(
        chartPoints,
        growable: false,
      );
      final isSalesCountSnapshot = isSalesCount;
      final fullscreenShareKey = GlobalKey();
      final metadata = shareMetadata(isSalesCountMetric: isSalesCountSnapshot);
      shareActions.openFullscreen(
        metadata.toFullscreenRequest(
          semanticsLabel: isSalesCountSnapshot
              ? l10n.overviewWeekdaySalesChartSemantics
              : l10n.overviewWeekdayRevenueChartSemantics,
          shareCaptureKey: fullscreenShareKey,
          chartBuilder: (fullscreenContext) {
            final fullscreenTokens = Theme.of(
              fullscreenContext,
            ).extension<AppThemeTokens>()!;
            var fullscreenMetric = _metric;
            return RepaintBoundary(
              key: fullscreenShareKey,
              child: StatefulBuilder(
                builder: (context, setFullscreenState) {
                  final fullscreenIsSalesCount =
                      fullscreenMetric == _OverviewWeekdayMetric.salesCount;
                  return buildMetricToggleComparisonBarFullscreenBody(
                    tokens: fullscreenTokens,
                    metricToggle: AppSegmentedControl<_OverviewWeekdayMetric>(
                      options:
                          <AppSegmentedControlOption<_OverviewWeekdayMetric>>[
                            AppSegmentedControlOption<_OverviewWeekdayMetric>(
                              value: _OverviewWeekdayMetric.salesCount,
                              label: l10n.overviewWeekdayMetricSalesCountLabel,
                            ),
                            AppSegmentedControlOption<_OverviewWeekdayMetric>(
                              value: _OverviewWeekdayMetric.salesAmount,
                              label: l10n.overviewWeekdayMetricSalesAmountLabel,
                            ),
                          ],
                      value: fullscreenMetric,
                      onChanged: (value) => setFullscreenState(
                        () => fullscreenMetric = value,
                      ),
                    ),
                    chartBuilder: (availableChartHeight) =>
                        AppComparisonBarChart<OverviewWeekdaySalesTrendPoint>(
                          items: chartPointsSnapshot,
                          plotFloorAccessibilityNotice:
                              l10n.chartComparisonPlotFloorNotice,
                          extremeSpreadAccessibilityNotice:
                              l10n.chartComparisonExtremeValueSpreadNotice,
                          labelBuilder: (point) => dailySalesWeekdayLabel(
                            point.weekdayNumber,
                            l10n,
                          ),
                          valueBuilder: (point) => fullscreenIsSalesCount
                              ? point.salesCount
                              : point.salesAmount,
                          tooltipLabelBuilder: (point, value) =>
                              l10n.overviewWeekdaySalesTooltip(
                                dailySalesWeekdayLabel(
                                  point.weekdayNumber,
                                  l10n,
                                ),
                                salesCountFormat.format(point.salesCount),
                                AppBrFormatters.currency(point.salesAmount),
                              ),
                          dataLabelBuilder: (_, value) => fullscreenIsSalesCount
                              ? compactSalesCountFormat.format(value)
                              : AppBrFormatters.compactCurrency(value),
                          style: () {
                            final built = appDashboardComparisonBarChartStyle(
                              tokens: fullscreenTokens,
                              kind: AppDashboardComparisonBarChartKind.weekday,
                              l10n: l10n,
                              weekdayUsesCurrencyAxis: !fullscreenIsSalesCount,
                              weekdayRevenueDataLabelBackground:
                                  fullscreenIsSalesCount
                                  ? null
                                  : Theme.of(context).colorScheme.surface,
                              heightOverride: availableChartHeight,
                            );
                            if (isLandscapeChartViewport(context)) {
                              return built.forLandscapeFullscreen(
                                height: availableChartHeight,
                              );
                            }
                            return built;
                          }(),
                          emptyPlaceholder: showEmptyPlaceholder
                              ? Center(
                                  child: Text(
                                    emptyMessage,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                )
                              : null,
                        ),
                  );
                },
              ),
            );
          },
        ),
      );
    }

    return Semantics(
      label: isSalesCount
          ? l10n.overviewWeekdaySalesChartSemantics
          : l10n.overviewWeekdayRevenueChartSemantics,
      hint: l10n.overviewWeekdayChartScopeHint,
      value: summary,
      child: RepaintBoundary(
        key: _shareKey,
        child: AppComparisonBarChart<OverviewWeekdaySalesTrendPoint>(
          title: shareTitle,
          subtitle: l10n.overviewWeekdaySalesSubtitle,
          onShare: shareActions.shareCallback(),
          shareProgressKey: _shareKey,
          onOpenFullscreen: shareActions.fullscreenCallback(openFullscreen),
          belowSubtitle: AppSegmentedControl<_OverviewWeekdayMetric>(
            options: <AppSegmentedControlOption<_OverviewWeekdayMetric>>[
              AppSegmentedControlOption<_OverviewWeekdayMetric>(
                value: _OverviewWeekdayMetric.salesCount,
                label: l10n.overviewWeekdayMetricSalesCountLabel,
              ),
              AppSegmentedControlOption<_OverviewWeekdayMetric>(
                value: _OverviewWeekdayMetric.salesAmount,
                label: l10n.overviewWeekdayMetricSalesAmountLabel,
              ),
            ],
            value: _metric,
            onChanged: (value) => setState(() => _metric = value),
          ),
          items: chartPoints,
          plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
          extremeSpreadAccessibilityNotice:
              l10n.chartComparisonExtremeValueSpreadNotice,
          labelBuilder: (point) =>
              dailySalesWeekdayLabel(point.weekdayNumber, l10n),
          valueBuilder: (point) =>
              isSalesCount ? point.salesCount : point.salesAmount,
          tooltipLabelBuilder: (point, value) =>
              l10n.overviewWeekdaySalesTooltip(
                dailySalesWeekdayLabel(point.weekdayNumber, l10n),
                salesCountFormat.format(point.salesCount),
                AppBrFormatters.currency(point.salesAmount),
              ),
          dataLabelBuilder: (_, value) => isSalesCount
              ? compactSalesCountFormat.format(value)
              : AppBrFormatters.compactCurrency(value),
          style: appDashboardComparisonBarChartStyle(
            tokens: tokens,
            kind: AppDashboardComparisonBarChartKind.weekday,
            l10n: l10n,
            weekdayUsesCurrencyAxis: !isSalesCount,
            weekdayRevenueDataLabelBackground: isSalesCount
                ? null
                : Theme.of(context).colorScheme.surface,
          ),
          emptyPlaceholder: showEmptyPlaceholder
              ? overviewChartEmptyPlaceholder(
                  emptyMessage: emptyMessage,
                  textStyle: Theme.of(context).textTheme.bodyMedium,
                  verticalPadding: tokens.contentSpacing,
                  onViewAgentFailureDetails: widget.onViewAgentFailureDetails,
                  loadFailure: widget.loadFailed ? widget.loadFailure : null,
                )
              : null,
        ),
      ),
    );
  }

  String _buildSemanticsSummary({
    required AppLocalizations l10n,
    required NumberFormat salesCountFormat,
  }) {
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
      final leftValue = _metric == _OverviewWeekdayMetric.salesCount
          ? left.salesCount.toDouble()
          : left.salesAmount;
      final rightValue = _metric == _OverviewWeekdayMetric.salesCount
          ? right.salesCount.toDouble()
          : right.salesAmount;
      return rightValue > leftValue ? right : left;
    });

    final topLabel = dailySalesWeekdayLabel(topPoint.weekdayNumber, l10n);
    return _metric == _OverviewWeekdayMetric.salesCount
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
