import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_formatters.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_step_line_chart.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SyncfusionStepLineChart extends StatelessWidget {
  const SyncfusionStepLineChart({
    required this.entries,
    required this.isMultiSeries,
    required this.style,
    required this.preset,
    super.key,
    this.onPointTap,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<AppStepLineEntry> entries;
  final bool isMultiSeries;
  final void Function(
    AppStepLineEntry entry,
    AppChartPoint point,
    int pointIndex,
    int seriesIndex,
  )?
  onPointTap;
  final AppStepLineChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(context, preset: preset);
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final resolvedHeight = style.height ?? chartTheme.height;
    final gridLineColor = colors.outlineVariant.withValues(alpha: 0.35);
    final visibleEntries = entries
        .map(
          (entry) => AppStepLineEntry(
            label: entry.label,
            color: entry.color,
            points: entry.points
                .where(_hasRenderableValue)
                .toList(growable: false),
          ),
        )
        .toList(growable: false);

    if (isLoading) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(
          child: Semantics(
            container: true,
            liveRegion: true,
            label: 'Carregando serie temporal...',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircularProgressIndicator(color: chartTheme.primaryColor),
                const SizedBox(height: 12),
                Text(
                  'Carregando serie temporal...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final allEmpty = visibleEntries.every((entry) => entry.points.isEmpty);
    if (allEmpty) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(
          child:
              emptyPlaceholder ??
              Text(
                'Sem dados disponiveis para este periodo.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
        ),
      );
    }

    final series = <CartesianSeries<AppChartPoint, String>>[];
    for (var i = 0; i < visibleEntries.length; i++) {
      final entry = visibleEntries[i];
      final seriesColor = entry.color ?? chartTheme.paletteColor(i);
      series.add(
        StepLineSeries<AppChartPoint, String>(
          dataSource: entry.points,
          xValueMapper: (point, _) => point.label,
          yValueMapper: (point, _) => point.value,
          name: entry.label,
          color: seriesColor,
          width: style.lineWidth ?? 2.5,
          animationDuration:
              style.animationDuration?.inMilliseconds.toDouble() ?? 1200,
          markerSettings: MarkerSettings(
            isVisible: style.showMarkers,
            height: style.markerSize ?? 7,
            width: style.markerSize ?? 7,
            color: seriesColor,
            borderColor: colors.surface,
          ),
          dataLabelSettings: DataLabelSettings(
            isVisible: style.showDataLabels,
          ),
          onPointTap: onPointTap == null
              ? null
              : (details) {
                  final pointIndex = details.pointIndex;
                  if (pointIndex != null &&
                      pointIndex >= 0 &&
                      pointIndex < entry.points.length) {
                    onPointTap!(entry, entry.points[pointIndex], pointIndex, i);
                  }
                },
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
          isVisible: isMultiSeries && style.showLegend,
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
        series: series,
      ),
    );
  }

  bool _hasRenderableValue(AppChartPoint point) {
    return point.value.toDouble().isFinite;
  }
}
