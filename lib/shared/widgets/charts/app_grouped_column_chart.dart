import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_grouped_column_chart_series.dart';
import 'package:colmeia/shared/widgets/charts/chart_horizontal_scroll_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_states.dart';
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
    this.showLegend = true,
    this.isLoading = false,
    this.emptyPlaceholder,
    this.semanticsLabel,
    this.semanticsHint,
    this.semanticsValue,
    this.loadingLabel,
    this.emptyMessage,
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
  final bool showLegend;
  final bool isLoading;
  final Widget? emptyPlaceholder;
  final String? semanticsLabel;
  final String? semanticsHint;
  final String? semanticsValue;
  final String? loadingLabel;
  final String? emptyMessage;

  static const BorderRadius kDefaultBarBorderRadius = BorderRadius.all(
    Radius.circular(6),
  );

  static double loadingBlockHeight(
    AppThemeTokens tokens, {
    AppChartPreset preset = AppChartPreset.standard,
    double? styleHeight,
  }) {
    if (styleHeight != null) {
      return styleHeight;
    }
    return switch (preset) {
      AppChartPreset.compact => tokens.chartCompactHeight,
      AppChartPreset.standard => tokens.chartStandardHeight,
      AppChartPreset.explorable => tokens.chartStandardHeight,
    };
  }

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

  static bool resolveNeedsHorizontalScroll({
    required double availableWidth,
    required int categoryCount,
    double categorySlotWidth =
        AppGroupedColumnChartLayout.defaultCategorySlotWidth,
    double horizontalPadding =
        AppGroupedColumnChartLayout.defaultHorizontalPadding,
  }) {
    if (categoryCount <= 0) {
      return false;
    }
    final contentWidth =
        (categoryCount * categorySlotWidth) + horizontalPadding;
    return contentWidth > availableWidth + 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    final resolvedLoadingLabel =
        loadingLabel ?? l10n?.chartComparisonLoadingDefault;
    final resolvedEmptyMessage =
        emptyMessage ?? l10n?.chartComparisonEmptyDefault;

    if (isLoading) {
      return buildChartLoadingState(
        context: context,
        height: height,
        indicatorColor: chartTheme.primaryColor,
        label: resolvedLoadingLabel,
        variant: ChartLoadingPlaceholderVariant.timeSeries,
      );
    }

    if (items.isEmpty) {
      return buildChartEmptyState(
        context: context,
        height: height,
        message: resolvedEmptyMessage ?? '',
        placeholder: emptyPlaceholder,
        semanticsLabel: semanticsLabel,
      );
    }

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

    Widget innerChart = LayoutBuilder(
      builder: (context, constraints) {
        final plotWidth = resolvePlotWidth(
          availableWidth: constraints.maxWidth,
          categoryCount: items.length,
          categorySlotWidth: categorySlotWidth,
          horizontalPadding: horizontalPadding,
          minPlotWidth: minPlotWidth,
        );
        final needsScroll = resolveNeedsHorizontalScroll(
          availableWidth: constraints.maxWidth,
          categoryCount: items.length,
          categorySlotWidth: categorySlotWidth,
          horizontalPadding: horizontalPadding,
        );
        final chart = SizedBox(
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
                  isVisible: showLegend,
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
        );
        return SizedBox(
          height: height,
          width: constraints.maxWidth,
          child: needsScroll
              ? ChartHorizontalScrollShell(
                  chart,
                  semanticsHint: horizontalScrollSemanticsHint,
                  key: horizontalScrollShellKey,
                )
              : chart,
        );
      },
    );

    final trimmedLabel = semanticsLabel?.trim();
    if (trimmedLabel != null && trimmedLabel.isNotEmpty) {
      innerChart = Semantics(
        label: trimmedLabel,
        hint: semanticsHint,
        value: semanticsValue,
        child: innerChart,
      );
    }

    return innerChart;
  }
}
