import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SyncfusionComparisonBarChart extends StatelessWidget {
  const SyncfusionComparisonBarChart({
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
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        tooltipBehavior: TooltipBehavior(enable: true),
        primaryXAxis: const CategoryAxis(
          majorGridLines: MajorGridLines(width: 0),
        ),
        primaryYAxis: const NumericAxis(
          axisLine: AxisLine(width: 0),
        ),
        series: <CartesianSeries<AppChartPoint, String>>[
          ColumnSeries<AppChartPoint, String>(
            dataSource: points,
            xValueMapper: (point, _) => point.label,
            yValueMapper: (point, _) => point.value,
            color: chartTheme.primaryColor,
            borderRadius: const BorderRadius.all(Radius.circular(6)),
          ),
        ],
      ),
    );
  }
}
