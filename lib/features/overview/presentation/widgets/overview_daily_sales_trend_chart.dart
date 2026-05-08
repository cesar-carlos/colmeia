import 'dart:async';

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_daily_sales_trend_point.dart';
import 'package:colmeia/features/overview/presentation/localization/daily_sales_trend_chart_labels.dart';
import 'package:colmeia/features/overview/presentation/localization/overview_weekday_sales_trend_l10n.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_bar_chart_style.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum _OverviewDailyMetric {
  salesCount,
  salesAmount,
}

/// Daily sales totals (bar chart) for the overview period or Sales branch/month scope.
class OverviewDailySalesTrendChart extends StatefulWidget {
  const OverviewDailySalesTrendChart({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    this.loadFailureMessage,
    this.useSalesDailyTotalsLabels = false,
    super.key,
  });

  final AppLocalizations l10n;
  final List<OverviewDailySalesTrendPoint> points;
  final bool loadFailed;
  final String? loadFailureMessage;

  /// When true, chart titles and messages use [DailySalesTrendChartLabels] sales
  /// branch/month strings instead of overview home copy.
  final bool useSalesDailyTotalsLabels;

  @override
  State<OverviewDailySalesTrendChart> createState() =>
      _OverviewDailySalesTrendChartState();
}

class _OverviewDailySalesTrendChartState
    extends State<OverviewDailySalesTrendChart> {
  _OverviewDailyMetric _metric = _OverviewDailyMetric.salesCount;

  List<OverviewDailySalesTrendPoint> _chartPointsNonZero() {
    if (_metric == _OverviewDailyMetric.salesCount) {
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

  String _dayAxisLabel(OverviewDailySalesTrendPoint p) {
    final l10n = widget.l10n;
    final dateLine = AppBrFormatters.shortDate(p.saleDate);
    final dowLine = overviewShortWeekdayFromDateTime(l10n, p.saleDate);
    return '$dateLine\n$dowLine';
  }

  String _tooltipDateLine(OverviewDailySalesTrendPoint p) {
    final l10n = widget.l10n;
    return '${AppBrFormatters.shortDate(p.saleDate)} · ${overviewShortWeekdayFromDateTime(l10n, p.saleDate)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final labels = DailySalesTrendChartLabels.resolve(
      l10n,
      salesBranchMonth: widget.useSalesDailyTotalsLabels,
    );
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final localeName = Localizations.localeOf(context).toString();
    final salesCountFormat = NumberFormat.decimalPattern(localeName);
    final compactSalesCountFormat = NumberFormat.compact(locale: localeName);
    final isSalesCount = _metric == _OverviewDailyMetric.salesCount;
    final emptyMessage = labels.resolveEmptyMessage(
      loadFailed: widget.loadFailed,
      loadFailureMessage: widget.loadFailureMessage,
    );
    final chartPoints = _chartPointsNonZero();
    final showEmptyPlaceholder = widget.points.isEmpty || chartPoints.isEmpty;

    void openFullscreen() {
      final chartPointsSnapshot = List<OverviewDailySalesTrendPoint>.of(
        chartPoints,
        growable: false,
      );
      final isSalesCountSnapshot = isSalesCount;
      unawaited(
        context.pushChartFullscreen<void>(
          extra: AppChartFullscreenRouteExtra(
            title: labels.titleForMetric(isSalesCount: isSalesCountSnapshot),
            subtitle: labels.subtitle,
            chartSemanticsLabel: labels.semanticsForMetric(
              isSalesCount: isSalesCountSnapshot,
            ),
            chartBuilder: (fullscreenContext) {
              final fullscreenTokens = Theme.of(
                fullscreenContext,
              ).extension<AppThemeTokens>()!;
              var fullscreenMetric = _metric;
              return StatefulBuilder(
                builder: (context, setFullscreenState) {
                  final fullscreenIsSalesCount =
                      fullscreenMetric == _OverviewDailyMetric.salesCount;
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
                          AppSegmentedControl<_OverviewDailyMetric>(
                            options:
                                <
                                  AppSegmentedControlOption<
                                    _OverviewDailyMetric
                                  >
                                >[
                                  AppSegmentedControlOption<
                                    _OverviewDailyMetric
                                  >(
                                    value: _OverviewDailyMetric.salesCount,
                                    label: labels.metricCountLabel,
                                  ),
                                  AppSegmentedControlOption<
                                    _OverviewDailyMetric
                                  >(
                                    value: _OverviewDailyMetric.salesAmount,
                                    label: labels.metricAmountLabel,
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
                                  OverviewDailySalesTrendPoint
                                >(
                                  items: chartPointsSnapshot,
                                  plotFloorAccessibilityNotice:
                                      l10n.chartComparisonPlotFloorNotice,
                                  extremeSpreadAccessibilityNotice: l10n
                                      .chartComparisonExtremeValueSpreadNotice,
                                  labelBuilder: _dayAxisLabel,
                                  valueBuilder: (point) =>
                                      fullscreenIsSalesCount
                                      ? point.salesCount
                                      : point.salesAmount,
                                  tooltipLabelBuilder: (point, value) {
                                    final dateStr = _tooltipDateLine(point);
                                    return labels.tooltip(
                                      dateStr,
                                      salesCountFormat.format(
                                        point.salesCount,
                                      ),
                                      AppBrFormatters.currency(
                                        point.salesAmount,
                                      ),
                                    );
                                  },
                                  dataLabelBuilder: (_, value) =>
                                      fullscreenIsSalesCount
                                      ? compactSalesCountFormat.format(value)
                                      : AppBrFormatters.compactCurrency(value),
                                  style: overviewHomeComparisonBarChartStyle(
                                    tokens: fullscreenTokens,
                                    kind: OverviewHomeBarChartKind.daily,
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
      label: labels.semanticsForMetric(isSalesCount: isSalesCount),
      hint: labels.scopeHint,
      child: AppComparisonBarChart<OverviewDailySalesTrendPoint>(
        title: labels.titleForMetric(isSalesCount: isSalesCount),
        subtitle: labels.subtitle,
        onOpenFullscreen: openFullscreen,
        belowSubtitle: AppSegmentedControl<_OverviewDailyMetric>(
          options: <AppSegmentedControlOption<_OverviewDailyMetric>>[
            AppSegmentedControlOption<_OverviewDailyMetric>(
              value: _OverviewDailyMetric.salesCount,
              label: labels.metricCountLabel,
            ),
            AppSegmentedControlOption<_OverviewDailyMetric>(
              value: _OverviewDailyMetric.salesAmount,
              label: labels.metricAmountLabel,
            ),
          ],
          value: _metric,
          onChanged: (value) => setState(() => _metric = value),
        ),
        items: chartPoints,
        plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
        extremeSpreadAccessibilityNotice:
            l10n.chartComparisonExtremeValueSpreadNotice,
        labelBuilder: _dayAxisLabel,
        valueBuilder: (point) =>
            isSalesCount ? point.salesCount : point.salesAmount,
        tooltipLabelBuilder: (point, value) => labels.tooltip(
          _tooltipDateLine(point),
          salesCountFormat.format(point.salesCount),
          AppBrFormatters.currency(point.salesAmount),
        ),
        dataLabelBuilder: (_, value) => isSalesCount
            ? compactSalesCountFormat.format(value)
            : AppBrFormatters.compactCurrency(value),
        style: overviewHomeComparisonBarChartStyle(
          tokens: tokens,
          kind: OverviewHomeBarChartKind.daily,
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
}
