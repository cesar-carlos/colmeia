import 'dart:async';

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_sales_trend_point.dart';
import 'package:colmeia/features/overview/presentation/localization/overview_weekday_sales_trend_l10n.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_bar_chart_style.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OverviewWeekdaySalesTrendChart extends StatefulWidget {
  const OverviewWeekdaySalesTrendChart({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    this.loadFailureMessage,
    super.key,
  });

  final AppLocalizations l10n;
  final List<OverviewWeekdaySalesTrendPoint> points;
  final bool loadFailed;

  /// Specific message extracted from the underlying `AppFailure`. When set
  /// AND [loadFailed] is true, the chart shows this instead of the generic
  /// l10n "load failed" label (BUG #4 — actionable error context).
  final String? loadFailureMessage;

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
  _OverviewWeekdayMetric _metric = _OverviewWeekdayMetric.salesCount;

  /// Bars for the selected metric only; zero values are omitted from the plot.
  List<OverviewWeekdaySalesTrendPoint> _chartPointsNonZero() {
    if (_metric == _OverviewWeekdayMetric.salesCount) {
      return [
        for (final p in widget.points)
          if (p.salesCount > 0) p,
      ];
    }
    return [
      for (final p in widget.points)
        if (p.salesAmount > 0) p,
    ];
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
    final emptyMessage = widget.loadFailed
        ? (widget.loadFailureMessage ?? l10n.overviewWeekdaySalesLoadFailed)
        : l10n.overviewWeekdaySalesEmpty;
    final summary = _semanticsSummaryForBuild(
      l10n: l10n,
      salesCountFormat: salesCountFormat,
    );
    final chartPoints = _chartPointsNonZero();
    final showEmptyPlaceholder = widget.points.isEmpty || chartPoints.isEmpty;
    void openFullscreen() {
      final chartPointsSnapshot = List<OverviewWeekdaySalesTrendPoint>.of(
        chartPoints,
        growable: false,
      );
      final isSalesCountSnapshot = isSalesCount;
      unawaited(
        context.pushChartFullscreen<void>(
          extra: AppChartFullscreenRouteExtra(
            title: isSalesCountSnapshot
                ? l10n.overviewWeekdaySalesTitle
                : l10n.overviewWeekdayRevenueTitle,
            subtitle: l10n.overviewWeekdaySalesSubtitle,
            chartSemanticsLabel: isSalesCountSnapshot
                ? l10n.overviewWeekdaySalesChartSemantics
                : l10n.overviewWeekdayRevenueChartSemantics,
            chartBuilder: (fullscreenContext) {
              final fullscreenTokens = Theme.of(
                fullscreenContext,
              ).extension<AppThemeTokens>()!;
              var fullscreenMetric = _metric;
              return StatefulBuilder(
                builder: (context, setFullscreenState) {
                  final fullscreenIsSalesCount =
                      fullscreenMetric == _OverviewWeekdayMetric.salesCount;
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final availableChartHeight =
                          (constraints.maxHeight -
                                  fullscreenTokens.contentSpacing -
                                  48)
                              .clamp(220.0, constraints.maxHeight);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          AppSegmentedControl<_OverviewWeekdayMetric>(
                            options:
                                <
                                  AppSegmentedControlOption<
                                    _OverviewWeekdayMetric
                                  >
                                >[
                                  AppSegmentedControlOption<
                                    _OverviewWeekdayMetric
                                  >(
                                    value: _OverviewWeekdayMetric.salesCount,
                                    label: l10n
                                        .overviewWeekdayMetricSalesCountLabel,
                                  ),
                                  AppSegmentedControlOption<
                                    _OverviewWeekdayMetric
                                  >(
                                    value: _OverviewWeekdayMetric.salesAmount,
                                    label: l10n
                                        .overviewWeekdayMetricSalesAmountLabel,
                                  ),
                                ],
                            value: fullscreenMetric,
                            onChanged: (value) => setFullscreenState(
                              () => fullscreenMetric = value,
                            ),
                          ),
                          SizedBox(height: fullscreenTokens.contentSpacing),
                          SizedBox(
                            height: availableChartHeight,
                            child:
                                AppComparisonBarChart<
                                  OverviewWeekdaySalesTrendPoint
                                >(
                                  items: chartPointsSnapshot,
                                  plotFloorAccessibilityNotice:
                                      l10n.chartComparisonPlotFloorNotice,
                                  extremeSpreadAccessibilityNotice: l10n
                                      .chartComparisonExtremeValueSpreadNotice,
                                  labelBuilder: (point) =>
                                      overviewWeekdaySalesLabel(
                                        point.weekdayNumber,
                                        l10n,
                                      ),
                                  valueBuilder: (point) =>
                                      fullscreenIsSalesCount
                                      ? point.salesCount
                                      : point.salesAmount,
                                  tooltipLabelBuilder: (point, value) =>
                                      l10n.overviewWeekdaySalesTooltip(
                                        overviewWeekdaySalesLabel(
                                          point.weekdayNumber,
                                          l10n,
                                        ),
                                        salesCountFormat.format(
                                          point.salesCount,
                                        ),
                                        AppBrFormatters.currency(
                                          point.salesAmount,
                                        ),
                                      ),
                                  dataLabelBuilder: (_, value) =>
                                      fullscreenIsSalesCount
                                      ? compactSalesCountFormat.format(value)
                                      : AppBrFormatters.compactCurrency(value),
                                  style: overviewHomeComparisonBarChartStyle(
                                    tokens: fullscreenTokens,
                                    kind: OverviewHomeBarChartKind.weekday,
                                    l10n: l10n,
                                    weekdayUsesCurrencyAxis:
                                        !fullscreenIsSalesCount,
                                    weekdayRevenueDataLabelBackground:
                                        fullscreenIsSalesCount
                                        ? null
                                        : Theme.of(context).colorScheme.surface,
                                    heightOverride: availableChartHeight,
                                  ),
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
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      );
    }

    return Semantics(
      label: isSalesCount
          ? l10n.overviewWeekdaySalesChartSemantics
          : l10n.overviewWeekdayRevenueChartSemantics,
      hint: l10n.overviewWeekdayChartScopeHint,
      value: summary,
      child: AppComparisonBarChart<OverviewWeekdaySalesTrendPoint>(
        title: isSalesCount
            ? l10n.overviewWeekdaySalesTitle
            : l10n.overviewWeekdayRevenueTitle,
        subtitle: l10n.overviewWeekdaySalesSubtitle,
        onOpenFullscreen: openFullscreen,
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
            overviewWeekdaySalesLabel(point.weekdayNumber, l10n),
        valueBuilder: (point) =>
            isSalesCount ? point.salesCount : point.salesAmount,
        tooltipLabelBuilder: (point, value) => l10n.overviewWeekdaySalesTooltip(
          overviewWeekdaySalesLabel(point.weekdayNumber, l10n),
          salesCountFormat.format(point.salesCount),
          AppBrFormatters.currency(point.salesAmount),
        ),
        dataLabelBuilder: (_, value) => isSalesCount
            ? compactSalesCountFormat.format(value)
            : AppBrFormatters.compactCurrency(value),
        style: overviewHomeComparisonBarChartStyle(
          tokens: tokens,
          kind: OverviewHomeBarChartKind.weekday,
          l10n: l10n,
          weekdayUsesCurrencyAxis: !isSalesCount,
          weekdayRevenueDataLabelBackground: isSalesCount
              ? null
              : Theme.of(context).colorScheme.surface,
        ),
        emptyPlaceholder: showEmptyPlaceholder
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.contentSpacing),
                child: Center(
                  child: Text(
                    emptyMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  String _buildSemanticsSummary({
    required AppLocalizations l10n,
    required NumberFormat salesCountFormat,
  }) {
    final points = widget.points;
    if (points.isEmpty) {
      return widget.loadFailed
          ? (widget.loadFailureMessage ?? l10n.overviewWeekdaySalesLoadFailed)
          : l10n.overviewWeekdaySalesEmpty;
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

    final topLabel = overviewWeekdaySalesLabel(topPoint.weekdayNumber, l10n);
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
