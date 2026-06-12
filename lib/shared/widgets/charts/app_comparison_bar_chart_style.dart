import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_states.dart';
import 'package:colmeia/shared/widgets/widgets.dart'
    show AppChartPoint, AppComparisonBarChart;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Visual customization for [AppComparisonBarChart].
///
/// **Horizontal overflow:** use at most one of these for a given chart:
/// - `enableAutoScroll` — widens the plot and wraps it in a horizontal
///   scroll view (heavy for many categories).
/// - `categoryAutoScrollingDelta` with `enableAutoScroll` false — keeps the
///   layout width and uses Syncfusion category-axis viewport pan when bars
///   would be narrower than `minBarWidth`.
///
/// When `enableAutoScroll` is true, the engine never applies category-axis pan.
///
/// **Vertical space:** [height] is the outer box for the Syncfusion chart.
/// With [showDataLabels] and outer label alignment, the engine applies extra
/// top margin by default (see comparison bar chart margin helper) and numeric
/// axis [ChartRangePadding.additionalEnd] so labels are not clipped at the plot
/// top — tightening [height] without adjusting labels can make bars shorter;
/// prefer tuning [chartPadding], [reserveOuterDataLabelTopMargin], or label
/// alignment per screen if needed.
///
/// All other properties are optional; omitted values fall back to the
/// preset-driven defaults from the chart theme helper.
class AppComparisonBarChartStyle {
  const AppComparisonBarChartStyle({
    this.barColor,
    this.barBorderRadius = const BorderRadius.all(Radius.circular(6)),
    this.height,
    this.barWidth,
    this.spacing,
    this.barGap,
    this.borderColor,
    this.borderWidth,
    this.plotAreaBackgroundColor,
    this.chartPadding,
    this.animationDuration,
    this.yAxisFormat,
    this.showXAxis = true,
    this.showYAxis = true,
    this.xLabelRotation = 0,
    this.axisLabelTextStyle,
    this.minY,
    this.maxY,
    this.interval,
    this.yAxisRangePadding,
    this.yAxisTitle,
    this.xAxisTitle,
    this.showTooltip = true,
    this.showYGridLines = true,
    this.showDataLabels = false,
    this.dataLabelTextStyle,
    this.dataLabelAlignment = ChartDataLabelAlignment.outer,
    this.dataLabelOffset,
    this.autoRotateXLabels = true,
    this.xLabelMaxChars,
    this.wrapXAxisLabelsInTwoLines = false,
    this.wrapXAxisCharsPerLine = 14,
    this.wrapXAxisMaxLines = 2,
    this.loadingLabel,
    this.loadingPlaceholderVariant = ChartLoadingPlaceholderVariant.radial,
    this.emptyMessage,
    this.enableAutoScroll = true,
    this.minBarWidth,
    this.showScrollFade = true,
    this.horizontalScrollSemanticsHint,
    this.tooltipLabelMaxChars,
    this.stickyPrimaryYAxisWhileScrolling = true,
    this.stickyPrimaryYAxisWidth = 72,
    this.minPlottedValueShareOfMax = 0.03,
    this.strictLinearBarHeights = false,
    this.categoryAutoScrollingDelta,
    this.categoryAutoScrollingMode = AutoScrollingMode.start,
    this.categoryViewportFootnote,
    this.categoryViewportPanSemanticsLabel,
    this.reserveOuterDataLabelTopMargin = true,
    this.outerDataLabelTopReserve = 0,
    this.dataLabelBackgroundColor,
    this.enableTapHighlight = false,
    this.tapHighlightDimmedOpacity = 0.35,
    this.chartSemanticsCoordinatorNotice,
  });

  /// Solid color applied to all bars when [AppComparisonBarChart.colorBuilder]
  /// is null. Falls back to the theme's chart primary color when null.
  final Color? barColor;

  /// Corner rounding for each bar.
  final BorderRadius barBorderRadius;

  /// Fixed chart height. Falls back to the preset-driven token when null.
  final double? height;

  /// Relative width of each bar as a fraction of the bar slot, between
  /// `0.0` (invisible) and `1.0` (fills the slot). When null, the engine uses
  /// [AppChartEngineCartesianBarGeometryDefaults.columnWidthRatio].
  ///
  /// See also [barGap] for an absolute pixel alternative that is often more
  /// intuitive when you know the visual result you want.
  final double? barWidth;

  /// Relative spacing between adjacent bars as a fraction of the bar slot,
  /// between `0.0` (bars touch) and `1.0` (bars invisible). When null and
  /// [barGap] is also null, the engine uses
  /// [AppChartEngineCartesianBarGeometryDefaults.columnSpacingRatio].
  ///
  /// Prefer [barGap] when you want to express the gap in logical pixels.
  /// Setting both [spacing] and [barGap] is not recommended — [barGap] takes
  /// precedence when it is non-null.
  final double? spacing;

  /// Absolute gap in logical pixels between adjacent bars.
  ///
  /// When set, the engine converts this value to the relative [spacing] ratio
  /// that Syncfusion expects, based on the resolved per-bar slot width. This
  /// is simpler to reason about than the [0, 1] fraction used by [spacing].
  /// Set to `null` (default) to fall back to [spacing] or the engine default.
  final double? barGap;

  /// Optional outline color for each bar.
  final Color? borderColor;

  /// Optional outline width for each bar.
  final double? borderWidth;

  /// Background color behind the plot area.
  final Color? plotAreaBackgroundColor;

  /// Outer chart margin.
  ///
  /// For column charts with outer or auto label alignment and visible data
  /// labels, the Syncfusion engine merges in extra top inset so labels are not
  /// clipped.
  final EdgeInsets? chartPadding;

  /// Extra top inset (logical pixels) added after the outer–data-label
  /// headroom calculation. Use when labels (e.g. compact currency) still clip
  /// at the top of the plot at default [TextScaler] values.
  final double outerDataLabelTopReserve;

  /// Whether the engine should add top chart margin for outer data labels.
  ///
  /// Keep this enabled for the generic case. Set it to false only when the
  /// chart already reserves plot headroom through its axis range padding and
  /// the extra margin would create a large empty band above the bars.
  final bool reserveOuterDataLabelTopMargin;

  /// Optional fill behind each data label (e.g. chart/card surface) so grid
  /// lines do not run through compact currency text on tall columns.
  final Color? dataLabelBackgroundColor;

  /// Animation duration for the series.
  final Duration? animationDuration;

  /// [NumberFormat] applied to Y-axis tick labels.
  /// When null, Syncfusion renders the raw number.
  final NumberFormat? yAxisFormat;

  /// Whether the X axis is visible.
  final bool showXAxis;

  /// Whether the Y axis is visible.
  final bool showYAxis;

  /// Rotation applied to X axis labels.
  final double xLabelRotation;

  /// Shared text style for axis labels.
  final TextStyle? axisLabelTextStyle;

  /// Optional Y axis minimum.
  final num? minY;

  /// Optional Y axis maximum.
  final num? maxY;

  /// Optional Y axis interval.
  final num? interval;

  /// When set, applied as [NumericAxis.rangePadding] instead of the engine
  /// default (outer labels use [ChartRangePadding.additionalEnd]).
  ///
  /// Use [ChartRangePadding.additionalEnd] when outer data labels still clip
  /// at the plot top: Syncfusion extends the axis maximum by one tick
  /// interval, shortening the tallest column and freeing vertical space.
  final ChartRangePadding? yAxisRangePadding;

  /// Optional Y axis title.
  final String? yAxisTitle;

  /// Optional X axis title.
  final String? xAxisTitle;

  /// Whether the tap/hover tooltip is enabled.
  final bool showTooltip;

  /// Whether horizontal grid lines behind the bars are visible.
  final bool showYGridLines;

  /// Whether data labels above the bars are visible.
  final bool showDataLabels;

  /// Text style for the data labels.
  final TextStyle? dataLabelTextStyle;

  /// Position of the data labels relative to the bar.
  ///
  /// Syncfusion [ColumnSeries]: [ChartDataLabelAlignment.outer] places labels
  /// above the bar; [ChartDataLabelAlignment.top] is inside the bar's top edge.
  final ChartDataLabelAlignment dataLabelAlignment;

  /// Extra offset for data labels on Cartesian charts. Syncfusion applies this
  /// after layout: positive Y moves labels upward (more clearance above column
  /// tops when labels sit outside the bar). When null, no extra offset is set.
  final Offset? dataLabelOffset;

  /// Whether to automatically rotate X-axis labels when they would overflow
  /// the bar slot width.
  ///
  /// When `true` (default) the engine estimates the label pixel width based
  /// on character count and applies a 45° rotation when labels are too wide
  /// to fit horizontally. Set to `false` to always use [xLabelRotation].
  final bool autoRotateXLabels;

  /// Maximum number of characters to display in each X-axis label before
  /// truncating with '…'.
  ///
  /// Only affects the visual label on the X axis — tooltip text (via
  /// [AppComparisonBarChart.tooltipLabelBuilder]) still shows the full value.
  /// Set to `null` (default) to show labels at their full length.
  ///
  /// Ignored when [wrapXAxisLabelsInTwoLines] is `true` (wrap handles length).
  final int? xLabelMaxChars;

  /// When `true`, X-axis labels use word-aware wrapping into up to
  /// [wrapXAxisMaxLines] lines (`\n` between lines); overflow ends with `…`.
  /// Avoids tilted labels; pair with `autoRotateXLabels: false`.
  ///
  /// Line width is guided by [wrapXAxisCharsPerLine]. Tooltips are unchanged.
  final bool wrapXAxisLabelsInTwoLines;

  /// Soft maximum characters per line when [wrapXAxisLabelsInTwoLines] is
  /// `true`. Defaults to `14`.
  final int wrapXAxisCharsPerLine;

  /// Maximum number of lines when [wrapXAxisLabelsInTwoLines] is `true`.
  /// Overflow on the last line ends with an ellipsis (`…`). Defaults to `2`.
  final int wrapXAxisMaxLines;

  /// Override label for the loading indicator.
  ///
  /// When `null` a built-in default is used.
  final String? loadingLabel;

  /// Visual shape used while [AppComparisonBarChart.isLoading] is true.
  final ChartLoadingPlaceholderVariant loadingPlaceholderVariant;

  /// Override message for the empty state.
  ///
  /// When `null` a built-in default is used.
  final String? emptyMessage;

  /// Whether the chart automatically enables horizontal scrolling when the
  /// number of bars would make them too narrow to read.
  ///
  /// When `true` (default) the engine compares the required chart width
  /// (`items.length × minBarWidth`) against the available layout width and
  /// wraps the chart in a [SingleChildScrollView] only when necessary.
  /// Set to `false` to always fill the available width and never scroll.
  final bool enableAutoScroll;

  /// Minimum logical-pixel width reserved for each bar slot (bar + gap) when
  /// [enableAutoScroll] is `true`.
  ///
  /// When null the engine uses [AppChartEngineCartesianBarGeometryDefaults.minCategorySlotWidth].
  final double? minBarWidth;

  /// Whether to show a subtle fade gradient on the trailing edge of the chart
  /// when horizontal scrolling is active. Defaults to `true`.
  final bool showScrollFade;

  /// When horizontal scrolling is active, announced as a Semantics hint on the
  /// scrollable. When null, no extra semantics wrapper is applied.
  final String? horizontalScrollSemanticsHint;

  /// Truncates tooltip text to this length (ellipsis). When null, tooltips are
  /// unchanged. Helps avoid layout overflow for long category names.
  final int? tooltipLabelMaxChars;

  /// When true and horizontal scroll is active, keeps the primary (left) Y-axis
  /// labels in a fixed column while the plot scrolls.
  final bool stickyPrimaryYAxisWhileScrolling;

  /// Width reserved for the sticky primary Y-axis column (tick labels).
  final double stickyPrimaryYAxisWidth;

  /// Minimum column height as a fraction of the largest positive value in the
  /// series. Positive values below `maxPositive * this` are drawn at that
  /// floor so tiny outliers stay visible; each point's numeric value field is
  /// unchanged for data labels, tooltips, and tap payloads. Set to `0` to keep
  /// strict linear proportions. Ignored when [strictLinearBarHeights] is true.
  final double minPlottedValueShareOfMax;

  /// When true, column heights match [AppChartPoint.value] exactly (no minimum
  /// height lift via [AppChartPoint.plottedValue]).
  final bool strictLinearBarHeights;

  /// Syncfusion [CategoryAxis.autoScrollingDelta] when [enableAutoScroll] is
  /// `false`: show at most this many adjacent categories at once once the bar
  /// slots would be narrower than [minBarWidth], and let the user pan the plot
  /// horizontally ([ZoomPanBehavior], [ZoomMode.x]) to see the rest. The chart
  /// width stays equal to the layout width (unlike [enableAutoScroll], which
  /// grows the plot and wraps it in a horizontal [ScrollView]).
  ///
  /// Ignored when null, when there are fewer points than this value, or when
  /// bars are already wide enough for the layout.
  final int? categoryAutoScrollingDelta;

  /// Which end of the category axis [categoryAutoScrollingDelta] anchors to
  /// when panning is active. Defaults to [AutoScrollingMode.start] (highest-
  /// priority categories first when data are pre-sorted).
  final AutoScrollingMode categoryAutoScrollingMode;

  /// Short line shown under the plot when category viewport pan is active
  /// (helps discovery vs a scrollbar). Ignored when null.
  final String? categoryViewportFootnote;

  /// Screen reader label when category viewport pan is active.
  /// Ignored when null (hint may still come from horizontal scroll semantics).
  final String? categoryViewportPanSemanticsLabel;

  /// When true, tapping a bar visually highlights it (Syncfusion
  /// [SelectionBehavior]): the tapped column keeps full opacity while siblings
  /// fade to [tapHighlightDimmedOpacity]. Single-select; tapping again clears.
  ///
  /// Independent from `AppComparisonBarChart.onPointTap` / `onPointTapEvent` —
  /// those callbacks still fire on the same gesture.
  final bool enableTapHighlight;

  /// Opacity applied to non-selected bars while [enableTapHighlight] is active.
  /// Defaults to `0.35`; set lower to dim more, `1.0` to disable the dim.
  final double tapHighlightDimmedOpacity;

  /// Optional extra sentence appended to the coordinator [Semantics] label for
  /// the chart body (after plot-floor / extreme-spread notices when present).
  final String? chartSemanticsCoordinatorNotice;

  /// Landscape fullscreen display: fit every category in the viewport width.
  AppComparisonBarChartStyle forLandscapeFullscreen({double? height}) {
    return AppComparisonBarChartStyle(
      barColor: barColor,
      barBorderRadius: barBorderRadius,
      height: height ?? this.height,
      barWidth: barWidth,
      spacing: spacing,
      barGap: barGap,
      borderColor: borderColor,
      borderWidth: borderWidth,
      plotAreaBackgroundColor: plotAreaBackgroundColor,
      chartPadding: chartPadding,
      animationDuration: animationDuration,
      yAxisFormat: yAxisFormat,
      showXAxis: showXAxis,
      showYAxis: showYAxis,
      xLabelRotation: xLabelRotation,
      axisLabelTextStyle: axisLabelTextStyle,
      minY: minY,
      maxY: maxY,
      interval: interval,
      yAxisRangePadding: yAxisRangePadding,
      yAxisTitle: yAxisTitle,
      xAxisTitle: xAxisTitle,
      showTooltip: showTooltip,
      showYGridLines: showYGridLines,
      showDataLabels: showDataLabels,
      dataLabelTextStyle: dataLabelTextStyle,
      dataLabelAlignment: dataLabelAlignment,
      dataLabelOffset: dataLabelOffset,
      autoRotateXLabels: autoRotateXLabels,
      xLabelMaxChars: xLabelMaxChars,
      wrapXAxisLabelsInTwoLines: wrapXAxisLabelsInTwoLines,
      wrapXAxisCharsPerLine: wrapXAxisCharsPerLine,
      wrapXAxisMaxLines: wrapXAxisMaxLines,
      loadingLabel: loadingLabel,
      loadingPlaceholderVariant: loadingPlaceholderVariant,
      emptyMessage: emptyMessage,
      enableAutoScroll: false,
      minBarWidth: minBarWidth,
      showScrollFade: false,
      horizontalScrollSemanticsHint: horizontalScrollSemanticsHint,
      tooltipLabelMaxChars: tooltipLabelMaxChars,
      stickyPrimaryYAxisWhileScrolling: false,
      stickyPrimaryYAxisWidth: stickyPrimaryYAxisWidth,
      minPlottedValueShareOfMax: minPlottedValueShareOfMax,
      strictLinearBarHeights: strictLinearBarHeights,
      categoryAutoScrollingMode: categoryAutoScrollingMode,
      categoryViewportFootnote: categoryViewportFootnote,
      categoryViewportPanSemanticsLabel: categoryViewportPanSemanticsLabel,
      reserveOuterDataLabelTopMargin: reserveOuterDataLabelTopMargin,
      outerDataLabelTopReserve: outerDataLabelTopReserve,
      dataLabelBackgroundColor: dataLabelBackgroundColor,
      tapHighlightDimmedOpacity: tapHighlightDimmedOpacity,
      chartSemanticsCoordinatorNotice: chartSemanticsCoordinatorNotice,
    );
  }

  /// Style for offscreen PDF export: full width, no scroll, no animation.
  AppComparisonBarChartStyle forPdfExport() {
    return AppComparisonBarChartStyle(
      barColor: barColor,
      barBorderRadius: barBorderRadius,
      height: height,
      barWidth: barWidth,
      spacing: spacing,
      barGap: barGap,
      borderColor: borderColor,
      borderWidth: borderWidth,
      plotAreaBackgroundColor: plotAreaBackgroundColor,
      chartPadding: chartPadding,
      animationDuration: Duration.zero,
      yAxisFormat: yAxisFormat,
      showXAxis: showXAxis,
      showYAxis: showYAxis,
      xLabelRotation: xLabelRotation,
      axisLabelTextStyle: axisLabelTextStyle,
      minY: minY,
      maxY: maxY,
      interval: interval,
      yAxisRangePadding: yAxisRangePadding,
      yAxisTitle: yAxisTitle,
      xAxisTitle: xAxisTitle,
      showTooltip: showTooltip,
      showYGridLines: showYGridLines,
      showDataLabels: showDataLabels,
      dataLabelTextStyle: dataLabelTextStyle,
      dataLabelAlignment: dataLabelAlignment,
      dataLabelOffset: dataLabelOffset,
      autoRotateXLabels: autoRotateXLabels,
      xLabelMaxChars: xLabelMaxChars,
      wrapXAxisLabelsInTwoLines: wrapXAxisLabelsInTwoLines,
      wrapXAxisCharsPerLine: wrapXAxisCharsPerLine,
      wrapXAxisMaxLines: wrapXAxisMaxLines,
      loadingLabel: loadingLabel,
      loadingPlaceholderVariant: loadingPlaceholderVariant,
      emptyMessage: emptyMessage,
      enableAutoScroll: false,
      minBarWidth: minBarWidth,
      showScrollFade: false,
      horizontalScrollSemanticsHint: horizontalScrollSemanticsHint,
      tooltipLabelMaxChars: tooltipLabelMaxChars,
      stickyPrimaryYAxisWhileScrolling: false,
      stickyPrimaryYAxisWidth: stickyPrimaryYAxisWidth,
      minPlottedValueShareOfMax: minPlottedValueShareOfMax,
      strictLinearBarHeights: strictLinearBarHeights,
      categoryAutoScrollingMode: categoryAutoScrollingMode,
      categoryViewportFootnote: categoryViewportFootnote,
      categoryViewportPanSemanticsLabel: categoryViewportPanSemanticsLabel,
      reserveOuterDataLabelTopMargin: reserveOuterDataLabelTopMargin,
      outerDataLabelTopReserve: outerDataLabelTopReserve,
      dataLabelBackgroundColor: dataLabelBackgroundColor,
      tapHighlightDimmedOpacity: tapHighlightDimmedOpacity,
      chartSemanticsCoordinatorNotice: chartSemanticsCoordinatorNotice,
    );
  }
}
