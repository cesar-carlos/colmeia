import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/charts/metric_toggle_comparison_bar_fullscreen_body.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Visual parity with the home dashboard comparison bar charts (ranking /
/// payment): horizontal auto-scroll, wrapped multi-line X labels, outer data
/// labels, and shared semantics/loading copy.
AppComparisonBarChartStyle salesTrendHomeLikeComparisonBarChartStyle({
  required AppThemeTokens tokens,
  required AppLocalizations l10n,
  required NumberFormat yAxisFormat,
  double? heightOverride,
  double minPlottedValueShareOfMax = 0.045,
}) {
  return AppComparisonBarChartStyle(
    animationDuration: const Duration(milliseconds: 350),
    stickyPrimaryYAxisWhileScrolling: false,
    enableTapHighlight: true,
    yAxisFormat: yAxisFormat,
    horizontalScrollSemanticsHint:
        l10n.overviewComparisonBarHorizontalScrollHint,
    loadingLabel: l10n.overviewComparisonChartLoading,
    showDataLabels: true,
    autoRotateXLabels: false,
    wrapXAxisLabelsInTwoLines: true,
    wrapXAxisCharsPerLine: 11,
    wrapXAxisMaxLines: 3,
    chartPadding: EdgeInsets.only(bottom: tokens.gapSm),
    dataLabelOffset: Offset(0, tokens.gapSm),
    tooltipLabelMaxChars: 56,
    minPlottedValueShareOfMax: minPlottedValueShareOfMax,
    height:
        heightOverride ??
        tokens.chartStandardHeight + tokens.contentSpacing * 2,
  );
}

/// Style for top-movers comparison charts (up to 15 products): tighter X labels
/// and optional landscape fullscreen fit when every category should be visible.
AppComparisonBarChartStyle salesTrendTopMoversComparisonBarChartStyle({
  required BuildContext context,
  required AppThemeTokens tokens,
  required AppLocalizations l10n,
  required NumberFormat yAxisFormat,
  double? heightOverride,
}) {
  final built = AppComparisonBarChartStyle(
    animationDuration: const Duration(milliseconds: 350),
    stickyPrimaryYAxisWhileScrolling: false,
    enableTapHighlight: true,
    yAxisFormat: yAxisFormat,
    horizontalScrollSemanticsHint:
        l10n.overviewComparisonBarHorizontalScrollHint,
    loadingLabel: l10n.overviewComparisonChartLoading,
    showDataLabels: true,
    autoRotateXLabels: false,
    wrapXAxisLabelsInTwoLines: true,
    wrapXAxisCharsPerLine: 10,
    chartPadding: EdgeInsets.only(bottom: tokens.gapSm),
    dataLabelOffset: Offset(0, tokens.gapSm),
    tooltipLabelMaxChars: 56,
    height:
        heightOverride ??
        tokens.chartStandardHeight + tokens.contentSpacing * 2,
  );
  if (isLandscapeChartViewport(context)) {
    return built.forLandscapeFullscreen(height: heightOverride);
  }
  return built;
}
