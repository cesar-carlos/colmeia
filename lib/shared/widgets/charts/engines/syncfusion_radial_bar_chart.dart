import 'dart:math' as math;

import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_radial_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_states.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SyncfusionRadialBarChart<T> extends StatefulWidget {
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
  State<SyncfusionRadialBarChart<T>> createState() =>
      _SyncfusionRadialBarChartState<T>();
}

class _SyncfusionRadialBarChartState<T> extends State<SyncfusionRadialBarChart<T>> {
  List<T>? _itemsRef;
  double? _styleMaximumValueRef;
  late double _maximumValue;

  void _recomputeMaximumIfNeeded() {
    final styleMax = widget.style.maximumValue;
    if (identical(_itemsRef, widget.items) &&
        _styleMaximumValueRef == styleMax) {
      return;
    }
    _itemsRef = widget.items;
    _styleMaximumValueRef = styleMax;
    _maximumValue = _resolveMaximumValue();
  }

  double _resolveMaximumValue() {
    final styleMax = widget.style.maximumValue;
    if (styleMax != null && styleMax > 0) {
      return styleMax;
    }

    var maxValue = 0.0;
    for (final item in widget.items) {
      maxValue = math.max(maxValue, widget.valueBuilder(item).toDouble());
    }

    return math.max(maxValue, 1);
  }

  @override
  void initState() {
    super.initState();
    _recomputeMaximumIfNeeded();
  }

  @override
  void didUpdateWidget(covariant SyncfusionRadialBarChart<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _recomputeMaximumIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(context, preset: widget.preset);
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedHeight = widget.style.height ?? chartTheme.height;

    if (widget.isLoading) {
      return buildChartLoadingState(
        context: context,
        height: resolvedHeight,
        indicatorColor: chartTheme.primaryColor,
        label: 'Carregando distribuicao radial...',
      );
    }

    if (widget.items.isEmpty) {
      return buildChartEmptyState(
        context: context,
        height: resolvedHeight,
        message: 'Sem distribuicao radial para este recorte.',
        placeholder: widget.emptyPlaceholder,
      );
    }

    final resolvedTrackColor =
        widget.style.trackColor ??
        colorScheme.surfaceContainerHighest.withValues(
          alpha: widget.style.trackOpacity,
        );

    return SizedBox(
      height: resolvedHeight,
      child: SfCircularChart(
        margin: widget.style.chartPadding ?? EdgeInsets.zero,
        legend: Legend(
          isVisible: widget.style.showLegend,
          position: LegendPosition.bottom,
          overflowMode: LegendItemOverflowMode.wrap,
        ),
        onDataLabelRender: widget.dataLabelBuilder == null
            ? null
            : (args) {
                final index = args.pointIndex;
                if (index >= 0 && index < widget.items.length) {
                  final item = widget.items[index];
                  final label = widget.dataLabelBuilder!(
                    item,
                    widget.valueBuilder(item),
                  );
                  if (label?.trim().isNotEmpty ?? false) {
                    args.text = label;
                  }
                }
              },
        onTooltipRender: buildSanitizingTooltipRenderer(
          bodyResolver: widget.tooltipLabelBuilder == null
              ? null
              : (args) {
                  final pointIndex = args.pointIndex?.toInt();
                  if (pointIndex == null ||
                      pointIndex < 0 ||
                      pointIndex >= widget.items.length) {
                    return null;
                  }
                  final item = widget.items[pointIndex];
                  return widget.tooltipLabelBuilder!(
                    item,
                    widget.valueBuilder(item),
                  );
                },
        ),
        tooltipBehavior: buildChartTooltipBehavior(
          context,
          enable: widget.style.showTooltip,
        ),
        series: <RadialBarSeries<T, String>>[
          RadialBarSeries<T, String>(
            dataSource: widget.items,
            animationDuration: resolveChartAnimationDurationMs(
              context: context,
              styleDuration: null,
              defaultMs:
                  AppChartEngineAnimationDefaults.circularSeriesMs,
            ),
            selectionBehavior: widget.style.enableTapHighlight
                ? SelectionBehavior(
                    enable: true,
                    unselectedOpacity: widget.style.tapHighlightDimmedOpacity
                        .clamp(0, 1)
                        .toDouble(),
                  )
                : null,
            maximumValue: _maximumValue,
            innerRadius: '28%',
            gap: '12%',
            trackColor: resolvedTrackColor,
            cornerStyle: CornerStyle.bothCurve,
            xValueMapper: (item, _) => widget.labelBuilder(item),
            yValueMapper: (item, _) => widget.valueBuilder(item).toDouble(),
            pointColorMapper: (item, index) {
              final resolvedColor = widget.colorBuilder?.call(item);
              return resolvedColor ?? chartTheme.paletteColor(index);
            },
            dataLabelSettings: DataLabelSettings(
              isVisible: widget.style.showDataLabels,
              textStyle: widget.style.dataLabelTextStyle,
            ),
            onPointTap: widget.onSegmentTap == null
                ? null
                : (details) {
                    final index = details.pointIndex;
                    if (index != null &&
                        index >= 0 &&
                        index < widget.items.length) {
                      widget.onSegmentTap!(widget.items[index], index);
                    }
                  },
          ),
        ],
      ),
    );
  }
}
