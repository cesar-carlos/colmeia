import 'package:colmeia/features/dashboards/domain/entities/dashboard_chart_point.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_time_series_chart.dart';
import 'package:flutter/material.dart';

class DashboardChartRenderer extends StatelessWidget {
  const DashboardChartRenderer({
    required this.title,
    required this.subtitle,
    required this.points,
    super.key,
    this.titleTrailing,
    this.belowSubtitle,
  });

  final String title;
  final String subtitle;
  final List<DashboardChartPoint> points;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;

  @override
  Widget build(BuildContext context) {
    final chartPoints = points
        .map(
          (point) => AppChartPoint(
            label: point.label,
            value: point.value,
          ),
        )
        .toList();

    return AppTimeSeriesChart(
      title: title,
      subtitle: subtitle,
      titleTrailing: titleTrailing,
      belowSubtitle: belowSubtitle,
      points: chartPoints,
      preset: AppChartPreset.standard,
    );
  }
}
