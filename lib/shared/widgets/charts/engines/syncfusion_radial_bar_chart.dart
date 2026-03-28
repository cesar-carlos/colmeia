import 'dart:math' as math;

import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_radial_bar_chart.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SyncfusionRadialBarChart<T> extends StatelessWidget {
  const SyncfusionRadialBarChart({
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
  final AppRadialBarChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(context, preset: preset);
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedHeight = style.height ?? chartTheme.height;

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

    final maximumValue = _resolveMaximumValue();
    final resolvedTrackColor =
        style.trackColor ??
        colorScheme.surfaceContainerHighest.withValues(
          alpha: style.trackOpacity,
        );

    return SizedBox(
      height: resolvedHeight,
      child: SfCircularChart(
        margin: style.chartPadding ?? EdgeInsets.zero,
        legend: Legend(
          isVisible: style.showLegend,
          position: LegendPosition.bottom,
          overflowMode: LegendItemOverflowMode.wrap,
        ),
        onTooltipRender: tooltipLabelBuilder == null
            ? null
            : (args) {
                final pointIndex = args.pointIndex?.toInt();
                if (pointIndex != null &&
                    pointIndex >= 0 &&
                    pointIndex < items.length) {
                  final item = items[pointIndex];
                  final label = tooltipLabelBuilder!(
                    item,
                    valueBuilder(item),
                  );
                  if (label?.trim().isNotEmpty ?? false) {
                    args.text = label;
                  }
                }
              },
        tooltipBehavior: TooltipBehavior(enable: style.showTooltip),
        series: <RadialBarSeries<T, String>>[
          RadialBarSeries<T, String>(
            dataSource: items,
            maximumValue: maximumValue,
            innerRadius: '28%',
            gap: '12%',
            trackColor: resolvedTrackColor,
            cornerStyle: CornerStyle.bothCurve,
            xValueMapper: (item, _) => labelBuilder(item),
            yValueMapper: (item, _) => valueBuilder(item).toDouble(),
            pointColorMapper: (item, index) {
              final resolvedColor = colorBuilder?.call(item);
              return resolvedColor ?? chartTheme.paletteColor(index);
            },
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
        ],
      ),
    );
  }

  double _resolveMaximumValue() {
    final styleMax = style.maximumValue;
    if (styleMax != null && styleMax > 0) {
      return styleMax;
    }

    var maxValue = 0.0;
    for (final item in items) {
      maxValue = math.max(maxValue, valueBuilder(item).toDouble());
    }

    return math.max(maxValue, 1);
  }
}
