import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/chart_horizontal_scroll_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Three grouped column series per category: [salesValue] uses the primary
/// (left) Y-axis; [profitValue] and [costValue] share a secondary opposed axis
/// so smaller magnitudes stay readable when sales dominates.
class AppGroupedColumnChart<T> extends StatelessWidget {
  const AppGroupedColumnChart({
    required this.items,
    required this.xLabelBuilder,
    required this.salesValue,
    required this.profitValue,
    required this.costValue,
    required this.salesLabel,
    required this.profitLabel,
    required this.costLabel,
    required this.salesColor,
    required this.profitColor,
    required this.costColor,
    required this.primaryAxisFormat,
    required this.secondaryAxisFormat,
    required this.height,
    required this.tooltipBuilder,
    super.key,
    this.preset = AppChartPreset.standard,
    this.animationDuration,
    this.categorySlotWidth = 72,
    this.horizontalPadding = 24,
    this.minPlotWidth = 560,
    this.gridLineColor,
    this.horizontalScrollSemanticsHint,
    this.secondaryAxisTitle,
    this.primaryAxisTitle,
    this.horizontalScrollShellKey,
  });

  final List<T> items;
  final String Function(T item) xLabelBuilder;
  final double Function(T item) salesValue;
  final double Function(T item) profitValue;
  final double Function(T item) costValue;

  final String salesLabel;
  final String profitLabel;
  final String costLabel;

  final Color salesColor;
  final Color profitColor;
  final Color costColor;

  final NumberFormat primaryAxisFormat;
  final NumberFormat secondaryAxisFormat;

  final double height;

  final ChartWidgetBuilder<dynamic, dynamic> tooltipBuilder;

  final AppChartPreset preset;

  final Duration? animationDuration;

  final double categorySlotWidth;
  final double horizontalPadding;
  final double minPlotWidth;

  final Color? gridLineColor;

  final String? horizontalScrollSemanticsHint;

  /// Shown on the secondary axis (defaults to "$profitLabel · $costLabel").
  final String? secondaryAxisTitle;

  /// Optional short label on the primary axis (often same as [salesLabel]).
  final String? primaryAxisTitle;

  /// Optional stable key for tests / semantics targeting (wraps [ChartHorizontalScrollShell]).
  final Key? horizontalScrollShellKey;

  static const BorderRadius kDefaultBarBorderRadius = BorderRadius.all(
    Radius.circular(6),
  );

  static double resolvePlotWidth({
    required double availableWidth,
    required int categoryCount,
    double categorySlotWidth = 72,
    double horizontalPadding = 24,
    double minPlotWidth = 560,
  }) {
    if (categoryCount <= 0) {
      return availableWidth.clamp(minPlotWidth, double.infinity);
    }
    final contentWidth =
        (categoryCount * categorySlotWidth) + horizontalPadding;
    return (availableWidth > contentWidth ? availableWidth : contentWidth)
        .clamp(minPlotWidth, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(context, preset: preset);
    final theme = Theme.of(context);
    final legendStyle = theme.textTheme.bodySmall;
    final resolvedGrid =
        gridLineColor ??
        theme.colorScheme.outlineVariant.withValues(alpha: 0.35);
    final animMs = resolveChartAnimationDurationMs(
      context: context,
      styleDuration: animationDuration,
      defaultMs: AppChartEngineAnimationDefaults.cartesianSeriesMs,
    );

    final secondaryTitle = secondaryAxisTitle ?? '$profitLabel · $costLabel';
    final primaryTitle = primaryAxisTitle ?? salesLabel;

    return LayoutBuilder(
      builder: (context, constraints) {
        final plotWidth = resolvePlotWidth(
          availableWidth: constraints.maxWidth,
          categoryCount: items.length,
          categorySlotWidth: categorySlotWidth,
          horizontalPadding: horizontalPadding,
          minPlotWidth: minPlotWidth,
        );
        return SizedBox(
          height: height,
          width: constraints.maxWidth,
          child: ChartHorizontalScrollShell(
            SizedBox(
              width: plotWidth,
              height: height,
              child: SfCartesianChart(
                margin: EdgeInsets.zero,
                plotAreaBorderWidth: 0,
                onTooltipRender: buildSanitizingTooltipRenderer(),
                tooltipBehavior: buildChartTooltipBehavior(
                  context,
                  enable: true,
                  shared: true,
                  builder: tooltipBuilder,
                ),
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  overflowMode: LegendItemOverflowMode.wrap,
                  textStyle: legendStyle,
                ),
                primaryXAxis: const CategoryAxis(
                  majorGridLines: MajorGridLines(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  name: '_salesAxis',
                  numberFormat: primaryAxisFormat,
                  axisLine: const AxisLine(width: 0),
                  majorGridLines: MajorGridLines(
                    color: resolvedGrid,
                    width: 1,
                  ),
                  title: AxisTitle(
                    text: primaryTitle,
                    textStyle: legendStyle,
                  ),
                ),
                axes: <ChartAxis>[
                  NumericAxis(
                    name: '_profitCostAxis',
                    opposedPosition: true,
                    numberFormat: secondaryAxisFormat,
                    axisLine: const AxisLine(width: 0),
                    majorGridLines: const MajorGridLines(width: 0),
                    title: AxisTitle(
                      text: secondaryTitle,
                      textStyle: legendStyle,
                    ),
                  ),
                ],
                zoomPanBehavior: ZoomPanBehavior(
                  enablePinching: chartTheme.enableSelectionZooming,
                  enablePanning: chartTheme.enableSelectionZooming,
                  enableSelectionZooming: chartTheme.enableSelectionZooming,
                ),
                series: <CartesianSeries<T, String>>[
                  ColumnSeries<T, String>(
                    dataSource: items,
                    xValueMapper: (item, _) => xLabelBuilder(item),
                    yValueMapper: (item, _) => salesValue(item),
                    name: salesLabel,
                    yAxisName: '_salesAxis',
                    color: salesColor,
                    borderRadius: kDefaultBarBorderRadius,
                    width: AppChartEngineCartesianBarGeometryDefaults
                        .columnWidthRatio,
                    spacing: AppChartEngineCartesianBarGeometryDefaults
                        .columnSpacingRatio,
                    animationDuration: animMs,
                  ),
                  ColumnSeries<T, String>(
                    dataSource: items,
                    xValueMapper: (item, _) => xLabelBuilder(item),
                    yValueMapper: (item, _) => profitValue(item),
                    name: profitLabel,
                    yAxisName: '_profitCostAxis',
                    color: profitColor,
                    borderRadius: kDefaultBarBorderRadius,
                    width: AppChartEngineCartesianBarGeometryDefaults
                        .columnWidthRatio,
                    spacing: AppChartEngineCartesianBarGeometryDefaults
                        .columnSpacingRatio,
                    animationDuration: animMs,
                  ),
                  ColumnSeries<T, String>(
                    dataSource: items,
                    xValueMapper: (item, _) => xLabelBuilder(item),
                    yValueMapper: (item, _) => costValue(item),
                    name: costLabel,
                    yAxisName: '_profitCostAxis',
                    color: costColor,
                    borderRadius: kDefaultBarBorderRadius,
                    width: AppChartEngineCartesianBarGeometryDefaults
                        .columnWidthRatio,
                    spacing: AppChartEngineCartesianBarGeometryDefaults
                        .columnSpacingRatio,
                    animationDuration: animMs,
                  ),
                ],
              ),
            ),
            semanticsHint: horizontalScrollSemanticsHint,
            key: horizontalScrollShellKey,
          ),
        );
      },
    );
  }
}
