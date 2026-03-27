import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_time_series_chart.dart';
import 'package:flutter/material.dart';

class AppTimeSeriesChart extends StatelessWidget {
  const AppTimeSeriesChart({
    required this.points,
    this.preset = AppChartPreset.explorable,
    super.key,
  });

  final List<AppChartPoint> points;
  final AppChartPreset preset;

  @override
  Widget build(BuildContext context) {
    return SyncfusionTimeSeriesChart(
      points: points,
      preset: preset,
    );
  }
}
