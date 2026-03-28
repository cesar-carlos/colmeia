import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_step_line_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppStepLineChartStyle {
  const AppStepLineChartStyle({
    this.height,
    this.lineWidth,
    this.yAxisFormat,
    this.chartPadding,
    this.showTooltip = true,
    this.showLegend = true,
    this.showYGridLines = true,
    this.showMarkers = false,
    this.showTrackball = false,
    this.showDataLabels = false,
    this.markerSize,
    this.animationDuration,
  });

  final double? height;
  final double? lineWidth;
  final NumberFormat? yAxisFormat;
  final EdgeInsets? chartPadding;
  final bool showTooltip;
  final bool showLegend;
  final bool showYGridLines;
  final bool showMarkers;
  final bool showTrackball;
  final bool showDataLabels;
  final double? markerSize;
  final Duration? animationDuration;
}

class AppStepLineEntry {
  const AppStepLineEntry({
    required this.label,
    required this.points,
    this.color,
  });

  final String label;
  final List<AppChartPoint> points;
  final Color? color;
}

class AppStepLineChart extends StatelessWidget {
  const AppStepLineChart({
    super.key,
    this.points = const <AppChartPoint>[],
    this.entries,
    this.title,
    this.subtitle,
    this.titleTrailing,
    this.belowSubtitle,
    this.onPointTap,
    this.style = const AppStepLineChartStyle(),
    this.preset = AppChartPreset.explorable,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<AppChartPoint> points;
  final List<AppStepLineEntry>? entries;
  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;
  final void Function(
    AppStepLineEntry entry,
    AppChartPoint point,
    int pointIndex,
    int seriesIndex,
  )?
  onPointTap;
  final AppStepLineChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final resolvedEntries =
        entries ??
        <AppStepLineEntry>[
          AppStepLineEntry(label: '', points: points),
        ];

    final innerChart = SyncfusionStepLineChart(
      entries: resolvedEntries,
      isMultiSeries: entries != null,
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
