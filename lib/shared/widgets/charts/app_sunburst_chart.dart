import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/custom_sunburst_chart.dart';
import 'package:flutter/material.dart';

class AppSunburstNode<T> {
  const AppSunburstNode({
    required this.id,
    required this.item,
    required this.label,
    required this.value,
    required this.totalValue,
    required this.depth,
    required this.childrenCount,
    required this.color,
    this.parentId,
  });

  final String id;
  final T item;
  final String label;
  final double value;
  final double totalValue;
  final int depth;
  final int childrenCount;
  final Color color;
  final String? parentId;
}

class AppSunburstChartStyle {
  const AppSunburstChartStyle({
    this.height,
    this.chartPadding,
    this.showLabels = true,
    this.showLegend = true,
    this.showCenterSummary = true,
    this.innerRadiusFactor = 0.18,
    this.ringGap = 6,
    this.segmentSpacing = 2,
    this.minLabelSweepAngle = 0.45,
    this.labelTextStyle,
    this.legendTextStyle,
    this.centerValueTextStyle,
    this.centerLabelTextStyle,
    this.borderColor,
    this.borderWidth = 1,
  });

  final double? height;
  final EdgeInsets? chartPadding;
  final bool showLabels;
  final bool showLegend;
  final bool showCenterSummary;
  final double innerRadiusFactor;
  final double ringGap;
  final double segmentSpacing;
  final double minLabelSweepAngle;
  final TextStyle? labelTextStyle;
  final TextStyle? legendTextStyle;
  final TextStyle? centerValueTextStyle;
  final TextStyle? centerLabelTextStyle;
  final Color? borderColor;
  final double borderWidth;
}

class AppSunburstChart<T> extends StatelessWidget {
  const AppSunburstChart({
    required this.items,
    required this.idBuilder,
    required this.labelBuilder,
    required this.valueBuilder,
    required this.parentIdBuilder,
    super.key,
    this.title,
    this.subtitle,
    this.titleTrailing,
    this.belowSubtitle,
    this.colorBuilder,
    this.centerLabel,
    this.onSegmentTap,
    this.style = const AppSunburstChartStyle(),
    this.preset = AppChartPreset.standard,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<T> items;
  final String Function(T item) idBuilder;
  final String Function(T item) labelBuilder;
  final num Function(T item) valueBuilder;
  final String? Function(T item) parentIdBuilder;
  final Color? Function(T item)? colorBuilder;
  final String? centerLabel;
  final void Function(AppSunburstNode<T> node)? onSegmentTap;

  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;
  final AppSunburstChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final innerChart = CustomSunburstChart<T>(
      items: items,
      idBuilder: idBuilder,
      labelBuilder: labelBuilder,
      valueBuilder: valueBuilder,
      parentIdBuilder: parentIdBuilder,
      colorBuilder: colorBuilder,
      centerLabel: centerLabel,
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
