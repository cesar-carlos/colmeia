import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:flutter/material.dart';

enum OverviewHomeBarChartKind {
  payment,
  ranking,
}

AppComparisonBarChartStyle overviewHomeComparisonBarChartStyle({
  required AppThemeTokens tokens,
  required OverviewHomeBarChartKind kind,
  required AppLocalizations l10n,
}) {
  final isRanking = kind == OverviewHomeBarChartKind.ranking;
  return AppComparisonBarChartStyle(
    yAxisFormat: AppBrFormatters.compactCurrencyFormat,
    horizontalScrollSemanticsHint:
        l10n.overviewComparisonBarHorizontalScrollHint,
    loadingLabel: l10n.overviewComparisonChartLoading,
    showDataLabels: true,
    autoRotateXLabels: false,
    wrapXAxisLabelsInTwoLines: true,
    wrapXAxisCharsPerLine: isRanking ? 14 : 12,
    dataLabelOffset: Offset(0, isRanking ? tokens.gapSm : tokens.gapMd),
    tooltipLabelMaxChars: 56,
    minPlottedValueShareOfMax: isRanking ? 0.03 : 0.045,
    minBarWidth: isRanking ? 84 : 76,
    height: isRanking
        ? tokens.chartStandardHeight + tokens.contentSpacing * 3
        : null,
  );
}
