import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_grouped_column_chart_series.dart';
import 'package:colmeia/shared/widgets/charts/chart_horizontal_scroll_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Grouped column chart with one or more series per category.
///
/// Series on [AppGroupedColumnYAxis.primary] use the left Y-axis; series on
/// [AppGroupedColumnYAxis.secondary] share an opposed axis for smaller magnitudes.
class AppGroupedColumnChart<T> extends StatelessWidget {
  const AppGroupedColumnChart({
    required this.items,
    required this.xLabelBuilder,
    required this.series,
    required this.primaryAxisFormat,
    required this.secondaryAxisFormat,
    required this.height,
    required this.tooltipBuilder,
    super.key,
    this.preset = AppChartPreset.standard,
    this.animationDuration,
    this.categorySlotWidth = AppGroupedColumnChartLayout.defaultCategorySlotWidth,
    this.horizontalPadding = AppGroupedColumnChartLayout.defaultHorizontalPadding,
    this.minPlotWidth = AppGroupedColumnChartLayout.defaultMinPlotWidth,
    this.gridLineColor,
    this.horizontalScrollSemanticsHint,
    this.secondaryAxisTitle,
    this.primaryAxisTitle,
    this.horizontalScrollShellKey,
  });

  final List<T> items;
  final String Function(T item) xLabelBuilder;
  final List<AppGroupedColumnChartSeries<T>> series;
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
  final String? secondaryAxisTitle;
  final String? primaryAxisTitle;
  final Key? horizontalScrollShellKey;

  static const BorderRadius kDefaultBarBorderRadius = BorderRadius.all(
    Radius.circular(6),
  );

  static double resolvePlotWidth({
    required double availableWidth,
    required int categoryCount,
    double categorySlotWidth =
        AppGroupedColumnChartLayout.defaultCategorySlotWidth,
    double horizontalPadding =
        AppGroupedColumnChartLayout.defaultHorizontalPadding,
    double minPlotWidth = AppGroupedColumnChartLayout.defaultMinPlotWidth,
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

    final primarySeries = series
        .where((entry) => entry.yAxis == AppGroupedColumnYAxis.primary)
        .toList(growable: false);
    final secondarySeries = series
        .where((entry) => entry.yAxis == AppGroupedColumnYAxis.secondary)
        .toList(growable: false);

    final resolvedPrimaryTitle =
        primaryAxisTitle ?? primarySeries.firstOrNull?.name;
    final resolvedSecondaryTitle =
        secondaryAxisTitle ??
        secondarySeries.map((entry) => entry.name).join(' · ');

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
                  name: '_primaryAxis',
                  numberFormat: primaryAxisFormat,
                  axisLine: const AxisLine(width: 0),
                  majorGridLines: MajorGridLines(
                    color: resolvedGrid,
                    width: 1,
                  ),
                  title: AxisTitle(
                    text: resolvedPrimaryTitle ?? '',
                    textStyle: legendStyle,
                  ),
                ),
                axes: secondarySeries.isEmpty
                    ? const <ChartAxis>[]
                    : <ChartAxis>[
                        NumericAxis(
                          name: '_secondaryAxis',
                          opposedPosition: true,
                          numberFormat: secondaryAxisFormat,
                          axisLine: const AxisLine(width: 0),
                          majorGridLines: const MajorGridLines(width: 0),
                          title: AxisTitle(
                            text: resolvedSecondaryTitle,
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
                  for (final entry in series)
                    ColumnSeries<T, String>(
                      dataSource: items,
                      xValueMapper: (item, _) => xLabelBuilder(item),
                      yValueMapper: (item, _) => entry.valueMapper(item),
                      name: entry.name,
                      yAxisName: entry.yAxis ==
                              AppGroupedColumnYAxis.secondary
                          ? '_secondaryAxis'
                          : '_primaryAxis',
                      color: entry.color,
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
