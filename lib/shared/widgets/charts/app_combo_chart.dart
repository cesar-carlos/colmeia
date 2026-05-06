import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_combo_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Visual customization for [AppComboChart].
///
/// **Horizontal overflow:** prefer a single strategy per chart instance:
/// - `enableAutoScroll` true — widens the plot to at least the default minimum
///   category slot width per category and wraps it in a horizontal scroll view
///   (can be heavy on many points; overview keeps this off for ANR safety).
/// - `categoryAutoScrollingDelta` with `enableAutoScroll` false — keeps layout
///   width and uses Syncfusion category-axis viewport pan when categories
///   would be narrower than [minCategorySlotWidth].
///
/// When `enableAutoScroll` is true, category viewport pan is not applied.
class AppComboChartStyle {
  const AppComboChartStyle({
    this.height,
    this.barWidth,
    this.barSpacing,
    this.lineWidth,
    this.chartPadding,
    this.animationDuration,
    this.leftAxisFormat,
    this.rightAxisFormat,
    this.showTooltip = true,
    this.showYGridLines = true,
    this.showXAxis = true,
    this.showRightYAxis = true,
    this.showLineSeries = true,
    this.showLegend = true,
    this.showMarkers = true,
    this.axisLabelTextStyle,
    this.legendTextStyle,
    this.barColor,
    this.lineColor,
    this.barBorderRadius = const BorderRadius.all(Radius.circular(6)),
    this.showDataLabels = false,
    this.dataLabelTextStyle,
    this.barDataLabelAlignment = ChartDataLabelAlignment.outer,
    this.barDataLabelOffset,
    this.enableAutoScroll = true,
    this.minCategorySlotWidth =
        AppChartEngineCartesianBarGeometryDefaults.minCategorySlotWidth,
    this.showScrollFade = true,
    this.horizontalScrollSemanticsHint,
    this.stickyPrimaryYAxisWhileScrolling = true,
    this.stickyPrimaryYAxisWidth = 72,
    this.loadingLabel,
    this.emptyMessage,
    this.categoryAutoScrollingDelta,
    this.categoryAutoScrollingMode = AutoScrollingMode.start,
    this.categoryViewportFootnote,
    this.categoryViewportPanSemanticsLabel,
    this.categoryLabelIntersectAction,
    this.tooltipBodyResolver,
    this.minPlottedBarValueShareOfMax = 0.03,
    this.strictLinearBarHeights = false,
  });

  final double? height;
  final double? barWidth;
  final double? barSpacing;
  final double? lineWidth;
  final EdgeInsets? chartPadding;
  final Duration? animationDuration;

  /// [NumberFormat] for the left Y-axis (bar values).
  final NumberFormat? leftAxisFormat;

  /// [NumberFormat] for the right Y-axis (line values).
  final NumberFormat? rightAxisFormat;

  final bool showTooltip;
  final bool showYGridLines;
  final bool showXAxis;

  /// When false, hides the right Y-axis tick labels (line series scale). The
  /// line still uses that axis for scaling; the chart tooltip lists both
  /// series so the line value stays readable without secondary ticks.
  final bool showRightYAxis;

  /// When false, only the column series is drawn (no line, markers, or line
  /// legend entry). `AppComboChart` still requires line builder and label
  /// parameters; the engine ignores them when this is false.
  final bool showLineSeries;

  final bool showLegend;

  /// Whether each line data point shows a marker dot.
  final bool showMarkers;

  final TextStyle? axisLabelTextStyle;
  final TextStyle? legendTextStyle;

  /// Optional bar color override. Falls back to the chart theme primary color.
  final Color? barColor;

  /// Optional line color override. Falls back to the chart theme secondary
  /// color.
  final Color? lineColor;

  /// Corner rounding for bar columns (default 6px radius, same as comparison bars).
  final BorderRadius barBorderRadius;

  final bool showDataLabels;
  final TextStyle? dataLabelTextStyle;

  /// Placement of bar column data labels when [showDataLabels] is true.
  final ChartDataLabelAlignment barDataLabelAlignment;

  /// Extra offset for bar data labels (Syncfusion: positive Y lifts outer labels).
  final Offset? barDataLabelOffset;

  /// When true, widens the plot (minimum [minCategorySlotWidth] per category)
  /// and wraps it in horizontal scroll if wider than the layout.
  final bool enableAutoScroll;

  /// Minimum logical width per category (bar slot) when [enableAutoScroll] is
  /// true. Defaults to the shared cartesian column default minimum slot width
  /// (see `chart_engine_defaults.dart`). Higher values trigger horizontal scroll
  /// sooner on narrow layouts. Also used with [categoryAutoScrollingDelta] to
  /// detect a crowded X-axis.
  final double minCategorySlotWidth;

  /// Trailing edge fade when horizontal scroll is active.
  final bool showScrollFade;

  /// Semantics hint when horizontal scroll or category pan is active.
  final String? horizontalScrollSemanticsHint;

  /// When true and horizontal scroll is active, keeps the primary (left) Y-axis
  /// labels in a fixed column while the plot scrolls.
  final bool stickyPrimaryYAxisWhileScrolling;

  /// Width reserved for the sticky primary Y-axis column (tick labels).
  final double stickyPrimaryYAxisWidth;

  /// Override loading string; when null, [AppComboChart] uses l10n default.
  final String? loadingLabel;

  /// Override empty engine message; when null, [AppComboChart] uses l10n default.
  final String? emptyMessage;

  /// Syncfusion [CategoryAxis.autoScrollingDelta] when [enableAutoScroll] is
  /// false (same idea as the comparison bar chart).
  final int? categoryAutoScrollingDelta;

  final AutoScrollingMode categoryAutoScrollingMode;

  /// Shown under the plot when category viewport pan is active.
  final String? categoryViewportFootnote;

  /// Screen reader label when category viewport pan is active.
  final String? categoryViewportPanSemanticsLabel;

  /// When set, overrides the default slot-width-based X-axis label overlap
  /// policy in the Syncfusion engine.
  final AxisLabelIntersectAction? categoryLabelIntersectAction;

  /// Optional Syncfusion tooltip body override or augmentation (runs after the
  /// chart fills default tooltip text; return non-null to replace [TooltipArgs.text]).
  final String? Function(TooltipArgs args)? tooltipBodyResolver;

  /// Minimum plotted height for positive bars as a fraction of the largest
  /// positive bar value in the same series.
  ///
  /// Keeps very small bars visible without changing their real numeric value in
  /// labels, tooltips, or tap callbacks. Defaults to `0.03`, matching the
  /// shared comparison bar chart. Set to `0` to keep strict linear proportions
  /// unless [strictLinearBarHeights] is enabled explicitly.
  final double minPlottedBarValueShareOfMax;

  /// When true, combo-chart bar heights match the real bar value exactly.
  ///
  /// Disables any readability floor configured through
  /// [minPlottedBarValueShareOfMax].
  final bool strictLinearBarHeights;
}

enum AppComboChartSeriesType {
  bar,
  line,
}

class AppComboChartPointTapEvent<T> {
  const AppComboChartPointTapEvent({
    required this.item,
    required this.index,
    required this.seriesType,
    required this.value,
  });

  final T item;
  final int index;
  final AppComboChartSeriesType seriesType;
  final num value;
}

/// Mixed bar + line chart for scenarios where two metrics share the same
/// X-axis but have different scales or visual emphasis.
///
/// The bar series is plotted against the left Y-axis; the line series is
/// plotted against the right Y-axis. Both axes can be formatted independently.
///
/// When [AppComboChartStyle.showRightYAxis] is false, the line still scales on
/// the right axis but tick labels are hidden; the combo engine uses a shared
/// tooltip so both series values remain visible on tap/long-press.
///
/// Usage:
/// ```dart
/// AppComboChart<_DaySummary>(
///   title: 'Pedidos e ticket médio',
///   items: _daySummaries,
///   xLabelBuilder: (d) => d.label,
///   barValueBuilder: (d) => d.orders,
///   barSeriesLabel: 'Pedidos',
///   lineValueBuilder: (d) => d.avgTicket,
///   lineSeriesLabel: 'Ticket médio',
///   style: AppComboChartStyle(
///     rightAxisFormat: AppBrFormatters.compactCurrencyFormat,
///   ),
/// )
/// ```
class AppComboChart<T> extends StatelessWidget {
  const AppComboChart({
    required this.items,
    required this.xLabelBuilder,
    required this.barValueBuilder,
    required this.barSeriesLabel,
    required this.lineValueBuilder,
    required this.lineSeriesLabel,
    super.key,
    this.title,
    this.subtitle,
    this.titleTrailing,
    this.onOpenFullscreen,
    this.openFullscreenTooltip,
    this.openFullscreenSemanticLabel,
    this.belowSubtitle,
    this.onBarTap,
    this.onLineTap,
    this.onBarTapEvent,
    this.onLineTapEvent,
    this.barDataLabelBuilder,
    this.style = const AppComboChartStyle(),
    this.preset = AppChartPreset.standard,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  /// Same idea as `AppComparisonBarChart.loadingBlockHeight` / the donut
  /// card helper: returns the height the engine reserves so callers can
  /// allocate the same space for an external placeholder while staged
  /// mounting.
  static double loadingBlockHeight(
    AppThemeTokens tokens, {
    AppChartPreset preset = AppChartPreset.standard,
    double? styleHeight,
  }) {
    if (styleHeight != null) {
      return styleHeight;
    }
    return switch (preset) {
      AppChartPreset.compact => tokens.chartCompactHeight,
      AppChartPreset.standard => tokens.chartStandardHeight,
      AppChartPreset.explorable => tokens.chartStandardHeight,
    };
  }

  final List<T> items;
  final String Function(T item) xLabelBuilder;

  final num Function(T item) barValueBuilder;

  /// Legend label for the bar series.
  final String barSeriesLabel;

  final num Function(T item) lineValueBuilder;

  /// Legend label for the line series.
  final String lineSeriesLabel;

  /// Optional label above each bar when `style.showDataLabels` is true.
  final String? Function(T item, num barValue)? barDataLabelBuilder;

  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final VoidCallback? onOpenFullscreen;
  final String? openFullscreenTooltip;
  final String? openFullscreenSemanticLabel;
  final Widget? belowSubtitle;

  /// Called when the user taps a bar data point.
  final void Function(T item, int index)? onBarTap;

  /// Called when the user taps a line data point.
  final void Function(T item, int index)? onLineTap;

  final ValueChanged<AppComboChartPointTapEvent<T>>? onBarTapEvent;

  final ValueChanged<AppComboChartPointTapEvent<T>>? onLineTapEvent;

  final AppComboChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final resolvedLoadingLabel =
        style.loadingLabel ?? l10n?.chartComboLoadingDefault;
    final resolvedEmptyMessage =
        style.emptyMessage ?? l10n?.chartComboEmptyDefault;

    void handleBarTap(T item, int index) {
      onBarTap?.call(item, index);
      onBarTapEvent?.call(
        AppComboChartPointTapEvent(
          item: item,
          index: index,
          seriesType: AppComboChartSeriesType.bar,
          value: barValueBuilder(item),
        ),
      );
    }

    void handleLineTap(T item, int index) {
      onLineTap?.call(item, index);
      onLineTapEvent?.call(
        AppComboChartPointTapEvent(
          item: item,
          index: index,
          seriesType: AppComboChartSeriesType.line,
          value: lineValueBuilder(item),
        ),
      );
    }

    final innerChart = SyncfusionComboChart<T>(
      items: items,
      xLabelBuilder: xLabelBuilder,
      barValueBuilder: barValueBuilder,
      barSeriesLabel: barSeriesLabel,
      lineValueBuilder: lineValueBuilder,
      lineSeriesLabel: lineSeriesLabel,
      style: style,
      preset: preset,
      onBarTap: (onBarTap == null && onBarTapEvent == null)
          ? null
          : handleBarTap,
      onLineTap: (onLineTap == null && onLineTapEvent == null)
          ? null
          : handleLineTap,
      barDataLabelBuilder: barDataLabelBuilder,
      isLoading: isLoading,
      emptyPlaceholder: emptyPlaceholder,
      resolvedLoadingLabel: resolvedLoadingLabel,
      resolvedEmptyMessage: resolvedEmptyMessage,
    );

    if (title == null) {
      return innerChart;
    }

    return AppChartShell(
      title: title!,
      subtitle: subtitle,
      titleTrailing: titleTrailing,
      onOpenFullscreen: onOpenFullscreen,
      openFullscreenTooltip: openFullscreenTooltip,
      openFullscreenSemanticLabel: openFullscreenSemanticLabel,
      belowSubtitle: belowSubtitle,
      child: innerChart,
    );
  }
}
