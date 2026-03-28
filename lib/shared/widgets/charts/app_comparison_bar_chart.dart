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
    this.dataLabelAlignment = ChartDataLabelAlignment.top,
  });

  /// Solid color applied to all bars when [AppComparisonBarChart.colorBuilder]
  /// is null. Falls back to the theme's chart primary color when null.
  final Color? barColor;

  /// Corner rounding for each bar.
  final BorderRadius barBorderRadius;

  /// Fixed chart height. Falls back to the preset-driven token when null.
  final double? height;

  /// Relative width of each bar, usually between `0.0` and `1.0`.
  final double? barWidth;

  /// Space between bars, usually between `0.0` and `1.0`.
  final double? spacing;

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
  final ChartDataLabelAlignment dataLabelAlignment;
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
    this.subtitle,
    this.titleTrailing,
    this.belowSubtitle,
    this.colorBuilder,
    this.dataLabelBuilder,
    this.tooltipLabelBuilder,
    this.onPointTap,
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

  /// Optional chart title. When provided the chart is wrapped in
  /// [AppChartShell].
  final String? title;

  /// Optional subtitle shown below [title] inside [AppChartShell].
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
    final points = items.indexed
        .map(
          (entry) => AppChartPoint(
            label: labelBuilder(entry.$2),
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

    final innerChart = SyncfusionComparisonBarChart(
      points: points,
      preset: preset,
      style: style,
      pointColors: pointColors,
      dataLabels: dataLabels,
      tooltipLabels: tooltipLabels,
      onPointTap: onPointTap == null
          ? null
          : (index) => onPointTap!(items[index], index),
      isLoading: isLoading,
      emptyPlaceholder: emptyPlaceholder,
    );

    if (title == null) {
      return innerChart;
    }

    return AppChartShell(
      title: title!,
      subtitle: subtitle,
      titleTrailing: titleTrailing,
      belowSubtitle: belowSubtitle,
      child: innerChart,
    );
  }
}
