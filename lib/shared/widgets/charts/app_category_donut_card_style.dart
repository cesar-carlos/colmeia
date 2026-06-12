import 'package:flutter/material.dart';

/// Default right inset for scrollable legends so the platform scrollbar does
/// not sit on top of currency / percent columns (see map sidebar gutter).
const double kCategoryDonutLegendScrollbarGutterDefault = 18;

class AppCategoryDonutCardStyle {
  const AppCategoryDonutCardStyle({
    this.chartSize,
    this.chartMinHeight,
    this.legendMinWidth,
    this.innerRadius = '64%',
    this.outerRadius = '82%',
    this.rowSpacing,
    this.legendItemPadding,
    this.selectedRowBorderRadius,
    this.chartBackgroundColor,
    this.titleAccentWidth = 4,
    this.titleAccentHeight = 22,
    this.compactBreakpointWidth,

    /// Syncfusion doughnut sweep duration (ms). `0` disables. When null, uses
    /// [defaultDoughnutAnimationDurationMs] unless the platform requests reduced
    /// motion ([MediaQueryData.disableAnimations]).
    ///
    /// **Per-screen policy (overview home):** payment mix keeps the default
    /// sweep; category mix passes `0` so the chart does not animate on refresh.
    this.doughnutAnimationDurationMs,

    /// When non-null, the legend is placed in a scrollable column with this max
    /// height (useful for many categories beside the chart).
    this.legendMaxHeight,

    /// Right padding inside scrollable legends so values are not covered by the
    /// scrollbar thumb. Defaults to [kCategoryDonutLegendScrollbarGutterDefault].
    this.legendScrollbarGutter,

    /// When false, only the chart is shown (no category legend). Use when detail
    /// rows below already list the same breakdown.
    this.showLegend = true,
  });

  /// Default donut sweep when [doughnutAnimationDurationMs] is null.
  ///
  /// Aligned with the comparison bar charts (~350-500 ms) so that the staged
  /// dashboard mounting in `OverviewHomeChartsBelowKpis` doesn't have one
  /// outlier card animating for nearly a second while sibling charts mount.
  static const int defaultDoughnutAnimationDurationMs = 500;

  /// Fixed width/height of the square chart area when not constrained.
  final double? chartSize;

  /// Minimum height of the chart column in responsive [Column] layout.
  final double? chartMinHeight;

  /// Minimum width reserved for the legend in [Row] layout.
  final double? legendMinWidth;

  final String innerRadius;
  final String outerRadius;

  final double? rowSpacing;
  final EdgeInsetsGeometry? legendItemPadding;
  final BorderRadius? selectedRowBorderRadius;
  final Color? chartBackgroundColor;

  final double titleAccentWidth;
  final double titleAccentHeight;

  /// Below this width (card constraints), chart stacks above legend.
  /// Defaults to the app mobile breakpoint (see `AppBreakpoints.mobile`).
  final double? compactBreakpointWidth;

  final int? doughnutAnimationDurationMs;

  final double? legendMaxHeight;

  final double? legendScrollbarGutter;

  final bool showLegend;

  AppCategoryDonutCardStyle copyWith({
    double? chartSize,
    double? chartMinHeight,
    double? legendMinWidth,
    String? innerRadius,
    String? outerRadius,
    double? rowSpacing,
    EdgeInsetsGeometry? legendItemPadding,
    BorderRadius? selectedRowBorderRadius,
    Color? chartBackgroundColor,
    double? titleAccentWidth,
    double? titleAccentHeight,
    double? compactBreakpointWidth,
    int? doughnutAnimationDurationMs,
    double? legendMaxHeight,
    double? legendScrollbarGutter,
    bool? showLegend,
  }) {
    return AppCategoryDonutCardStyle(
      chartSize: chartSize ?? this.chartSize,
      chartMinHeight: chartMinHeight ?? this.chartMinHeight,
      legendMinWidth: legendMinWidth ?? this.legendMinWidth,
      innerRadius: innerRadius ?? this.innerRadius,
      outerRadius: outerRadius ?? this.outerRadius,
      rowSpacing: rowSpacing ?? this.rowSpacing,
      legendItemPadding: legendItemPadding ?? this.legendItemPadding,
      selectedRowBorderRadius:
          selectedRowBorderRadius ?? this.selectedRowBorderRadius,
      chartBackgroundColor: chartBackgroundColor ?? this.chartBackgroundColor,
      titleAccentWidth: titleAccentWidth ?? this.titleAccentWidth,
      titleAccentHeight: titleAccentHeight ?? this.titleAccentHeight,
      compactBreakpointWidth:
          compactBreakpointWidth ?? this.compactBreakpointWidth,
      doughnutAnimationDurationMs:
          doughnutAnimationDurationMs ?? this.doughnutAnimationDurationMs,
      legendMaxHeight: legendMaxHeight ?? this.legendMaxHeight,
      legendScrollbarGutter:
          legendScrollbarGutter ?? this.legendScrollbarGutter,
      showLegend: showLegend ?? this.showLegend,
    );
  }
}
