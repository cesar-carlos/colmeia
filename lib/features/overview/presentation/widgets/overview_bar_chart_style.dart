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
}) {
  final localeName = l10n.localeName;
  final isRanking = kind == OverviewHomeBarChartKind.ranking;
  final isWeekday = kind == OverviewHomeBarChartKind.weekday;
  return AppComparisonBarChartStyle(
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
    dataLabelOffset: Offset(0, isRanking ? tokens.gapSm : tokens.gapMd),
    tooltipLabelMaxChars: 56,
    minPlottedValueShareOfMax: isRanking ? 0.03 : (isWeekday ? 0.06 : 0.045),
    minBarWidth: isRanking ? 84 : (isWeekday ? 72 : 76),
    height: isRanking
        ? tokens.chartStandardHeight + tokens.contentSpacing * 3
        : null,
  );
}
