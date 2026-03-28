import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_pyramid_chart.dart';
import 'package:flutter/material.dart';

class AppPyramidChartStyle {
  const AppPyramidChartStyle({
    this.height,
    this.chartPadding,
    this.showTooltip = true,
    this.showLegend = false,
    this.showDataLabels = true,
    this.gapRatio = 0.04,
    this.dataLabelTextStyle,
  });

  final double? height;
  final EdgeInsets? chartPadding;
  final bool showTooltip;
  final bool showLegend;
  final bool showDataLabels;
  final double gapRatio;
  final TextStyle? dataLabelTextStyle;
}

class AppPyramidChart<T> extends StatelessWidget {
  const AppPyramidChart({
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
    this.onSegmentTap,
    this.style = const AppPyramidChartStyle(),
    this.preset = AppChartPreset.standard,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<T> items;
  final String Function(T item) labelBuilder;
  final num Function(T item) valueBuilder;
  final Color? Function(T item)? colorBuilder;
  final String? Function(T item, num value)? dataLabelBuilder;
  final String? Function(T item, num value)? tooltipLabelBuilder;
  final void Function(T item, int index)? onSegmentTap;

  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;
  final AppPyramidChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final innerChart = SyncfusionPyramidChart<T>(
      items: items,
      labelBuilder: labelBuilder,
      valueBuilder: valueBuilder,
      colorBuilder: colorBuilder,
      dataLabelBuilder: dataLabelBuilder,
      tooltipLabelBuilder: tooltipLabelBuilder,
      onSegmentTap: onSegmentTap,
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
