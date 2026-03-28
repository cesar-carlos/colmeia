import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_scatter_bubble_chart.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SyncfusionScatterBubbleChart<T> extends StatelessWidget {
  const SyncfusionScatterBubbleChart({
    required this.items,
    required this.xValueBuilder,
    required this.yValueBuilder,
    required this.style,
    required this.preset,
    super.key,
    this.labelBuilder,
    this.bubbleSizeBuilder,
    this.colorBuilder,
    this.tooltipLabelBuilder,
    this.onPointTap,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<T> items;
  final num Function(T item) xValueBuilder;
  final num Function(T item) yValueBuilder;
  final String Function(T item)? labelBuilder;
  final num Function(T item)? bubbleSizeBuilder;
  final Color? Function(T item)? colorBuilder;
  final String? Function(T item)? tooltipLabelBuilder;
  final void Function(T item, int index)? onPointTap;
  final AppScatterBubbleChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(context, preset: preset);
    final colors = Theme.of(context).appColors;
    final resolvedHeight = style.height ?? chartTheme.height;
    final baseColor = style.pointColor ?? chartTheme.primaryColor;

    if (isLoading) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(
          child: CircularProgressIndicator(color: chartTheme.primaryColor),
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
        onTooltipRender: tooltipLabelBuilder == null
            ? null
            : (args) {
                final pointIndex = args.pointIndex?.toInt();
                if (pointIndex != null &&
                    pointIndex >= 0 &&
                    pointIndex < items.length) {
                  final label = tooltipLabelBuilder!.call(items[pointIndex]);
                  if (label?.trim().isNotEmpty ?? false) {
                    args.text = label;
                  }
                }
              },
        tooltipBehavior: TooltipBehavior(enable: style.showTooltip),
        legend: Legend(isVisible: style.showLegend),
        primaryXAxis: NumericAxis(
          minimum: style.minX?.toDouble(),
          maximum: style.maxX?.toDouble(),
          majorGridLines: MajorGridLines(
            color: colors.outlineVariant.withValues(alpha: 0.35),
            width: style.showGridLines ? 1 : 0,
          ),
          labelStyle: style.axisLabelTextStyle,
          title: AxisTitle(
            text: style.xAxisTitle ?? '',
            textStyle: style.axisLabelTextStyle,
          ),
          axisLabelFormatter: style.xAxisFormat == null
              ? null
              : (details) => ChartAxisLabel(
                  style.xAxisFormat!.format(details.value),
                  details.textStyle,
                ),
        ),
        primaryYAxis: NumericAxis(
          minimum: style.minY?.toDouble(),
          maximum: style.maxY?.toDouble(),
          majorGridLines: MajorGridLines(
            color: colors.outlineVariant.withValues(alpha: 0.35),
            width: style.showGridLines ? 1 : 0,
          ),
          labelStyle: style.axisLabelTextStyle,
          title: AxisTitle(
            text: style.yAxisTitle ?? '',
            textStyle: style.axisLabelTextStyle,
          ),
          axisLabelFormatter: style.yAxisFormat == null
              ? null
              : (details) => ChartAxisLabel(
                  style.yAxisFormat!.format(details.value),
                  details.textStyle,
                ),
        ),
        series: <CartesianSeries<T, num>>[
          if (bubbleSizeBuilder == null)
            ScatterSeries<T, num>(
              dataSource: items,
              xValueMapper: (item, _) => xValueBuilder(item),
              yValueMapper: (item, _) => yValueBuilder(item),
              dataLabelMapper: labelBuilder == null
                  ? null
                  : (item, _) => labelBuilder!(item),
              pointColorMapper: colorBuilder == null
                  ? null
                  : (item, _) => colorBuilder!(item) ?? baseColor,
              color: colorBuilder == null ? baseColor : null,
              markerSettings: MarkerSettings(
                isVisible: true,
                width: style.markerSize ?? 10,
                height: style.markerSize ?? 10,
              ),
              dataLabelSettings: DataLabelSettings(
                isVisible: style.showDataLabels,
                textStyle: style.dataLabelTextStyle,
              ),
              onPointTap: onPointTap == null
                  ? null
                  : (details) {
                      final index = details.pointIndex;
                      if (index != null && index >= 0) {
                        onPointTap!(items[index], index);
                      }
                    },
            )
          else
            BubbleSeries<T, num>(
              dataSource: items,
              xValueMapper: (item, _) => xValueBuilder(item),
              yValueMapper: (item, _) => yValueBuilder(item),
              sizeValueMapper: (item, _) => bubbleSizeBuilder!(item),
              dataLabelMapper: labelBuilder == null
                  ? null
                  : (item, _) => labelBuilder!(item),
              pointColorMapper: colorBuilder == null
                  ? null
                  : (item, _) => colorBuilder!(item) ?? baseColor,
              color: colorBuilder == null
                  ? baseColor.withValues(alpha: style.bubbleOpacity ?? 0.75)
                  : null,
              dataLabelSettings: DataLabelSettings(
                isVisible: style.showDataLabels,
                textStyle: style.dataLabelTextStyle,
              ),
              onPointTap: onPointTap == null
                  ? null
                  : (details) {
                      final index = details.pointIndex;
                      if (index != null && index >= 0) {
                        onPointTap!(items[index], index);
                      }
                    },
            ),
        ],
      ),
    );
  }
}
