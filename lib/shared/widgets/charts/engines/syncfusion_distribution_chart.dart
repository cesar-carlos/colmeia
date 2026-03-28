import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_distribution_chart.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SyncfusionDistributionChart extends StatelessWidget {
  const SyncfusionDistributionChart({
    required this.points,
    required this.preset,
    required this.style,
    super.key,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<AppChartPoint> points;
  final AppChartPreset preset;
  final AppDistributionChartStyle style;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(
      context,
      preset: preset,
    );
    final resolvedHeight = style.height ?? chartTheme.height;

    if (isLoading) {
      return SizedBox(
        height: resolvedHeight,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (points.isEmpty && emptyPlaceholder != null) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(child: emptyPlaceholder),
      );
    }

    return SizedBox(
      height: resolvedHeight,
      child: SfCircularChart(
        margin: style.chartPadding ?? EdgeInsets.zero,
        legend: Legend(isVisible: style.showLegend),
        tooltipBehavior: TooltipBehavior(enable: style.showTooltip),
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
