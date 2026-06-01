import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_states.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Identifies which dashboard bar chart preset is being requested.
///
/// Each kind tweaks axis formatting, header height, data-label lift,
/// minimum plotted share and other knobs that keep dashboard charts
/// visually consistent across overview/sales/etc. when they render the
/// same data shape.
enum AppDashboardComparisonBarChartKind {
  payment,
  weekday,
  daily,
  ranking,
}

/// Shared [AppComparisonBarChartStyle] preset for dashboard bar charts.
///
/// All kinds use horizontal auto-scroll when categories would be narrower
/// than the style's minimum bar slot width, plus a short bar entrance
/// animation. Category-axis pan was dropped in favour of the same
/// horizontal scroll pattern as other comparison charts (fade edges +
/// localized semantics hint).
AppComparisonBarChartStyle appDashboardComparisonBarChartStyle({
  required AppThemeTokens tokens,
  required AppDashboardComparisonBarChartKind kind,
  required AppLocalizations l10n,
  double? heightOverride,
  bool showDataLabels = true,
  bool weekdayUsesCurrencyAxis = false,
  Color? weekdayRevenueDataLabelBackground,
  Color? rankingValueLabelBackground,
}) {
  final localeName = l10n.localeName;
  final isRanking = kind == AppDashboardComparisonBarChartKind.ranking;
  final isWeekday = kind == AppDashboardComparisonBarChartKind.weekday;
  final isDaily = kind == AppDashboardComparisonBarChartKind.daily;
  final isPayment = kind == AppDashboardComparisonBarChartKind.payment;
  final isWeekdayOrDaily = isWeekday || isDaily;
  final metricRevenueAxis = isWeekdayOrDaily && weekdayUsesCurrencyAxis;

  // Compact currency labels sit just above tall bars; horizontal grid
  // lines at round tick values (e.g. R$ 20 mil) can visually cross the
  // label. Keep the same modest lift used by other comparison charts;
  // the axis range padding already creates plot headroom for labels, so
  // adding a second large top reserve leaves an empty band above the
  // bars.
  final dataLabelLiftY = metricRevenueAxis
      ? tokens.gapSm
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
    wrapXAxisMaxLines: isRanking
        ? 4
        : (isWeekday || isDaily || isPayment ? 3 : 2),
    chartPadding: isRanking || isWeekday || isDaily || isPayment
        ? EdgeInsets.only(bottom: tokens.gapSm)
        : null,
    dataLabelOffset: Offset(0, dataLabelLiftY),
    yAxisRangePadding: metricRevenueAxis || isRanking
        ? ChartRangePadding.additionalEnd
        : null,
    dataLabelBackgroundColor: metricRevenueAxis
        ? weekdayRevenueDataLabelBackground
        : (isRanking ? rankingValueLabelBackground : null),
    outerDataLabelTopReserve: isRanking ? tokens.gapSm : 0,
    dataLabelTextStyle: isRanking
        ? const TextStyle(fontSize: 11, height: 1.2, fontWeight: FontWeight.w600)
        : null,
    tooltipLabelMaxChars: 56,
    minPlottedValueShareOfMax: isRanking
        ? 0.03
        : (isWeekdayOrDaily ? 0.06 : 0.045),
    chartSemanticsCoordinatorNotice: isRanking
        ? l10n.overviewUserRankingChartSemanticsExtra
        : null,
    height:
        heightOverride ??
        (isRanking
            ? tokens.chartStandardHeight + tokens.contentSpacing * 3
            : (isPayment
                  ? tokens.chartStandardHeight + tokens.contentSpacing * 2
                  : (isWeekdayOrDaily
                        ? tokens.chartStandardHeight + tokens.contentSpacing * 2
                        : null))),
  );
}
