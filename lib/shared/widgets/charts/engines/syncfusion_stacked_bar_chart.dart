import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_stacked_bar_chart.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SyncfusionStackedBarChart<G> extends StatelessWidget {
  const SyncfusionStackedBarChart({
    required this.groups,
    required this.groupLabelBuilder,
    required this.series,
    required this.style,
    required this.preset,
    super.key,
    this.onGroupTap,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<G> groups;
  final String Function(G group) groupLabelBuilder;
  final List<AppStackedBarSeries<G>> series;
  final AppStackedBarChartStyle style;
  final AppChartPreset preset;
  final void Function(G group, int index)? onGroupTap;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(context, preset: preset);
    final resolvedHeight = style.height ?? chartTheme.height;
    final isHorizontal = style.orientation == Axis.horizontal;

    if (isLoading) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(
          child: CircularProgressIndicator(color: chartTheme.primaryColor),
        ),
      );
    }

    if (groups.isEmpty && emptyPlaceholder != null) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(child: emptyPlaceholder),
      );
    }

    final resolvedSeries = <CartesianSeries<G, String>>[];
    for (var i = 0; i < series.length; i++) {
      final s = series[i];
      final color = s.color ?? chartTheme.paletteColor(i);
      final void Function(ChartPointDetails)? tapHandler;
      if (onGroupTap == null) {
        tapHandler = null;
      } else {
        tapHandler = (details) {
          final idx = details.pointIndex;
          if (idx != null && idx >= 0 && idx < groups.length) {
            onGroupTap!(groups[idx], idx);
          }
        };
      }

      if (isHorizontal) {
        if (style.isPercentStack) {
          resolvedSeries.add(
            StackedBar100Series<G, String>(
              dataSource: groups,
              xValueMapper: (g, _) => groupLabelBuilder(g),
              yValueMapper: (g, _) => s.valueBuilder(g),
              name: s.label,
              color: color,
              width: style.barWidth ?? 0.7,
              spacing: style.spacing ?? 0.2,
              animationDuration:
                  style.animationDuration?.inMilliseconds.toDouble() ?? 1200,
              dataLabelSettings: DataLabelSettings(
                isVisible: style.showDataLabels,
                textStyle: style.dataLabelTextStyle,
              ),
              onPointTap: tapHandler,
            ),
          );
        } else {
          resolvedSeries.add(
            StackedBarSeries<G, String>(
              dataSource: groups,
              xValueMapper: (g, _) => groupLabelBuilder(g),
              yValueMapper: (g, _) => s.valueBuilder(g),
              name: s.label,
              color: color,
              width: style.barWidth ?? 0.7,
              spacing: style.spacing ?? 0.2,
              animationDuration:
                  style.animationDuration?.inMilliseconds.toDouble() ?? 1200,
              dataLabelSettings: DataLabelSettings(
                isVisible: style.showDataLabels,
                textStyle: style.dataLabelTextStyle,
              ),
              onPointTap: tapHandler,
            ),
          );
        }
      } else {
        if (style.isPercentStack) {
          resolvedSeries.add(
            StackedColumn100Series<G, String>(
              dataSource: groups,
              xValueMapper: (g, _) => groupLabelBuilder(g),
              yValueMapper: (g, _) => s.valueBuilder(g),
              name: s.label,
              color: color,
              width: style.barWidth ?? 0.7,
              spacing: style.spacing ?? 0.2,
              animationDuration:
                  style.animationDuration?.inMilliseconds.toDouble() ?? 1200,
              dataLabelSettings: DataLabelSettings(
                isVisible: style.showDataLabels,
                textStyle: style.dataLabelTextStyle,
              ),
              onPointTap: tapHandler,
            ),
          );
        } else {
          resolvedSeries.add(
            StackedColumnSeries<G, String>(
              dataSource: groups,
              xValueMapper: (g, _) => groupLabelBuilder(g),
              yValueMapper: (g, _) => s.valueBuilder(g),
              name: s.label,
              color: color,
              width: style.barWidth ?? 0.7,
              spacing: style.spacing ?? 0.2,
              animationDuration:
                  style.animationDuration?.inMilliseconds.toDouble() ?? 1200,
              dataLabelSettings: DataLabelSettings(
                isVisible: style.showDataLabels,
                textStyle: style.dataLabelTextStyle,
              ),
              onPointTap: tapHandler,
            ),
          );
        }
      }
    }

    return SizedBox(
      height: resolvedHeight,
      child: SfCartesianChart(
        margin: style.chartPadding ?? EdgeInsets.zero,
        plotAreaBorderWidth: 0,
        tooltipBehavior: TooltipBehavior(enable: style.showTooltip),
        legend: Legend(
          isVisible: style.showLegend,
          position: LegendPosition.bottom,
          textStyle: style.legendTextStyle,
          overflowMode: LegendItemOverflowMode.wrap,
        ),
        primaryXAxis: CategoryAxis(
          isVisible: style.showXAxis,
          majorGridLines: const MajorGridLines(width: 0),
          labelStyle: style.axisLabelTextStyle,
        ),
        primaryYAxis: NumericAxis(
          isVisible: style.showYAxis,
          axisLine: const AxisLine(width: 0),
          majorGridLines: MajorGridLines(
            width: style.showYGridLines ? 1 : 0,
          ),
          labelStyle: style.axisLabelTextStyle,
          numberFormat: style.yAxisFormat,
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
