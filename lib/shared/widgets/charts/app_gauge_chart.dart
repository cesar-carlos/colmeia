import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_gauge_chart.dart';
import 'package:flutter/material.dart';

class AppGaugeRange {
  const AppGaugeRange({
    required this.start,
    required this.end,
    required this.color,
    this.label,
  });

  final double start;
  final double end;
  final Color color;
  final String? label;
}

class AppGaugeTapEvent {
  const AppGaugeTapEvent({
    required this.value,
    required this.min,
    required this.max,
    required this.normalizedValue,
    required this.ranges,
    this.targetValue,
  });

  final double value;
  final double min;
  final double max;
  final double? targetValue;
  final double normalizedValue;
  final List<AppGaugeRange> ranges;
}

class AppGaugeChartStyle {
  const AppGaugeChartStyle({
    this.height,
    this.chartPadding,
    this.startAngle = 150,
    this.endAngle = 30,
    this.showTicks = true,
    this.showLabels = true,
    this.showAxisLine = true,
    this.showValueAnnotation = true,
    this.showNeedle = true,
    this.showRangePointer = true,
    this.showTargetMarker = true,
    this.animationDuration = 900,
    this.axisLabelTextStyle,
    this.valueTextStyle,
  });

  final double? height;
  final EdgeInsets? chartPadding;
  final double startAngle;
  final double endAngle;
  final bool showTicks;
  final bool showLabels;
  final bool showAxisLine;
  final bool showValueAnnotation;
  final bool showNeedle;
  final bool showRangePointer;
  final bool showTargetMarker;
  final int animationDuration;
  final TextStyle? axisLabelTextStyle;
  final TextStyle? valueTextStyle;
}

class AppGaugeChart extends StatelessWidget {
  const AppGaugeChart({
    required this.value,
    super.key,
    this.title,
    this.subtitle,
    this.titleTrailing,
    this.belowSubtitle,
    this.min = 0,
    this.max = 100,
    this.targetValue,
    this.ranges = const <AppGaugeRange>[],
    this.valueLabelBuilder,
    this.targetLabelBuilder,
    this.style = const AppGaugeChartStyle(),
    this.preset = AppChartPreset.standard,
    this.isLoading = false,
    this.emptyPlaceholder,
    this.onTap,
    this.onTapEvent,
  });

  final double value;
  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;
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
  final VoidCallback? onTap;
  final ValueChanged<AppGaugeTapEvent>? onTapEvent;

  @override
  Widget build(BuildContext context) {
    final resolvedMin = min < max ? min : max;
    final resolvedMax = min > max ? min : max;
    final safeRange = resolvedMax - resolvedMin;
    final normalizedValue = safeRange <= 0
        ? 0.0
        : (value.clamp(resolvedMin, resolvedMax) - resolvedMin) / safeRange;

    void handleTap() {
      onTap?.call();
      onTapEvent?.call(
        AppGaugeTapEvent(
          value: value.clamp(resolvedMin, resolvedMax),
          min: resolvedMin,
          max: resolvedMax,
          targetValue: targetValue?.clamp(resolvedMin, resolvedMax),
          normalizedValue: normalizedValue,
          ranges: ranges,
        ),
      );
    }

    final innerChart = SyncfusionGaugeChart(
      value: value,
      min: min,
      max: max,
      targetValue: targetValue,
      ranges: ranges,
      valueLabelBuilder: valueLabelBuilder,
      targetLabelBuilder: targetLabelBuilder,
      style: style,
      preset: preset,
      isLoading: isLoading,
      emptyPlaceholder: emptyPlaceholder,
    );

    final interactiveChart =
        onTap == null && onTapEvent == null
            ? innerChart
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: handleTap,
                child: innerChart,
              );

    if (title == null) {
      return interactiveChart;
    }

    return AppChartShell(
      title: title!,
      subtitle: subtitle,
      titleTrailing: titleTrailing,
      belowSubtitle: belowSubtitle,
      child: interactiveChart,
    );
  }
}
