import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/custom_bullet_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppBulletRange {
  const AppBulletRange({
    required this.end,
    this.color,
  });

  final num end;
  final Color? color;
}

class AppBulletChartStyle {
  const AppBulletChartStyle({
    this.height,
    this.rowSpacing,
    this.barHeight,
    this.labelWidth,
    this.chartPadding,
    this.labelTextStyle,
    this.valueTextStyle,
    this.captionTextStyle,
    this.numberFormat,
    this.actualBarColor,
    this.targetMarkerColor,
    this.backgroundRadius,
    this.targetMarkerWidth,
    this.showValueLabels = true,
  });

  final double? height;
  final double? rowSpacing;
  final double? barHeight;
  final double? labelWidth;
  final EdgeInsets? chartPadding;
  final TextStyle? labelTextStyle;
  final TextStyle? valueTextStyle;
  final TextStyle? captionTextStyle;
  final NumberFormat? numberFormat;
  final Color? actualBarColor;
  final Color? targetMarkerColor;
  final BorderRadius? backgroundRadius;
  final double? targetMarkerWidth;
  final bool showValueLabels;
}

class AppBulletChart<T> extends StatelessWidget {
  const AppBulletChart({
    required this.items,
    required this.labelBuilder,
    required this.valueBuilder,
    required this.targetValueBuilder,
    required this.rangesBuilder,
    super.key,
    this.title,
    this.subtitle,
    this.titleTrailing,
    this.belowSubtitle,
    this.maxValueBuilder,
    this.onPointTap,
    this.style = const AppBulletChartStyle(),
    this.preset = AppChartPreset.standard,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<T> items;
  final String Function(T item) labelBuilder;
  final num Function(T item) valueBuilder;
  final num Function(T item) targetValueBuilder;
  final List<AppBulletRange> Function(T item) rangesBuilder;
  final num Function(T item)? maxValueBuilder;
  final void Function(T item, int index)? onPointTap;

  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;

  final AppBulletChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final innerChart = CustomBulletChart<T>(
      items: items,
      labelBuilder: labelBuilder,
      valueBuilder: valueBuilder,
      targetValueBuilder: targetValueBuilder,
      rangesBuilder: rangesBuilder,
      maxValueBuilder: maxValueBuilder,
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
