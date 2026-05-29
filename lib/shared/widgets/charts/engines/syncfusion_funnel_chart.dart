import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_funnel_chart.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_states.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SyncfusionFunnelChart<T> extends StatelessWidget {
  const SyncfusionFunnelChart({
    required this.items,
    required this.labelBuilder,
    required this.valueBuilder,
    required this.style,
    required this.preset,
    super.key,
    this.colorBuilder,
    this.dataLabelBuilder,
    this.tooltipLabelBuilder,
    this.onSegmentTap,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<T> items;
  final String Function(T item) labelBuilder;
  final num Function(T item) valueBuilder;
  final Color? Function(T item)? colorBuilder;
  final String? Function(T item, num value)? dataLabelBuilder;
  final String? Function(T item, num value)? tooltipLabelBuilder;
  final void Function(T item, int index)? onSegmentTap;
  final AppFunnelChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(context, preset: preset);
    final resolvedHeight = style.height ?? chartTheme.height;

    if (isLoading) {
      return buildChartLoadingState(
        context: context,
        height: resolvedHeight,
        indicatorColor: chartTheme.primaryColor,
      );
    }

    if (items.isEmpty) {
      return buildChartEmptyState(
        context: context,
        height: resolvedHeight,
        message: 'Sem etapas de funil para este recorte.',
        placeholder: emptyPlaceholder,
      );
    }

    return SizedBox(
      height: resolvedHeight,
      child: SfFunnelChart(
        margin: style.chartPadding ?? EdgeInsets.zero,
        onDataLabelRender: dataLabelBuilder == null
            ? null
            : (args) {
                final pointIndex = args.pointIndex;
                if (pointIndex >= 0 && pointIndex < items.length) {
                  final item = items[pointIndex];
                  final label = dataLabelBuilder!(
                    item,
                    valueBuilder(item),
                  );
                  if (label?.trim().isNotEmpty ?? false) {
                    args.text = label;
                  }
                }
              },
        legend: Legend(
          isVisible: style.showLegend,
          position: LegendPosition.bottom,
          overflowMode: LegendItemOverflowMode.wrap,
        ),
        onTooltipRender: buildSanitizingTooltipRenderer(
          bodyResolver: tooltipLabelBuilder == null
              ? null
              : (args) {
                  final pointIndex = args.pointIndex?.toInt();
                  if (pointIndex == null ||
                      pointIndex < 0 ||
                      pointIndex >= items.length) {
                    return null;
                  }
                  final item = items[pointIndex];
                  return tooltipLabelBuilder!(
                    item,
                    valueBuilder(item),
                  );
                },
        ),
        tooltipBehavior: buildChartTooltipBehavior(
          context,
          enable: style.showTooltip,
        ),
        series: FunnelSeries<T, String>(
          dataSource: items,
          animationDuration: resolveChartAnimationDurationMs(
            context: context,
            styleDuration: null,
            defaultMs: AppChartEngineAnimationDefaults.circularSeriesMs,
          ),
          xValueMapper: (item, _) => labelBuilder(item),
          yValueMapper: (item, _) => valueBuilder(item),
          pointColorMapper: (item, index) {
            final resolvedColor = colorBuilder?.call(item);
            return resolvedColor ?? chartTheme.paletteColor(index);
          },
          gapRatio: style.gapRatio,
          neckWidth: style.neckWidth,
          neckHeight: style.neckHeight,
          dataLabelSettings: DataLabelSettings(
            isVisible: style.showDataLabels,
            textStyle: style.dataLabelTextStyle,
          ),
          onPointTap: onSegmentTap == null
              ? null
              : (details) {
                  final index = details.pointIndex;
                  if (index != null && index >= 0 && index < items.length) {
                    onSegmentTap!(items[index], index);
                  }
                },
        ),
      ),
    );
  }
}
