import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_scatter_bubble_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppScatterBubbleChartStyle {
  const AppScatterBubbleChartStyle({
    this.height,
    this.chartPadding,
    this.xAxisFormat,
    this.yAxisFormat,
    this.xAxisTitle,
    this.yAxisTitle,
    this.showTooltip = true,
    this.showLegend = false,
    this.showDataLabels = false,
    this.showGridLines = true,
    this.axisLabelTextStyle,
    this.dataLabelTextStyle,
    this.pointColor,
    this.bubbleOpacity,
    this.markerSize,
    this.minX,
    this.maxX,
    this.minY,
    this.maxY,
  });

  final double? height;
  final EdgeInsets? chartPadding;
  final NumberFormat? xAxisFormat;
  final NumberFormat? yAxisFormat;
  final String? xAxisTitle;
  final String? yAxisTitle;
  final bool showTooltip;
  final bool showLegend;
  final bool showDataLabels;
  final bool showGridLines;
  final TextStyle? axisLabelTextStyle;
  final TextStyle? dataLabelTextStyle;
  final Color? pointColor;
  final double? bubbleOpacity;
  final double? markerSize;
  final num? minX;
  final num? maxX;
  final num? minY;
  final num? maxY;
}

class AppScatterBubbleChart<T> extends StatelessWidget {
  const AppScatterBubbleChart({
    required this.items,
    required this.xValueBuilder,
    required this.yValueBuilder,
    super.key,
    this.title,
    this.subtitle,
    this.titleTrailing,
    this.belowSubtitle,
    this.labelBuilder,
    this.bubbleSizeBuilder,
    this.colorBuilder,
    this.tooltipLabelBuilder,
    this.onPointTap,
    this.style = const AppScatterBubbleChartStyle(),
    this.preset = AppChartPreset.standard,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<T> items;
  final num Function(T item) xValueBuilder;
  final num Function(T item) yValueBuilder;
  final String Function(T item)? labelBuilder;
  final num Function(T item)? bubbleSizeBuilder;
  final Color? Function(T item)? colorBuilder;
  final String? Function(T item)? tooltipLabelBuilder;
  final void Function(T item, int index)? onPointTap;

  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;
  final AppScatterBubbleChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final innerChart = SyncfusionScatterBubbleChart<T>(
      items: items,
      xValueBuilder: xValueBuilder,
      yValueBuilder: yValueBuilder,
      labelBuilder: labelBuilder,
      bubbleSizeBuilder: bubbleSizeBuilder,
      colorBuilder: colorBuilder,
      tooltipLabelBuilder: tooltipLabelBuilder,
      onPointTap: onPointTap,
      style: style,
      preset: preset,
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
