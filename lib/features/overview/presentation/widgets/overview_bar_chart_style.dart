import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

enum OverviewHomeBarChartKind {
  payment,
  weekday,
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
  bool showDataLabels = true,
  bool weekdayUsesCurrencyAxis = false,
  Color? weekdayRevenueDataLabelBackground,
}) {
  final localeName = l10n.localeName;
  final isRanking = kind == OverviewHomeBarChartKind.ranking;
  final isWeekday = kind == OverviewHomeBarChartKind.weekday;
  final isPayment = kind == OverviewHomeBarChartKind.payment;
  final weekdayRevenue = isWeekday && weekdayUsesCurrencyAxis;

  return AppComparisonBarChartStyle(
    animationDuration: const Duration(milliseconds: 350),
    stickyPrimaryYAxisWhileScrolling: false,
    enableTapHighlight: isPayment || isRanking,
    yAxisFormat: isWeekday
        ? (weekdayUsesCurrencyAxis
              ? AppBrFormatters.compactCurrencyFormatForLocale(localeName)
              : NumberFormat.decimalPattern(localeName))
        : AppBrFormatters.compactCurrencyFormatForLocale(localeName),
    horizontalScrollSemanticsHint:
        l10n.overviewComparisonBarHorizontalScrollHint,
    loadingLabel: l10n.overviewComparisonChartLoading,
    showDataLabels: showDataLabels,
    autoRotateXLabels: false,
    wrapXAxisLabelsInTwoLines: true,
    wrapXAxisCharsPerLine: isRanking ? 14 : (isWeekday ? 10 : 12),
    xLabelMaxChars: isRanking ? 22 : null,
    dataLabelOffset: Offset(
      0,
      weekdayRevenue
          ? tokens.gapMd + tokens.gapSm + tokens.gapXs
          : ((isRanking || isPayment) ? tokens.gapSm : tokens.gapMd),
    ),
    outerDataLabelTopReserve: weekdayRevenue ? tokens.contentSpacing : 0,
    yAxisRangePadding:
        weekdayRevenue ? ChartRangePadding.additionalEnd : null,
    dataLabelBackgroundColor:
        weekdayRevenue ? weekdayRevenueDataLabelBackground : null,
    tooltipLabelMaxChars: 56,
    minPlottedValueShareOfMax: isRanking
        ? 0.03
        : (isWeekday ? 0.06 : 0.045),
    minBarWidth: isRanking ? 88 : (isWeekday ? 92 : 82),
    height: isRanking
        ? tokens.chartStandardHeight + tokens.contentSpacing * 3
        : (isPayment
              ? tokens.chartStandardHeight + tokens.contentSpacing * 2
              : (isWeekday
                    ? tokens.chartStandardHeight + tokens.contentSpacing * 2
                    : null)),
  );
}
