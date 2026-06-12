import 'package:colmeia/features/sales/domain/sales_monthly_pnl_bar_chart_preferences.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_dashboard_comparison_bar_chart_preset.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';

Widget salesMonthlyPnlBarDisplayModeSegmented({
  required AppLocalizations l10n,
  required SalesMonthlyPnlBarDisplayMode value,
  required ValueChanged<SalesMonthlyPnlBarDisplayMode>? onChanged,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 340;
      return Semantics(
        sortKey: const OrdinalSortKey(1),
        child: AppSegmentedControl<SalesMonthlyPnlBarDisplayMode>(
          expandToFill: true,
          options: <AppSegmentedControlOption<SalesMonthlyPnlBarDisplayMode>>[
            AppSegmentedControlOption<SalesMonthlyPnlBarDisplayMode>(
              value: SalesMonthlyPnlBarDisplayMode.amounts,
              label: narrow
                  ? l10n.salesMonthlyPnlBarDisplayValuesCompactLabel
                  : l10n.salesMonthlyPnlBarDisplayValuesLabel,
              tooltip: narrow
                  ? l10n.salesMonthlyPnlBarDisplayValuesLabel
                  : null,
            ),
            AppSegmentedControlOption<SalesMonthlyPnlBarDisplayMode>(
              value: SalesMonthlyPnlBarDisplayMode.percent,
              label: narrow
                  ? l10n.salesMonthlyPnlBarDisplayPercentCompactLabel
                  : l10n.salesMonthlyPnlBarDisplayPercentLabel,
              tooltip: narrow
                  ? l10n.salesMonthlyPnlBarDisplayPercentLabel
                  : null,
            ),
          ],
          value: value,
          onChanged: onChanged,
        ),
      );
    },
  );
}

AppComparisonBarChartStyle salesMonthlyPnlBarComparisonStyleWithPercent({
  required AppThemeTokens tokens,
  required AppLocalizations l10n,
  required double chartHeightOverride,
  required double animationMs,
  required NumberFormat percentRatioFormat,
}) {
  final base = appDashboardComparisonBarChartStyle(
    tokens: tokens,
    kind: AppDashboardComparisonBarChartKind.weekday,
    l10n: l10n,
    heightOverride: chartHeightOverride,
  );
  return AppComparisonBarChartStyle(
    barColor: base.barColor,
    barBorderRadius: base.barBorderRadius,
    height: base.height,
    barWidth: base.barWidth,
    spacing: base.spacing,
    barGap: base.barGap,
    borderColor: base.borderColor,
    borderWidth: base.borderWidth,
    plotAreaBackgroundColor: base.plotAreaBackgroundColor,
    chartPadding: base.chartPadding,
    animationDuration: Duration(milliseconds: animationMs.round()),
    yAxisFormat: percentRatioFormat,
    showXAxis: base.showXAxis,
    showYAxis: base.showYAxis,
    xLabelRotation: base.xLabelRotation,
    axisLabelTextStyle: base.axisLabelTextStyle,
    minY: base.minY,
    maxY: base.maxY,
    interval: base.interval,
    yAxisRangePadding: base.yAxisRangePadding,
    yAxisTitle: base.yAxisTitle,
    xAxisTitle: base.xAxisTitle,
    showTooltip: base.showTooltip,
    showYGridLines: base.showYGridLines,
    showDataLabels: base.showDataLabels,
    dataLabelTextStyle: base.dataLabelTextStyle,
    dataLabelAlignment: base.dataLabelAlignment,
    dataLabelOffset: base.dataLabelOffset,
    autoRotateXLabels: base.autoRotateXLabels,
    xLabelMaxChars: base.xLabelMaxChars,
    wrapXAxisLabelsInTwoLines: base.wrapXAxisLabelsInTwoLines,
    wrapXAxisCharsPerLine: base.wrapXAxisCharsPerLine,
    wrapXAxisMaxLines: base.wrapXAxisMaxLines,
    loadingLabel: base.loadingLabel,
    emptyMessage: base.emptyMessage,
    enableAutoScroll: base.enableAutoScroll,
    minBarWidth: base.minBarWidth,
    showScrollFade: base.showScrollFade,
    horizontalScrollSemanticsHint: base.horizontalScrollSemanticsHint,
    tooltipLabelMaxChars: base.tooltipLabelMaxChars,
    stickyPrimaryYAxisWhileScrolling: base.stickyPrimaryYAxisWhileScrolling,
    stickyPrimaryYAxisWidth: base.stickyPrimaryYAxisWidth,
    minPlottedValueShareOfMax: base.minPlottedValueShareOfMax,
    strictLinearBarHeights: base.strictLinearBarHeights,
    categoryAutoScrollingDelta: base.categoryAutoScrollingDelta,
    categoryAutoScrollingMode: base.categoryAutoScrollingMode,
    categoryViewportFootnote: base.categoryViewportFootnote,
    categoryViewportPanSemanticsLabel: base.categoryViewportPanSemanticsLabel,
    reserveOuterDataLabelTopMargin: base.reserveOuterDataLabelTopMargin,
    outerDataLabelTopReserve: base.outerDataLabelTopReserve,
    dataLabelBackgroundColor: base.dataLabelBackgroundColor,
    enableTapHighlight: base.enableTapHighlight,
    tapHighlightDimmedOpacity: base.tapHighlightDimmedOpacity,
  );
}
