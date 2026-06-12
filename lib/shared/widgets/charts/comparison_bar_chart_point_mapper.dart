import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/comparison_bar_plot_floor.dart';
import 'package:flutter/material.dart';

class ComparisonBarChartMappedPoints<T> {
  const ComparisonBarChartMappedPoints({
    required this.points,
    required this.hasPlotFloor,
    required this.hasExtremeSpread,
    this.pointColors,
    this.dataLabels,
    this.tooltipLabels,
  });

  final List<AppChartPoint> points;
  final List<Color?>? pointColors;
  final List<String?>? dataLabels;
  final List<String?>? tooltipLabels;
  final bool hasPlotFloor;
  final bool hasExtremeSpread;
}

ComparisonBarChartMappedPoints<T> mapComparisonBarChartPoints<T>({
  required List<T> items,
  required List<num> values,
  required String Function(T item) labelBuilder,
  required AppComparisonBarChartStyle style,
  Color? Function(T item)? colorBuilder,
  String? Function(T item, num value)? dataLabelBuilder,
  String? Function(T item, num value)? tooltipLabelBuilder,
}) {
  String formatXLabel(String raw) {
    if (style.wrapXAxisLabelsInTwoLines) {
      return formatComparisonBarXAxisLabelWrapped(
        raw,
        maxCharsPerLine: style.wrapXAxisCharsPerLine,
        maxLines: style.wrapXAxisMaxLines,
      );
    }
    final maxChars = style.xLabelMaxChars;
    if (maxChars == null) {
      return raw;
    }
    return formatComparisonBarXAxisLabelCollapsed(raw, maxChars: maxChars);
  }

  final n = items.length;
  final rawPoints = <AppChartPoint>[];
  List<Color?>? pointColorsOut;
  List<String?>? dataLabelsOut;
  List<String?>? tooltipLabelsOut;
  if (colorBuilder != null) {
    pointColorsOut = <Color?>[];
  }
  if (style.showDataLabels) {
    dataLabelsOut = <String?>[];
  }
  if (tooltipLabelBuilder != null) {
    tooltipLabelsOut = <String?>[];
  }
  for (var i = 0; i < n; i++) {
    final item = items[i];
    final value = values[i];
    rawPoints.add(
      AppChartPoint(
        label: formatXLabel(labelBuilder(item)),
        value: value,
      ),
    );
    pointColorsOut?.add(colorBuilder!(item));
    dataLabelsOut?.add(
      dataLabelBuilder?.call(item, value) ?? value.toString(),
    );
    tooltipLabelsOut?.add(
      truncateComparisonTooltipLabel(
        tooltipLabelBuilder!.call(item, value),
        style.tooltipLabelMaxChars,
      ),
    );
  }
  final points = applyComparisonBarPlotHeightFloor(
    rawPoints,
    style.minPlottedValueShareOfMax,
    strictLinearBarHeights: style.strictLinearBarHeights,
  );

  return ComparisonBarChartMappedPoints<T>(
    points: points,
    pointColors: pointColorsOut,
    dataLabels: dataLabelsOut,
    tooltipLabels: tooltipLabelsOut,
    hasPlotFloor: points.any((point) => point.plottedValue != null),
    hasExtremeSpread: comparisonBarValuesHaveExtremeSpread(values),
  );
}

/// Joins optional accessibility notices for the comparison bar chart body.
String? buildComparisonBarChartSemanticsLabel({
  required bool hasPlotFloor,
  required bool hasExtremeSpread,
  String? plotFloorAccessibilityNotice,
  String? extremeSpreadAccessibilityNotice,
  String? chartSemanticsCoordinatorNotice,
}) {
  final semanticsParts = <String>[];
  final floorNotice = plotFloorAccessibilityNotice?.trim();
  if (hasPlotFloor && floorNotice != null && floorNotice.isNotEmpty) {
    semanticsParts.add(floorNotice);
  }
  final spreadNotice = extremeSpreadAccessibilityNotice?.trim();
  if (hasExtremeSpread && spreadNotice != null && spreadNotice.isNotEmpty) {
    semanticsParts.add(spreadNotice);
  }
  final coordinatorExtra = chartSemanticsCoordinatorNotice?.trim();
  if (coordinatorExtra != null && coordinatorExtra.isNotEmpty) {
    semanticsParts.add(coordinatorExtra);
  }
  if (semanticsParts.isEmpty) {
    return null;
  }
  return semanticsParts.join(' ');
}

String? truncateComparisonTooltipLabel(String? raw, int? maxChars) {
  if (raw == null) {
    return null;
  }
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return raw;
  }
  final max = maxChars;
  if (max == null || trimmed.length <= max) {
    return raw;
  }
  final cap = max < 4 ? 4 : max;
  return '${trimmed.substring(0, cap)}\u2026';
}
