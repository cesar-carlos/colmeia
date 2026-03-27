import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SyncfusionDistributionChart extends StatelessWidget {
  const SyncfusionDistributionChart({
    required this.points,
    required this.preset,
    super.key,
  });

  final List<AppChartPoint> points;
  final AppChartPreset preset;

  @override
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(
      context,
      preset: preset,
    );

    return SizedBox(
      height: chartTheme.height,
      child: SfCircularChart(
        legend: const Legend(isVisible: true),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CircularSeries<AppChartPoint, String>>[
          DoughnutSeries<AppChartPoint, String>(
            dataSource: points,
            xValueMapper: (point, _) => point.label,
            yValueMapper: (point, _) => point.value,
          ),
        ],
      ),
    );
  }
}
