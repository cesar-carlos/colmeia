import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_combo_chart.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SyncfusionComboChart<T> extends StatelessWidget {
  const SyncfusionComboChart({
    required this.items,
    required this.xLabelBuilder,
    required this.barValueBuilder,
    required this.barSeriesLabel,
    required this.lineValueBuilder,
    required this.lineSeriesLabel,
    required this.style,
    required this.preset,
    super.key,
    this.onBarTap,
    this.onLineTap,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<T> items;
  final String Function(T item) xLabelBuilder;
  final num Function(T item) barValueBuilder;
  final String barSeriesLabel;
  final num Function(T item) lineValueBuilder;
  final String lineSeriesLabel;
  final AppComboChartStyle style;
  final AppChartPreset preset;
  final void Function(T item, int index)? onBarTap;
  final void Function(T item, int index)? onLineTap;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(context, preset: preset);
    final colors = Theme.of(context).appColors;
    final resolvedHeight = style.height ?? chartTheme.height;
    final gridLineColor = colors.outlineVariant.withValues(alpha: 0.35);
    final resolvedBarColor = style.barColor ?? chartTheme.primaryColor;
    final resolvedLineColor = style.lineColor ?? colors.secondary;

    if (isLoading) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(
          child: CircularProgressIndicator(color: resolvedBarColor),
        ),
      );
    }

    if (items.isEmpty && emptyPlaceholder != null) {
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
          name: 'leftAxis',
          axisLine: const AxisLine(width: 0),
          majorGridLines: MajorGridLines(
            color: gridLineColor,
            width: style.showYGridLines ? 1 : 0,
          ),
          labelStyle: style.axisLabelTextStyle,
          numberFormat: style.leftAxisFormat,
          axisLabelFormatter: style.leftAxisFormat == null
              ? null
              : (details) => ChartAxisLabel(
                    style.leftAxisFormat!.format(details.value),
                    details.textStyle,
                  ),
        ),
        axes: <ChartAxis>[
          NumericAxis(
            name: 'rightAxis',
            opposedPosition: true,
            axisLine: const AxisLine(width: 0),
            majorGridLines: const MajorGridLines(width: 0),
            labelStyle: style.axisLabelTextStyle,
            numberFormat: style.rightAxisFormat,
            axisLabelFormatter: style.rightAxisFormat == null
                ? null
                : (details) => ChartAxisLabel(
                      style.rightAxisFormat!.format(details.value),
                      details.textStyle,
                    ),
          ),
        ],
        series: <CartesianSeries<T, String>>[
          ColumnSeries<T, String>(
            dataSource: items,
            xValueMapper: (item, _) => xLabelBuilder(item),
            yValueMapper: (item, _) => barValueBuilder(item),
            name: barSeriesLabel,
            yAxisName: 'leftAxis',
            color: resolvedBarColor,
            width: style.barWidth ?? 0.6,
            spacing: style.barSpacing ?? 0.2,
            animationDuration:
                style.animationDuration?.inMilliseconds.toDouble() ?? 1200,
            dataLabelSettings: DataLabelSettings(
              isVisible: style.showDataLabels,
              textStyle: style.dataLabelTextStyle,
            ),
            onPointTap: onBarTap == null
                ? null
                : (details) {
                    final idx = details.pointIndex;
                    if (idx != null && idx >= 0 && idx < items.length) {
                      onBarTap!(items[idx], idx);
                    }
                  },
          ),
          LineSeries<T, String>(
            dataSource: items,
            xValueMapper: (item, _) => xLabelBuilder(item),
            yValueMapper: (item, _) => lineValueBuilder(item),
            name: lineSeriesLabel,
            yAxisName: 'rightAxis',
            color: resolvedLineColor,
            width: style.lineWidth ?? 2.5,
            animationDuration:
                style.animationDuration?.inMilliseconds.toDouble() ?? 1200,
            markerSettings: MarkerSettings(
              isVisible: style.showMarkers,
              height: 6,
              width: 6,
              color: resolvedLineColor,
              borderColor: colors.surface,
            ),
            onPointTap: onLineTap == null
                ? null
                : (details) {
                    final idx = details.pointIndex;
                    if (idx != null && idx >= 0 && idx < items.length) {
                      onLineTap!(items[idx], idx);
                    }
                  },
          ),
        ],
      ),
    );
  }
}
