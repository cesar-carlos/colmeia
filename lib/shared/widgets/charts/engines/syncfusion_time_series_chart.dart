import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_formatters.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_time_series_chart.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_states.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SyncfusionTimeSeriesChart extends StatelessWidget {
  const SyncfusionTimeSeriesChart({
    required this.points,
    required this.preset,
    required this.style,
    super.key,
    this.isLoading = false,
    this.emptyPlaceholder,
    this.onPointTap,
  });

  final List<AppChartPoint> points;
  final AppChartPreset preset;
  final AppTimeSeriesChartStyle style;
  final bool isLoading;
  final Widget? emptyPlaceholder;
  final void Function(AppChartPoint point, int index)? onPointTap;

  @override
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(
      context,
      preset: preset,
    );
    final colors = Theme.of(context).appColors;
    final resolvedHeight = style.height ?? chartTheme.height;
    final gridLineColor = colors.outlineVariant.withValues(alpha: 0.35);

    if (isLoading) {
      return buildChartLoadingState(
        context: context,
        height: resolvedHeight,
        indicatorColor: chartTheme.primaryColor,
        label: 'Carregando serie temporal...',
      );
    }

    if (points.isEmpty) {
      return buildChartEmptyState(
        context: context,
        height: resolvedHeight,
        message: 'Sem dados disponiveis para este periodo.',
        placeholder: emptyPlaceholder,
      );
    }

    return SizedBox(
      height: resolvedHeight,
      child: SfCartesianChart(
        margin: style.chartPadding ?? EdgeInsets.zero,
        plotAreaBorderWidth: 0,
        tooltipBehavior: TooltipBehavior(enable: style.showTooltip),
        primaryXAxis: const CategoryAxis(
          majorGridLines: MajorGridLines(width: 0),
        ),
        primaryYAxis: NumericAxis(
          numberFormat:
              style.yAxisFormat ?? AppChartFormatters.compactCurrencyFormat,
          axisLine: const AxisLine(width: 0),
          majorGridLines: MajorGridLines(
            color: gridLineColor,
            width: style.showYGridLines ? 1 : 0,
          ),
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
            borderWidth: style.lineWidth ?? 3,
            gradient: chartTheme.gradient,
            onPointTap: onPointTap == null
                ? null
                : (args) {
                    final index = args.pointIndex;
                    if (index == null || index < 0 || index >= points.length) {
                      return;
                    }
                    onPointTap!(points[index], index);
                  },
          ),
        ],
      ),
    );
  }
}
