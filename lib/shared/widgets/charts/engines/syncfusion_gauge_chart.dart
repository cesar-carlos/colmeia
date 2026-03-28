import 'dart:math' as math;

import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_gauge_chart.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class SyncfusionGaugeChart extends StatelessWidget {
  const SyncfusionGaugeChart({
    required this.value,
    required this.min,
    required this.max,
    required this.ranges,
    required this.style,
    required this.preset,
    super.key,
    this.targetValue,
    this.valueLabelBuilder,
    this.targetLabelBuilder,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final double value;
  final double min;
  final double max;
  final double? targetValue;
  final List<AppGaugeRange> ranges;
  final String Function(double value)? valueLabelBuilder;
  final String Function(double targetValue)? targetLabelBuilder;
  final AppGaugeChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(context, preset: preset);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resolvedHeight = style.height ?? chartTheme.height;
    final resolvedMin = math.min(min, max);
    final resolvedMax = math.max(min, max);
    final resolvedValue = value.clamp(resolvedMin, resolvedMax);
    final resolvedTarget = targetValue?.clamp(resolvedMin, resolvedMax);

    if (isLoading) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(
          child: CircularProgressIndicator(color: chartTheme.primaryColor),
        ),
      );
    }

    if (resolvedMax <= resolvedMin && emptyPlaceholder != null) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(child: emptyPlaceholder),
      );
    }

    return SizedBox(
      height: resolvedHeight,
      child: Padding(
        padding: style.chartPadding ?? EdgeInsets.zero,
        child: SfRadialGauge(
          axes: <RadialAxis>[
            RadialAxis(
              minimum: resolvedMin,
              maximum: resolvedMax,
              startAngle: style.startAngle,
              endAngle: style.endAngle,
              showLabels: style.showLabels,
              showTicks: style.showTicks,
              canScaleToFit: true,
              axisLabelStyle: GaugeTextStyle(
                color:
                    style.axisLabelTextStyle?.color ??
                    colorScheme.onSurfaceVariant,
                fontSize: style.axisLabelTextStyle?.fontSize ?? 12,
                fontWeight:
                    style.axisLabelTextStyle?.fontWeight ?? FontWeight.w500,
              ),
              axisLineStyle: AxisLineStyle(
                thickness: 0.18,
                thicknessUnit: GaugeSizeUnit.factor,
                color: style.showAxisLine
                    ? colorScheme.surfaceContainerHighest
                    : Colors.transparent,
              ),
              ranges: ranges
                  .map(
                    (range) => GaugeRange(
                      startValue: range.start,
                      endValue: range.end,
                      color: range.color,
                      label: range.label,
                      sizeUnit: GaugeSizeUnit.factor,
                      startWidth: 0.18,
                      endWidth: 0.18,
                    ),
                  )
                  .toList(),
              pointers: <GaugePointer>[
                if (style.showRangePointer)
                  RangePointer(
                    value: resolvedValue,
                    width: 0.18,
                    sizeUnit: GaugeSizeUnit.factor,
                    color: chartTheme.primaryColor,
                    cornerStyle: CornerStyle.bothCurve,
                    enableAnimation: true,
                    animationDuration: style.animationDuration.toDouble(),
                  ),
                if (style.showNeedle)
                  NeedlePointer(
                    value: resolvedValue,
                    enableAnimation: true,
                    animationDuration: style.animationDuration.toDouble(),
                    needleColor: chartTheme.primaryColor,
                    knobStyle: KnobStyle(color: chartTheme.primaryColor),
                    tailStyle: TailStyle(
                      color: chartTheme.primaryColor.withValues(alpha: 0.4),
                      width: 8,
                      length: 0.16,
                    ),
                  ),
                if (resolvedTarget != null && style.showTargetMarker)
                  MarkerPointer(
                    value: resolvedTarget,
                    color: colorScheme.secondary,
                    markerWidth: 18,
                    markerHeight: 18,
                  ),
              ],
              annotations: style.showValueAnnotation
                  ? <GaugeAnnotation>[
                      GaugeAnnotation(
                        angle: 90,
                        positionFactor: 0.15,
                        widget: _GaugeAnnotation(
                          valueLabel:
                              valueLabelBuilder?.call(resolvedValue) ??
                              resolvedValue.toStringAsFixed(0),
                          targetLabel: resolvedTarget == null
                              ? null
                              : targetLabelBuilder?.call(resolvedTarget) ??
                                    'Meta ${resolvedTarget.toStringAsFixed(0)}',
                          textStyle:
                              style.valueTextStyle ??
                              theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                          secondaryTextStyle: theme.textTheme.bodySmall
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ]
                  : const <GaugeAnnotation>[],
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugeAnnotation extends StatelessWidget {
  const _GaugeAnnotation({
    required this.valueLabel,
    required this.textStyle,
    this.targetLabel,
    this.secondaryTextStyle,
  });

  final String valueLabel;
  final String? targetLabel;
  final TextStyle? textStyle;
  final TextStyle? secondaryTextStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(valueLabel, style: textStyle, textAlign: TextAlign.center),
        if (targetLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              targetLabel!,
              style: secondaryTextStyle,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
