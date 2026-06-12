import 'package:colmeia/shared/widgets/charts/app_horizontal_progress_chart.dart' show AppHorizontalProgressChart;
import 'package:colmeia/shared/widgets/widgets.dart' show AppHorizontalProgressChart;
import 'package:flutter/material.dart';

class AppHorizontalProgressChartStyle {
  const AppHorizontalProgressChartStyle({
    this.barColor,
    this.trackColor,
    this.valueColor,
    this.barGradient,
    this.rowSpacing,
    this.barHeight = 8,
    this.barRadius,
    this.rowPadding,
    this.titleTextStyle,
    this.labelTextStyle,
    this.valueTextStyle,
    this.titleTextAlign,
    this.labelTextAlign,
    this.valueTextAlign,
    this.titleBottomSpacing,
    this.leadingSpacing,
    this.dividerPadding,
  });

  final Color? barColor;
  final Color? trackColor;
  final Color? valueColor;
  final Gradient? barGradient;
  final double? rowSpacing;
  final double barHeight;
  final BorderRadiusGeometry? barRadius;
  final EdgeInsetsGeometry? rowPadding;
  final TextStyle? titleTextStyle;
  final TextStyle? labelTextStyle;
  final TextStyle? valueTextStyle;
  final TextAlign? titleTextAlign;
  final TextAlign? labelTextAlign;
  final TextAlign? valueTextAlign;

  /// Gap between the title block (string [AppHorizontalProgressChart.title] or
  /// custom widget [AppHorizontalProgressChart.titleWidget]) and the first row.
  ///
  /// When null, [AppHorizontalProgressChart] uses the active theme's medium
  /// gap token (`gapMd`).
  final double? titleBottomSpacing;
  final double? leadingSpacing;
  final EdgeInsetsGeometry? dividerPadding;
}
