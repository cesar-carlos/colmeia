import 'package:colmeia/shared/widgets/charts/app_chart_formatters.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SyncfusionTimeSeriesChart extends StatelessWidget {
  const SyncfusionTimeSeriesChart({
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
        primaryYAxis: NumericAxis(
          numberFormat: AppChartFormatters.compactCurrencyFormat,
          axisLine: const AxisLine(width: 0),
        ),
        zoomPanBehavior: ZoomPanBehavior(
          enablePinching: chartTheme.enableSelectionZooming,
          enablePanning: chartTheme.enableSelectionZooming,
          enableSelectionZooming: chartTheme.enableSelectionZooming,
        ),
        series: <CartesianSeries<AppChartPoint, String>>[
          SplineAreaSeries<AppChartPoint, String>(
            dataSource: points,
            xValueMapper: (point, _) => point.label,
            yValueMapper: (point, _) => point.value,
            borderWidth: 3,
            gradient: chartTheme.gradient,
          ),
        ],
      ),
    );
  }
}
