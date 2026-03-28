import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_stacked_bar_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppStackedBarChartStyle {
  const AppStackedBarChartStyle({
    this.height,
    this.barWidth,
    this.spacing,
    this.chartPadding,
    this.animationDuration,
    this.yAxisFormat,
    this.showXAxis = true,
    this.showYAxis = true,
    this.showYGridLines = true,
    this.showTooltip = true,
    this.showLegend = true,
    this.showDataLabels = false,
    this.axisLabelTextStyle,
    this.legendTextStyle,
    this.dataLabelTextStyle,
    this.isPercentStack = false,
    this.orientation = Axis.vertical,
  });

  final double? height;
  final double? barWidth;
  final double? spacing;
  final EdgeInsets? chartPadding;
  final Duration? animationDuration;

  /// [NumberFormat] applied to the value axis tick labels.
  final NumberFormat? yAxisFormat;

  final bool showXAxis;
  final bool showYAxis;
  final bool showYGridLines;
  final bool showTooltip;
  final bool showLegend;
  final bool showDataLabels;

  final TextStyle? axisLabelTextStyle;
  final TextStyle? legendTextStyle;
  final TextStyle? dataLabelTextStyle;

  /// When true, stacks are normalized to 100%.
  final bool isPercentStack;

  /// [Axis.vertical] renders column bars (default).
  /// [Axis.horizontal] renders horizontal bars — useful for long group labels.
  final Axis orientation;
}

/// A series entry for [AppStackedBarChart].
///
/// Each series maps a group item `G` to a numeric value. Pass [color] to
/// override the palette-driven default.
class AppStackedBarSeries<G> {
  const AppStackedBarSeries({
    required this.label,
    required this.valueBuilder,
    this.color,
  });

  /// Legend label for this series.
  final String label;

  /// Returns the numeric value of this series for a given group item.
  final num Function(G group) valueBuilder;

  /// Optional color override. Falls back to the chart theme palette.
  final Color? color;
}

/// Stacked vertical bar chart for comparing composition across groups.
///
/// Usage:
/// ```dart
/// AppStackedBarChart<_Month>(
///   title: 'Vendas por canal',
///   groups: _months,
///   groupLabelBuilder: (m) => m.label,
///   series: [
///     AppStackedBarSeries(label: 'Loja', valueBuilder: (m) => m.store),
///     AppStackedBarSeries(label: 'App', valueBuilder: (m) => m.app),
///   ],
/// )
/// ```
///
/// Set `style.isPercentStack` to `true` for 100% stacked bars.
class AppStackedBarChart<G> extends StatelessWidget {
  const AppStackedBarChart({
    required this.groups,
    required this.groupLabelBuilder,
    required this.series,
    super.key,
    this.title,
    this.subtitle,
    this.titleTrailing,
    this.belowSubtitle,
    this.onGroupTap,
    this.style = const AppStackedBarChartStyle(),
    this.preset = AppChartPreset.standard,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<G> groups;
  final String Function(G group) groupLabelBuilder;
  final List<AppStackedBarSeries<G>> series;

  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;

  /// Called when the user taps a group bar segment.
  final void Function(G group, int index)? onGroupTap;

  final AppStackedBarChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final innerChart = SyncfusionStackedBarChart<G>(
      groups: groups,
      groupLabelBuilder: groupLabelBuilder,
      series: series,
      style: style,
      preset: preset,
      onGroupTap: onGroupTap,
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
