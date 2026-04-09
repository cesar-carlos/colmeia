import 'dart:math' as math;

import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_comparison_bar_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Visual customization for [AppComparisonBarChart].
///
/// All properties are optional. Omitted values fall back to the preset-driven
/// defaults resolved by the internal chart theme helper.
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
    this.yAxisTitle,
    this.xAxisTitle,
    this.showTooltip = true,
    this.showYGridLines = true,
    this.showDataLabels = false,
    this.dataLabelTextStyle,
    this.dataLabelAlignment = ChartDataLabelAlignment.outer,
    this.autoRotateXLabels = true,
    this.xLabelMaxChars,
    this.wrapXAxisLabelsInTwoLines = false,
    this.wrapXAxisCharsPerLine = 14,
    this.loadingLabel,
    this.emptyMessage,
    this.enableAutoScroll = true,
    this.minBarWidth,
    this.showScrollFade = true,
  });

  /// Solid color applied to all bars when [AppComparisonBarChart.colorBuilder]
  /// is null. Falls back to the theme's chart primary color when null.
  final Color? barColor;

  /// Corner rounding for each bar.
  final BorderRadius barBorderRadius;

  /// Fixed chart height. Falls back to the preset-driven token when null.
  final double? height;

  /// Relative width of each bar as a fraction of the bar slot, between
  /// `0.0` (invisible) and `1.0` (fills the slot). Defaults to `0.7`.
  ///
  /// See also [barGap] for an absolute pixel alternative that is often more
  /// intuitive when you know the visual result you want.
  final double? barWidth;

  /// Relative spacing between adjacent bars as a fraction of the bar slot,
  /// between `0.0` (bars touch) and `1.0` (bars invisible). Defaults to `0.2`.
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
  final EdgeInsets? chartPadding;

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

  /// When `true`, X-axis labels are split onto up to two horizontal lines using
  /// `\n` between lines, and overflow on the second line ends with an ellipsis
  /// (`…`). This avoids tilted labels; pair with `autoRotateXLabels: false`.
  ///
  /// Line length is guided by [wrapXAxisCharsPerLine]. Tooltips are unchanged.
  final bool wrapXAxisLabelsInTwoLines;

  /// Soft maximum characters per line when [wrapXAxisLabelsInTwoLines] is
  /// `true`. Defaults to `14`.
  final int wrapXAxisCharsPerLine;

  /// Override label for the loading indicator.
  ///
  /// When `null` a built-in default is used.
  final String? loadingLabel;

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
  /// When `null` the engine falls back to a built-in default (72 px), which
  /// keeps X-axis labels readable at standard font sizes.
  final double? minBarWidth;

  /// Whether to show a subtle fade gradient on the trailing edge of the chart
  /// when horizontal scrolling is active. Defaults to `true`.
  final bool showScrollFade;
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
  });

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

  @override
  Widget build(BuildContext context) {
    final values = items.map(valueBuilder).toList(growable: false);

    // X-axis label shaping: optional two-line wrap, else optional single-line
    // truncation. Tooltips still use [tooltipLabelBuilder] with full context.
    String formatXLabel(String raw) {
      if (style.wrapXAxisLabelsInTwoLines) {
        return formatComparisonBarXAxisLabelTwoLines(
          raw,
          maxCharsPerLine: style.wrapXAxisCharsPerLine,
        );
      }
      final maxChars = style.xLabelMaxChars;
      if (maxChars == null || raw.length <= maxChars) return raw;
      return '${raw.substring(0, maxChars)}\u2026';
    }

    final points = items.indexed
        .map(
          (entry) => AppChartPoint(
            label: formatXLabel(labelBuilder(entry.$2)),
            value: values[entry.$1],
          ),
        )
        .toList(growable: false);

    final pointColors = colorBuilder != null
        ? items.map(colorBuilder!).toList(growable: false)
        : null;
    final dataLabels = style.showDataLabels
        ? items.indexed
              .map(
                (entry) =>
                    dataLabelBuilder?.call(entry.$2, values[entry.$1]) ??
                    values[entry.$1].toString(),
              )
              .toList(growable: false)
        : null;
    final tooltipLabels = tooltipLabelBuilder != null
        ? items.indexed
              .map(
                (entry) =>
                    tooltipLabelBuilder!.call(entry.$2, values[entry.$1]),
              )
              .toList(growable: false)
        : null;

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

    final innerChart = SyncfusionComparisonBarChart(
      points: points,
      preset: preset,
      style: style,
      pointColors: pointColors,
      dataLabels: dataLabels,
      tooltipLabels: tooltipLabels,
      onPointTap: (onPointTap == null && onPointTapEvent == null)
          ? null
          : handlePointTap,
      isLoading: isLoading,
      emptyPlaceholder: emptyPlaceholder,
    );

    if (title == null && titleWidget == null) {
      return innerChart;
    }

    return AppChartShell(
      title: title ?? '',
      titleWidget: titleWidget,
      subtitle: subtitle,
      titleTrailing: titleTrailing,
      belowSubtitle: belowSubtitle,
      child: innerChart,
    );
  }
}

/// Formats a category label for [AppComparisonBarChart] using at most two
/// horizontal lines (`\n` separator). If the remainder still does not fit on
/// the second line, it is truncated and an ellipsis (U+2026) is appended.
///
/// Syncfusion renders `\n` in category axis labels as line breaks.
String formatComparisonBarXAxisLabelTwoLines(
  String raw, {
  int maxCharsPerLine = 14,
}) {
  final s = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (s.isEmpty) {
    return s;
  }
  final limit = math.max(4, maxCharsPerLine);

  if (s.length <= limit) {
    return s;
  }

  var breakIdx = -1;
  final scanEnd = math.min(limit, s.length);
  for (var i = scanEnd - 1; i > 0; i--) {
    if (s[i] == ' ') {
      breakIdx = i;
      break;
    }
  }

  late final String line1;
  late final String rest;
  if (breakIdx > 0) {
    line1 = s.substring(0, breakIdx).trimRight();
    rest = s.substring(breakIdx + 1).trimLeft();
  } else {
    line1 = s.substring(0, limit);
    rest = s.substring(limit);
  }

  if (rest.isEmpty) {
    return line1;
  }

  if (rest.length <= limit) {
    return '$line1\n$rest';
  }

  final cap = limit - 1;
  final truncated = rest.substring(0, cap).trimRight();
  return '$line1\n$truncated\u2026';
}
