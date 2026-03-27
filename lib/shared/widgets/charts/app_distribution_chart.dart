import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_distribution_chart.dart';
import 'package:flutter/material.dart';

class AppDistributionChart extends StatelessWidget {
  const AppDistributionChart({
    required this.points,
    this.preset = AppChartPreset.standard,
    super.key,
  });

  final List<AppChartPoint> points;
  final AppChartPreset preset;

  @override
  Widget build(BuildContext context) {
    return SyncfusionDistributionChart(
      points: points,
      preset: preset,
    );
  }
}
