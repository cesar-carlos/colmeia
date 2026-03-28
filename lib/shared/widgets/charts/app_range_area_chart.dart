import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_range_area_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppRangeAreaPoint {
  const AppRangeAreaPoint({
    required this.label,
    required this.low,
    required this.high,
  });

  final String label;
  final num low;
  final num high;
}

class AppRangeAreaChartStyle {
  const AppRangeAreaChartStyle({
    this.height,
    this.chartPadding,
    this.yAxisFormat,
    this.showTooltip = true,
    this.showYGridLines = true,
    this.showMarkers = false,
    this.showTrackball = false,
    this.fillColor,
    this.borderColor,
    this.markerSize,
    this.lineWidth,
    this.animationDuration,
  });

  final double? height;
  final EdgeInsets? chartPadding;
  final NumberFormat? yAxisFormat;
  final bool showTooltip;
  final bool showYGridLines;
  final bool showMarkers;
  final bool showTrackball;
  final Color? fillColor;
  final Color? borderColor;
  final double? markerSize;
  final double? lineWidth;
  final Duration? animationDuration;
}

class AppRangeAreaChart extends StatelessWidget {
  const AppRangeAreaChart({
    required this.points,
    super.key,
    this.title,
    this.subtitle,
    this.titleTrailing,
    this.belowSubtitle,
    this.onPointTap,
    this.style = const AppRangeAreaChartStyle(),
    this.preset = AppChartPreset.standard,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<AppRangeAreaPoint> points;
  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;
  final void Function(AppRangeAreaPoint point, int index)? onPointTap;
  final AppRangeAreaChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final innerChart = SyncfusionRangeAreaChart(
      points: points,
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
