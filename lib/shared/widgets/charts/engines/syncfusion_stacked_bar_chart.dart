import 'dart:math' as math;

import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_stacked_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_states.dart';
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
    this.onSegmentTap,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<G> groups;
  final String Function(G group) groupLabelBuilder;
  final List<AppStackedBarSeries<G>> series;
  final AppStackedBarChartStyle style;
  final AppChartPreset preset;
  final void Function(
    G group,
    AppStackedBarSeries<G> series,
    int groupIndex,
    int seriesIndex,
    num value,
  )?
  onSegmentTap;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(context, preset: preset);
    final resolvedHeight = style.height ?? chartTheme.height;
    final isHorizontal = style.orientation == Axis.horizontal;
    final resolvedChartHeight = isHorizontal
        ? _resolveHorizontalChartHeight(resolvedHeight)
        : resolvedHeight;

    if (isLoading) {
      return buildChartLoadingState(
        context: context,
        height: resolvedChartHeight,
        indicatorColor: chartTheme.primaryColor,
      );
    }

    if (groups.isEmpty) {
      return buildChartEmptyState(
        context: context,
        height: resolvedChartHeight,
        message: 'Sem grupos disponiveis para comparacao.',
        placeholder: emptyPlaceholder,
      );
    }

    final animationMs = resolveChartAnimationDurationMs(
      context: context,
      styleDuration: style.animationDuration,
      defaultMs: AppChartEngineAnimationDefaults.cartesianSeriesMs,
    );

    SelectionBehavior? buildSelectionBehavior() {
      if (!style.enableTapHighlight) {
        return null;
      }
      return SelectionBehavior(
        enable: true,
        unselectedOpacity: style.tapHighlightDimmedOpacity
            .clamp(0, 1)
            .toDouble(),
      );
    }

    final resolvedSeries = <CartesianSeries<G, String>>[];
    for (var i = 0; i < series.length; i++) {
      final s = series[i];
      final color = s.color ?? chartTheme.paletteColor(i);
      final void Function(ChartPointDetails)? tapHandler;
      if (onSegmentTap == null) {
        tapHandler = null;
      } else {
        tapHandler = (details) {
          final idx = details.pointIndex;
          if (idx != null && idx >= 0 && idx < groups.length) {
            final group = groups[idx];
            onSegmentTap!(
              group,
              s,
              idx,
              i,
              s.valueBuilder(group),
            );
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
              animationDuration: animationMs,
              selectionBehavior: buildSelectionBehavior(),
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
              animationDuration: animationMs,
              selectionBehavior: buildSelectionBehavior(),
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
              animationDuration: animationMs,
              selectionBehavior: buildSelectionBehavior(),
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
              animationDuration: animationMs,
              selectionBehavior: buildSelectionBehavior(),
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
      height: resolvedChartHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : _minVerticalGroupWidth * groups.length;
          final minChartWidth = isHorizontal
              ? availableWidth
              : math.max(
                  availableWidth,
                  groups.length * _minVerticalGroupWidth,
                );
          final chart = SizedBox(
            width: minChartWidth,
            height: resolvedChartHeight,
            child: SfCartesianChart(
              margin: style.chartPadding ?? EdgeInsets.zero,
              plotAreaBorderWidth: 0,
              selectionType: style.enableTapHighlight
                  ? SelectionType.point
                  : SelectionType.series,
              onTooltipRender: buildSanitizingTooltipRenderer(),
              tooltipBehavior: buildChartTooltipBehavior(
                context,
                enable: style.showTooltip,
                shared: true,
              ),
              legend: Legend(
                isVisible: style.showLegend,
                position: LegendPosition.bottom,
                textStyle: style.legendTextStyle,
                overflowMode: LegendItemOverflowMode.wrap,
              ),
              zoomPanBehavior: ZoomPanBehavior(
                enablePinching: chartTheme.enableSelectionZooming,
                enablePanning: chartTheme.enableSelectionZooming,
                enableSelectionZooming: chartTheme.enableSelectionZooming,
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

          if (isHorizontal || minChartWidth <= availableWidth) {
            return chart;
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: chart,
          );
        },
      ),
    );
  }

  double _resolveHorizontalChartHeight(double baseHeight) {
    final minHeight = groups.length * _minHorizontalGroupExtent;
    final legendHeight = style.showLegend ? _legendHeightAllowance : 0.0;
    return math.max(baseHeight, minHeight + legendHeight);
  }
}

const double _legendHeightAllowance = 56;
const double _minHorizontalGroupExtent = 56;
const double _minVerticalGroupWidth = 72;
