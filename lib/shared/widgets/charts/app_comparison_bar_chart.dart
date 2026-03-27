import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_comparison_bar_chart.dart';
import 'package:flutter/material.dart';

class AppComparisonBarChart extends StatelessWidget {
  const AppComparisonBarChart({
    required this.points,
    this.preset = AppChartPreset.standard,
    super.key,
  });

  final List<AppChartPoint> points;
  final AppChartPreset preset;

  @override
  Widget build(BuildContext context) {
    return SyncfusionComparisonBarChart(
      points: points,
      preset: preset,
    );
  }
}
