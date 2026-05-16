import 'dart:math' as math;

import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/comparison_bar_plot_floor.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_states.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_comparison_bar_chart.dart';
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
}

/// Structured payload emitted when the user taps a bar.
class AppComparisonBarPointTapEvent<T> {
  const AppComparisonBarPointTapEvent({
    required this.item,
    required this.index,
    required this.label,
    required this.value,
  });

  final T item;
  final int index;
  final String label;
  final num value;
}

/// Generic vertical bar chart for discrete comparisons between labelled items.
///
/// [valueBuilder] supplies the true metric; optional minimum-height lifts for
/// readability are stored on [AppChartPoint.plottedValue] only for drawing.
///
/// Usage:
/// ```dart
/// AppComparisonBarChart<ReportResultRow>(
///   title: 'Faturamento por vendedor',
///   subtitle: 'Recorte atual.',
///   items: detail.rows,
///   labelBuilder: (row) => row.seller,
///   valueBuilder: (row) => row.revenue,
///   style: AppComparisonBarChartStyle(
///     yAxisFormat: AppBrFormatters.compactCurrencyFormat,
///   ),
/// )
/// ```
///
/// Pass [colorBuilder] to assign a different color to each bar. Pass
/// [title] to wrap the chart inside a shell card automatically.
class AppComparisonBarChart<T> extends StatelessWidget {
  const AppComparisonBarChart({
    required this.items,
    required this.labelBuilder,
    required this.valueBuilder,
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.titleTrailing,
    this.onOpenFullscreen,
    this.openFullscreenTooltip,
    this.openFullscreenSemanticLabel,
    this.belowSubtitle,
    this.colorBuilder,
    this.dataLabelBuilder,
    this.tooltipLabelBuilder,
    this.onPointTap,
    this.onPointTapEvent,
    this.style = const AppComparisonBarChartStyle(),
    this.preset = AppChartPreset.standard,
    this.isLoading = false,
    this.emptyPlaceholder,
    this.plotFloorAccessibilityNotice,
    this.extremeSpreadAccessibilityNotice,
  });

  /// Height the engine will reserve for the chart body when `style.height` is
  /// not set. Useful for callers that render their own staged-mounting
  /// placeholder and need to keep the same vertical footprint between the
  /// placeholder and the eventual real card (avoids layout shift).
  ///
  /// When [styleHeight] is non-null it is returned verbatim — mirrors the
  /// engine resolution (`style.height ?? chartTheme.height`).
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

  /// Data items to plot.
  final List<T> items;

  /// Returns the X-axis label for an item.
  final String Function(T item) labelBuilder;

  /// Returns the numeric Y value for an item.
  final num Function(T item) valueBuilder;

  /// Optional chart title string. When provided (and [titleWidget] is null)
  /// the chart is wrapped in [AppChartShell] with a plain text header.
  final String? title;

  /// Optional rich-content widget used as the chart title header.
  ///
  /// When set, it replaces the plain [Text] rendered from [title] inside
  /// [AppChartShell]. [subtitle], [titleTrailing] and [belowSubtitle] still
  /// apply alongside it. Setting [titleWidget] without [title] is supported —
  /// pass an empty string for [title] or omit it entirely.
  final Widget? titleWidget;

  /// Optional subtitle shown below [title] / [titleWidget] inside [AppChartShell].
  final String? subtitle;

  /// Widget aligned to the trailing edge of the header row.
  final Widget? titleTrailing;

  /// Optional callback that enables fullscreen expansion from the chart header.
  final VoidCallback? onOpenFullscreen;

  /// Optional tooltip for the fullscreen action button.
  final String? openFullscreenTooltip;

  /// Optional semantics label for the fullscreen action button.
  final String? openFullscreenSemanticLabel;

  /// Widget rendered between the subtitle and the chart (e.g. period picker).
  final Widget? belowSubtitle;

  /// Returns an optional per-item bar color. When null the style bar color
  /// (or the theme default) is used uniformly.
  final Color? Function(T item)? colorBuilder;

  /// Returns an optional label rendered above each bar.
  final String? Function(T item, num value)? dataLabelBuilder;

  /// Returns an optional tooltip string for each bar.
  final String? Function(T item, num value)? tooltipLabelBuilder;

  /// Called when the user taps a bar.
  final void Function(T item, int index)? onPointTap;

  /// Called when the user taps a bar with a structured event payload.
  final ValueChanged<AppComparisonBarPointTapEvent<T>>? onPointTapEvent;

  /// Visual overrides applied on top of the [preset]-driven defaults.
  final AppComparisonBarChartStyle style;

  /// Base visual preset (compact / standard / explorable).
  final AppChartPreset preset;

  /// Shows an indeterminate loading indicator at chart height.
  final bool isLoading;

  /// Widget rendered when [items] is empty (and not loading).
  final Widget? emptyPlaceholder;

  /// Shown as a header info tooltip and in chart [Semantics] when any bar uses
  /// a minimum plotted height ([AppChartPoint.plottedValue]).
  final String? plotFloorAccessibilityNotice;

  /// Appended to chart [Semantics] when values span an extreme ratio (e.g.
  /// orders of magnitude); use for screen-reader context about possible unit mix-ups.
  final String? extremeSpreadAccessibilityNotice;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final n = items.length;
    final values = List<num>.generate(n, (i) => valueBuilder(items[i]));
    debugLogSuspiciousComparisonBarSpread(values);

    // X-axis label shaping: optional two-line wrap, else optional single-line
    // truncation. Tooltips still use [tooltipLabelBuilder] with full context.
    String formatXLabel(String raw) {
      if (style.wrapXAxisLabelsInTwoLines) {
        return formatComparisonBarXAxisLabelWrapped(
          raw,
          maxCharsPerLine: style.wrapXAxisCharsPerLine,
          maxLines: style.wrapXAxisMaxLines,
        );
      }
      final maxChars = style.xLabelMaxChars;
      if (maxChars == null) {
        return raw;
      }
      return formatComparisonBarXAxisLabelCollapsed(raw, maxChars: maxChars);
    }

    final rawPoints = <AppChartPoint>[];
    List<Color?>? pointColorsOut;
    List<String?>? dataLabelsOut;
    List<String?>? tooltipLabelsOut;
    if (colorBuilder != null) {
      pointColorsOut = <Color?>[];
    }
    if (style.showDataLabels) {
      dataLabelsOut = <String?>[];
    }
    if (tooltipLabelBuilder != null) {
      tooltipLabelsOut = <String?>[];
    }
    for (var i = 0; i < n; i++) {
      final item = items[i];
      final v = values[i];
      rawPoints.add(
        AppChartPoint(
          label: formatXLabel(labelBuilder(item)),
          value: v,
        ),
      );
      pointColorsOut?.add(colorBuilder!(item));
      dataLabelsOut?.add(
        dataLabelBuilder?.call(item, v) ?? v.toString(),
      );
      tooltipLabelsOut?.add(
        _truncateComparisonTooltipLabel(
          tooltipLabelBuilder!.call(item, v),
          style.tooltipLabelMaxChars,
        ),
      );
    }
    final points = applyComparisonBarPlotHeightFloor(
      rawPoints,
      style.minPlottedValueShareOfMax,
      strictLinearBarHeights: style.strictLinearBarHeights,
    );
    final hasPlotFloor = points.any((p) => p.plottedValue != null);
    final hasExtremeSpread = comparisonBarValuesHaveExtremeSpread(values);

    final semanticsParts = <String>[];
    final floorNotice = plotFloorAccessibilityNotice?.trim();
    if (hasPlotFloor && floorNotice != null && floorNotice.isNotEmpty) {
      semanticsParts.add(floorNotice);
    }
    final spreadNotice = extremeSpreadAccessibilityNotice?.trim();
    if (hasExtremeSpread && spreadNotice != null && spreadNotice.isNotEmpty) {
      semanticsParts.add(spreadNotice);
    }
    final semanticsCoordinatorLabel = semanticsParts.isEmpty
        ? null
        : semanticsParts.join(' ');

    Widget? floorNoticeTrailing;
    if (hasPlotFloor && floorNotice != null && floorNotice.isNotEmpty) {
      floorNoticeTrailing = Tooltip(
        message: floorNotice,
        child: Icon(
          Icons.info_outline,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    final mergedTitleTrailing = _mergeComparisonTitleTrailing(
      titleTrailing,
      floorNoticeTrailing,
    );

    final resolvedLoadingLabel =
        style.loadingLabel ?? l10n?.chartComparisonLoadingDefault;
    final resolvedEmptyMessage =
        style.emptyMessage ?? l10n?.chartComparisonEmptyDefault;

    void handlePointTap(int index) {
      if (index < 0 || index >= items.length || index >= points.length) {
        return;
      }

      final item = items[index];
      final event = AppComparisonBarPointTapEvent<T>(
        item: item,
        index: index,
        label: points[index].label,
        value: points[index].value,
      );
      onPointTap?.call(item, index);
      onPointTapEvent?.call(event);
    }

    Widget innerChart = SyncfusionComparisonBarChart(
      points: points,
      preset: preset,
      style: style,
      pointColors: pointColorsOut,
      dataLabels: dataLabelsOut,
      tooltipLabels: tooltipLabelsOut,
      onPointTap: (onPointTap == null && onPointTapEvent == null)
          ? null
          : handlePointTap,
      isLoading: isLoading,
      emptyPlaceholder: emptyPlaceholder,
      resolvedLoadingLabel: resolvedLoadingLabel,
      resolvedEmptyMessage: resolvedEmptyMessage,
    );

    if (semanticsCoordinatorLabel != null &&
        semanticsCoordinatorLabel.isNotEmpty) {
      innerChart = Semantics(
        label: semanticsCoordinatorLabel,
        excludeSemantics: true,
        child: innerChart,
      );
    }

    if (title == null && titleWidget == null) {
      return innerChart;
    }

    return AppChartShell(
      title: title ?? '',
      titleWidget: titleWidget,
      subtitle: subtitle,
      titleTrailing: mergedTitleTrailing,
      onOpenFullscreen: onOpenFullscreen,
      openFullscreenTooltip: openFullscreenTooltip,
      openFullscreenSemanticLabel: openFullscreenSemanticLabel,
      belowSubtitle: belowSubtitle,
      child: innerChart,
    );
  }
}

Widget? _mergeComparisonTitleTrailing(Widget? primary, Widget? secondary) {
  if (primary == null) {
    return secondary;
  }
  if (secondary == null) {
    return primary;
  }
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      primary,
      const SizedBox(width: 8),
      secondary,
    ],
  );
}

String? _truncateComparisonTooltipLabel(String? raw, int? maxChars) {
  if (raw == null) {
    return null;
  }
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return raw;
  }
  final max = maxChars;
  if (max == null || trimmed.length <= max) {
    return raw;
  }
  final cap = math.max(4, max);
  return '${trimmed.substring(0, cap)}\u2026';
}

/// Single-line category label: trims and collapses with U+2026 when longer
/// than [maxChars]. Tooltips should keep the full raw string elsewhere.
String formatComparisonBarXAxisLabelCollapsed(
  String raw, {
  required int maxChars,
}) {
  final s = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (s.isEmpty) {
    return s;
  }
  final limit = math.max(4, maxChars);
  if (s.length <= limit) {
    return s;
  }
  return '${s.substring(0, limit)}\u2026';
}

/// Formats a category label for [AppComparisonBarChart] with word-aware line
/// breaks (`\n`). [maxLines] caps height; overflow on the last line uses U+2026.
///
/// Syncfusion renders `\n` in category axis labels as line breaks.
///
/// When [raw] contains explicit newline characters, each line is truncated
/// independently (no word-wrap merge across lines) so callers can stack
/// structured labels (e.g. date + weekday) without collapsing them.
String formatComparisonBarXAxisLabelWrapped(
  String raw, {
  int maxCharsPerLine = 14,
  int maxLines = 2,
}) {
  final trimmedOuter = raw.trim();
  if (trimmedOuter.contains('\n')) {
    final limit = math.max(4, maxCharsPerLine);
    final capLines = math.max(1, maxLines);
    final segments = trimmedOuter
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    final out = <String>[];
    for (var i = 0; i < segments.length && i < capLines; i++) {
      var seg = segments[i];
      if (seg.length > limit) {
        seg = '${seg.substring(0, limit)}\u2026';
      }
      out.add(seg);
    }
    return out.join('\n');
  }

  final s = trimmedOuter.replaceAll(RegExp(r'\s+'), ' ');
  if (s.isEmpty) {
    return s;
  }
  final limit = math.max(4, maxCharsPerLine);
  final capLines = math.max(1, maxLines);

  final lines = <String>[];
  var remainder = s;

  while (remainder.isNotEmpty && lines.length < capLines) {
    if (remainder.length <= limit) {
      lines.add(remainder);
      remainder = '';
      break;
    }

    var breakIdx = -1;
    final scanEnd = math.min(limit, remainder.length);
    for (var i = scanEnd - 1; i > 0; i--) {
      if (remainder[i] == ' ') {
        breakIdx = i;
        break;
      }
    }

    late final String line;
    if (breakIdx > 0) {
      line = remainder.substring(0, breakIdx).trimRight();
      remainder = remainder.substring(breakIdx + 1).trimLeft();
    } else {
      line = remainder.substring(0, limit);
      remainder = remainder.substring(limit).trimLeft();
    }

    if (line.isEmpty) {
      lines.add(remainder.substring(0, limit));
      remainder = remainder.length > limit
          ? remainder.substring(limit).trimLeft()
          : '';
      continue;
    }
    lines.add(line);
  }

  if (remainder.isEmpty) {
    return lines.join('\n');
  }

  final lastIdx = lines.length - 1;
  final last = lines[lastIdx];
  final candidate = '$last $remainder'.trim();
  if (candidate.length <= limit) {
    lines[lastIdx] = candidate;
    return lines.join('\n');
  }

  final cap = limit - 1;
  if (last.length >= cap) {
    lines[lastIdx] = '${last.substring(0, cap)}\u2026';
    return lines.join('\n');
  }
  final room = limit - last.length - 1;
  final take = math.max(0, math.min(room, remainder.length));
  final frag = remainder.substring(0, take).trimRight();
  lines[lastIdx] = frag.isEmpty
      ? '${last.substring(0, math.min(cap, last.length))}\u2026'
      : '$last $frag\u2026';
  return lines.join('\n');
}

/// Prefer [formatComparisonBarXAxisLabelWrapped] with `maxLines: 2`.
String formatComparisonBarXAxisLabelTwoLines(
  String raw, {
  int maxCharsPerLine = 14,
}) {
  return formatComparisonBarXAxisLabelWrapped(
    raw,
    maxCharsPerLine: maxCharsPerLine,
  );
}
