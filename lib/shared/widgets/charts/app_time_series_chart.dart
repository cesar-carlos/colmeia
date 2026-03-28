import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_time_series_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppTimeSeriesChartStyle {
  const AppTimeSeriesChartStyle({
    this.height,
    this.yAxisFormat,
    this.lineWidth,
    this.showTooltip = true,
    this.showYGridLines = true,
    this.chartPadding,
  });

  final double? height;
  final NumberFormat? yAxisFormat;
  final double? lineWidth;
  final bool showTooltip;
  final bool showYGridLines;
  final EdgeInsets? chartPadding;
}

class AppTimeSeriesChart extends StatelessWidget {
  const AppTimeSeriesChart({
    required this.points,
    super.key,
    this.title,
    this.subtitle,
    this.titleTrailing,
    this.belowSubtitle,
    this.preset = AppChartPreset.explorable,
    this.style = const AppTimeSeriesChartStyle(),
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<AppChartPoint> points;
  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;
  final AppChartPreset preset;
  final AppTimeSeriesChartStyle style;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final innerChart = SyncfusionTimeSeriesChart(
      points: points,
      preset: preset,
      style: style,
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
