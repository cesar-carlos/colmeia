import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/widgets/charts/app_area_trend_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_formatters.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SyncfusionAreaTrendChart extends StatelessWidget {
  const SyncfusionAreaTrendChart({
    required this.entries,
    required this.isMultiSeries,
    required this.style,
    required this.preset,
    super.key,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<AppAreaTrendEntry> entries;
  final bool isMultiSeries;
  final AppAreaTrendChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(context, preset: preset);
    final colors = Theme.of(context).appColors;
    final resolvedHeight = style.height ?? chartTheme.height;
    final gridLineColor = colors.outlineVariant.withValues(alpha: 0.35);

    if (isLoading) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(
          child: CircularProgressIndicator(color: chartTheme.primaryColor),
        ),
      );
    }

    final allEmpty = entries.every((e) => e.points.isEmpty);
    if (allEmpty && emptyPlaceholder != null) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(child: emptyPlaceholder),
      );
    }

    final resolvedSeries = <CartesianSeries<AppChartPoint, String>>[];
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final seriesColor = entry.color ?? chartTheme.paletteColor(i);
      final gradient = style.showGradientFill
          ? LinearGradient(
              colors: <Color>[
                seriesColor.withValues(alpha: isMultiSeries ? 0.2 : 0.35),
                seriesColor.withValues(alpha: 0.03),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            )
          : null;
      final solidFill = style.showGradientFill
          ? null
          : seriesColor.withValues(alpha: isMultiSeries ? 0.12 : 0.15);

      resolvedSeries.add(
        AreaSeries<AppChartPoint, String>(
          dataSource: entry.points,
          xValueMapper: (p, _) => p.label,
          yValueMapper: (p, _) => p.value,
          name: entry.label,
          borderWidth: style.lineWidth ?? 2.5,
          borderColor: seriesColor,
          color: solidFill,
          gradient: gradient,
          animationDuration:
              style.animationDuration?.inMilliseconds.toDouble() ?? 1200,
          markerSettings: MarkerSettings(
            isVisible: style.showMarkers,
            height: style.markerSize ?? 6,
            width: style.markerSize ?? 6,
            color: seriesColor,
            borderColor: colors.surface,
          ),
        ),
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
                  format: 'point.x : point.y',
                ),
              )
            : null,
        legend: Legend(
          isVisible: isMultiSeries,
          position: LegendPosition.bottom,
          overflowMode: LegendItemOverflowMode.wrap,
        ),
        zoomPanBehavior: ZoomPanBehavior(
          enablePinching: chartTheme.enableSelectionZooming,
          enablePanning: chartTheme.enableSelectionZooming,
          enableSelectionZooming: chartTheme.enableSelectionZooming,
        ),
        primaryXAxis: const CategoryAxis(
          majorGridLines: MajorGridLines(width: 0),
        ),
        primaryYAxis: NumericAxis(
          axisLine: const AxisLine(width: 0),
          majorGridLines: MajorGridLines(
            color: gridLineColor,
            width: style.showYGridLines ? 1 : 0,
          ),
          numberFormat:
              style.yAxisFormat ?? AppChartFormatters.compactCurrencyFormat,
          axisLabelFormatter: style.yAxisFormat == null
              ? null
              : (details) => ChartAxisLabel(
                  style.yAxisFormat!.format(details.value),
                  details.textStyle,
                ),
        ),
        series: resolvedSeries,
      ),
    );
  }
}
