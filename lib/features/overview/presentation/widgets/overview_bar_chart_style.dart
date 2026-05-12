import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_states.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

enum OverviewHomeBarChartKind {
  payment,
  weekday,
  daily,
  ranking,
}

/// Shared [AppComparisonBarChartStyle] for overview / home dashboard bar charts.
///
/// All kinds use horizontal auto-scroll when categories would be narrower than
/// the style's minimum bar slot width, plus a short bar entrance animation. Category-axis pan was
/// dropped in favour of the same horizontal scroll pattern as other comparison
/// charts (fade edges + localized semantics hint).
AppComparisonBarChartStyle overviewHomeComparisonBarChartStyle({
  required AppThemeTokens tokens,
  required OverviewHomeBarChartKind kind,
  required AppLocalizations l10n,
  double? heightOverride,
  bool showDataLabels = true,
  bool weekdayUsesCurrencyAxis = false,
  Color? weekdayRevenueDataLabelBackground,
}) {
  final localeName = l10n.localeName;
  final isRanking = kind == OverviewHomeBarChartKind.ranking;
  final isWeekday = kind == OverviewHomeBarChartKind.weekday;
  final isDaily = kind == OverviewHomeBarChartKind.daily;
  final isPayment = kind == OverviewHomeBarChartKind.payment;
  final isWeekdayOrDaily = isWeekday || isDaily;
  final metricRevenueAxis = isWeekdayOrDaily && weekdayUsesCurrencyAxis;

  // Compact currency labels sit just above tall bars; horizontal grid lines at
  // round tick values (e.g. R$ 20 mil) can visually cross the label. Lift outer
  // labels more than count-mode labels and reserve extra axis headroom.
  final dataLabelLiftY = metricRevenueAxis
      ? tokens.contentSpacing + tokens.gapSm
      : (isRanking || isPayment ? tokens.gapSm : tokens.gapMd);

  return AppComparisonBarChartStyle(
    animationDuration: const Duration(milliseconds: 350),
    stickyPrimaryYAxisWhileScrolling: false,
    enableTapHighlight: isPayment || isRanking,
    yAxisFormat: isWeekdayOrDaily
        ? (weekdayUsesCurrencyAxis
              ? AppBrFormatters.compactCurrencyFormatForLocale(localeName)
              : NumberFormat.decimalPattern(localeName))
        : AppBrFormatters.compactCurrencyFormatForLocale(localeName),
    horizontalScrollSemanticsHint:
        l10n.overviewComparisonBarHorizontalScrollHint,
    loadingLabel: l10n.overviewComparisonChartLoading,
    loadingPlaceholderVariant: isDaily
        ? ChartLoadingPlaceholderVariant.timeSeries
        : ChartLoadingPlaceholderVariant.radial,
    showDataLabels: showDataLabels,
    autoRotateXLabels: false,
    wrapXAxisLabelsInTwoLines: true,
    wrapXAxisCharsPerLine: isRanking || isWeekday || isDaily || isPayment
        ? 11
        : 12,
    wrapXAxisMaxLines: isRanking || isWeekday || isDaily || isPayment ? 3 : 2,
    chartPadding: isRanking || isWeekday || isDaily || isPayment
        ? EdgeInsets.only(bottom: tokens.gapSm)
        : null,
    dataLabelOffset: Offset(0, dataLabelLiftY),
    yAxisRangePadding: metricRevenueAxis
        ? ChartRangePadding.additionalEnd
        : null,
    // Compact currency labels use annotation widgets with padded containers plus a
    // negative Y transform; reserved margin can still clip the tallest column.
    outerDataLabelTopReserve: metricRevenueAxis
        ? tokens.contentSpacing + tokens.gapSm
        : 0,
    dataLabelBackgroundColor: metricRevenueAxis
        ? weekdayRevenueDataLabelBackground
        : null,
    tooltipLabelMaxChars: 56,
    minPlottedValueShareOfMax: isRanking
        ? 0.03
        : (isWeekdayOrDaily ? 0.06 : 0.045),
    height:
        heightOverride ??
        (isRanking
            ? tokens.chartStandardHeight + tokens.contentSpacing * 2
            : (isPayment
                  ? tokens.chartStandardHeight + tokens.contentSpacing * 2
                  : (isWeekdayOrDaily
                        ? tokens.chartStandardHeight + tokens.contentSpacing * 2
                        : null))),
  );
}
