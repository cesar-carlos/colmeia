import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_waterfall_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppWaterfallChartStyle {
  const AppWaterfallChartStyle({
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
    this.showDataLabels = false,
    this.axisLabelTextStyle,
    this.dataLabelTextStyle,
    this.positiveColor,
    this.negativeColor,
    this.intermediateSumColor,
    this.totalSumColor,
    this.connectorLineColor,
  });

  final double? height;
  final double? barWidth;
  final double? spacing;
  final EdgeInsets? chartPadding;
  final Duration? animationDuration;
  final NumberFormat? yAxisFormat;
  final bool showXAxis;
  final bool showYAxis;
  final bool showYGridLines;
  final bool showTooltip;
  final bool showDataLabels;
  final TextStyle? axisLabelTextStyle;
  final TextStyle? dataLabelTextStyle;
  final Color? positiveColor;
  final Color? negativeColor;
  final Color? intermediateSumColor;
  final Color? totalSumColor;
  final Color? connectorLineColor;
}

class AppWaterfallChart<T> extends StatelessWidget {
  const AppWaterfallChart({
    required this.items,
    required this.labelBuilder,
    required this.valueBuilder,
    super.key,
    this.title,
    this.subtitle,
    this.titleTrailing,
    this.belowSubtitle,
    this.isIntermediateSum,
    this.isTotalSum,
    this.dataLabelBuilder,
    this.tooltipLabelBuilder,
    this.onPointTap,
    this.style = const AppWaterfallChartStyle(),
    this.preset = AppChartPreset.standard,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<T> items;
  final String Function(T item) labelBuilder;
  final num Function(T item) valueBuilder;
  final bool Function(T item)? isIntermediateSum;
  final bool Function(T item)? isTotalSum;
  final String? Function(T item, num value)? dataLabelBuilder;
  final String? Function(T item, num value)? tooltipLabelBuilder;
  final void Function(T item, int index)? onPointTap;

  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;

  final AppWaterfallChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final values = items.map(valueBuilder).toList(growable: false);
    final dataLabels = style.showDataLabels
        ? items.indexed
              .map(
                (entry) =>
                    dataLabelBuilder?.call(entry.$2, values[entry.$1]) ??
                    values[entry.$1].toString(),
              )
              .toList(growable: false)
        : null;
    final tooltipLabels = tooltipLabelBuilder == null
        ? null
        : items.indexed
              .map(
                (entry) =>
                    tooltipLabelBuilder!.call(entry.$2, values[entry.$1]),
              )
              .toList(growable: false);

    final innerChart = SyncfusionWaterfallChart<T>(
      items: items,
      labelBuilder: labelBuilder,
      valueBuilder: valueBuilder,
      isIntermediateSum: isIntermediateSum,
      isTotalSum: isTotalSum,
      dataLabels: dataLabels,
      tooltipLabels: tooltipLabels,
      onPointTap: onPointTap == null
          ? null
          : (index) => onPointTap!(items[index], index),
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
