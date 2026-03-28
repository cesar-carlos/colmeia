import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_range_area_chart.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SyncfusionRangeAreaChart extends StatelessWidget {
  const SyncfusionRangeAreaChart({
    required this.points,
    required this.style,
    required this.preset,
    super.key,
    this.onPointTap,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<AppRangeAreaPoint> points;
  final void Function(AppRangeAreaPoint point, int index)? onPointTap;
  final AppRangeAreaChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(context, preset: preset);
    final colors = Theme.of(context).appColors;
    final resolvedHeight = style.height ?? chartTheme.height;
    final fillColor =
        style.fillColor ?? chartTheme.primaryColor.withValues(alpha: 0.18);
    final borderColor = style.borderColor ?? chartTheme.primaryColor;

    if (isLoading) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(
          child: CircularProgressIndicator(color: chartTheme.primaryColor),
        ),
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
      child: SfCartesianChart(
        margin: style.chartPadding ?? EdgeInsets.zero,
        plotAreaBorderWidth: 0,
        tooltipBehavior: TooltipBehavior(enable: style.showTooltip),
        trackballBehavior: style.showTrackball
            ? TrackballBehavior(
                enable: true,
                activationMode: ActivationMode.singleTap,
                tooltipSettings: const InteractiveTooltip(
                  format: 'point.x',
                ),
              )
            : null,
        primaryXAxis: const CategoryAxis(
          majorGridLines: MajorGridLines(width: 0),
        ),
        primaryYAxis: NumericAxis(
          axisLine: const AxisLine(width: 0),
          majorGridLines: MajorGridLines(
            color: colors.outlineVariant.withValues(alpha: 0.35),
            width: style.showYGridLines ? 1 : 0,
          ),
          axisLabelFormatter: style.yAxisFormat == null
              ? null
              : (details) => ChartAxisLabel(
                  style.yAxisFormat!.format(details.value),
                  details.textStyle,
                ),
        ),
        series: <CartesianSeries<AppRangeAreaPoint, String>>[
          RangeAreaSeries<AppRangeAreaPoint, String>(
            dataSource: points,
            xValueMapper: (point, _) => point.label,
            lowValueMapper: (point, _) => point.low,
            highValueMapper: (point, _) => point.high,
            borderColor: borderColor,
            borderWidth: style.lineWidth ?? 2,
            color: fillColor,
            animationDuration:
                style.animationDuration?.inMilliseconds.toDouble() ?? 1200,
            markerSettings: MarkerSettings(
              isVisible: style.showMarkers,
              height: style.markerSize ?? 6,
              width: style.markerSize ?? 6,
              color: borderColor,
              borderColor: colors.surface,
            ),
            onPointTap: onPointTap == null
                ? null
                : (details) {
                    final index = details.pointIndex;
                    if (index != null && index >= 0) {
                      onPointTap!(points[index], index);
                    }
                  },
          ),
        ],
      ),
    );
  }
}
