import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum OverviewHomeBarChartKind {
  payment,
  weekday,
  ranking,
}

AppComparisonBarChartStyle overviewHomeComparisonBarChartStyle({
  required AppThemeTokens tokens,
  required OverviewHomeBarChartKind kind,
  required AppLocalizations l10n,
  bool showDataLabels = true,
  bool weekdayUsesCurrencyAxis = false,
  int? comparisonCategoryCount,
}) {
  final localeName = l10n.localeName;
  final isRanking = kind == OverviewHomeBarChartKind.ranking;
  final isWeekday = kind == OverviewHomeBarChartKind.weekday;
  final isPayment = kind == OverviewHomeBarChartKind.payment;
  const categoryPanDelta = 6;

  /// Default when [comparisonCategoryCount] is not passed (e.g. tests).
  const weekdayCategoryCountDefault = 7;
  final panCategoryCount =
      isPayment &&
          comparisonCategoryCount != null &&
          comparisonCategoryCount > categoryPanDelta
      ? comparisonCategoryCount
      : null;
  final showCategoryPanHintsPayment = panCategoryCount != null;
  return AppComparisonBarChartStyle(
    animationDuration: Duration.zero,
    // Defaults enable auto-scroll + sticky Y; that builds two SfCartesianChart
    // trees when the plot overflows (e.g. 7 weekdays × minBarWidth). Same
    // pattern as the overview monthly combo ANR (NDJSON f480b8).
    enableAutoScroll: false,
    // Pan inside fixed-width chart (CategoryAxis.autoScrollingDelta) instead of
    // an extra-wide plot + horizontal ScrollView — see Syncfusion docs / ANR.
    categoryAutoScrollingDelta:
        (isPayment || isWeekday || isRanking) ? categoryPanDelta : null,
    categoryViewportFootnote:
        (showCategoryPanHintsPayment || isWeekday || isRanking)
        ? l10n.chartComparisonPanGestureHint
        : null,
    categoryViewportPanSemanticsLabel: isWeekday
        ? l10n.chartComparisonPanChartA11y(
            comparisonCategoryCount ?? weekdayCategoryCountDefault,
          )
        : isRanking
        ? (comparisonCategoryCount != null && comparisonCategoryCount > 0
              ? l10n.chartComparisonPanChartA11y(comparisonCategoryCount)
              : null)
        : (panCategoryCount == null
              ? null
              : l10n.chartComparisonPanChartA11y(panCategoryCount)),
    stickyPrimaryYAxisWhileScrolling: false,
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
    // Slightly smaller vertical lift than weekday: long currency labels need
    // headroom; the comparison chart engine adds extra top margin accordingly.
    dataLabelOffset: Offset(
      0,
      (isRanking || isPayment) ? tokens.gapSm : tokens.gapMd,
    ),
    tooltipLabelMaxChars: 56,
    minPlottedValueShareOfMax: isRanking
        ? 0.03
        : (isWeekday ? 0.06 : 0.045),
    minBarWidth: isRanking ? 84 : (isWeekday ? 72 : 76),
    height: isRanking
        ? tokens.chartStandardHeight + tokens.contentSpacing * 3
        : (isPayment
              // Taller plot: compact currency labels still need headroom, but
              // less top margin than before — see resolveComparisonBarChartMargin.
              ? tokens.chartStandardHeight + tokens.contentSpacing * 2
              : (isWeekday
                    ? tokens.chartStandardHeight + tokens.contentSpacing * 2
                    : null)),
  );
}
