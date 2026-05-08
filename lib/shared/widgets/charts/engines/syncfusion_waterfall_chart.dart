import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_waterfall_chart.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_states.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SyncfusionWaterfallChart<T> extends StatelessWidget {
  const SyncfusionWaterfallChart({
    required this.items,
    required this.labelBuilder,
    required this.valueBuilder,
    required this.style,
    required this.preset,
    super.key,
    this.isIntermediateSum,
    this.isTotalSum,
    this.dataLabels,
    this.tooltipLabels,
    this.onPointTap,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<T> items;
  final String Function(T item) labelBuilder;
  final num Function(T item) valueBuilder;
  final bool Function(T item)? isIntermediateSum;
  final bool Function(T item)? isTotalSum;
  final List<String?>? dataLabels;
  final List<String?>? tooltipLabels;
  final ValueChanged<int>? onPointTap;
  final AppWaterfallChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(context, preset: preset);
    final colors = Theme.of(context).appColors;
    final resolvedHeight = style.height ?? chartTheme.height;

    if (isLoading) {
      return buildChartLoadingState(
        context: context,
        height: resolvedHeight,
        indicatorColor: chartTheme.primaryColor,
        label: 'Carregando variacoes...',
      );
    }

    if (items.isEmpty) {
      return buildChartEmptyState(
        context: context,
        height: resolvedHeight,
        message: 'Sem variacoes disponiveis para exibir.',
        placeholder: emptyPlaceholder,
      );
    }

    return SizedBox(
      height: resolvedHeight,
      child: SfCartesianChart(
        margin: style.chartPadding ?? EdgeInsets.zero,
        plotAreaBorderWidth: 0,
        selectionType: style.enableTapHighlight
            ? SelectionType.point
            : SelectionType.series,
        onTooltipRender: buildSanitizingTooltipRenderer(
          bodyResolver: tooltipLabels == null
              ? null
              : (args) {
                  final index = args.pointIndex?.toInt();
                  if (index == null ||
                      index < 0 ||
                      index >= tooltipLabels!.length) {
                    return null;
                  }
                  return tooltipLabels![index];
                },
        ),
        tooltipBehavior: buildChartTooltipBehavior(
          context,
          enable: style.showTooltip,
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
            color: colors.outlineVariant.withValues(alpha: 0.35),
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
        series: <CartesianSeries<T, String>>[
          WaterfallSeries<T, String>(
            dataSource: items,
            xValueMapper: (item, _) => labelBuilder(item),
            yValueMapper: (item, _) => valueBuilder(item),
            intermediateSumPredicate: isIntermediateSum == null
                ? null
                : (item, _) => isIntermediateSum!(item),
            totalSumPredicate: isTotalSum == null
                ? null
                : (item, _) => isTotalSum!(item),
            width: style.barWidth ?? 0.7,
            spacing: style.spacing ?? 0.2,
            color: style.positiveColor ?? chartTheme.primaryColor,
            negativePointsColor: style.negativeColor ?? colors.error,
            intermediateSumColor:
                style.intermediateSumColor ?? chartTheme.paletteColor(1),
            totalSumColor: style.totalSumColor ?? chartTheme.paletteColor(2),
            connectorLineSettings: WaterfallConnectorLineSettings(
              color:
                  style.connectorLineColor ??
                  colors.outlineVariant.withValues(alpha: 0.8),
              width: 1.5,
            ),
            animationDuration: resolveChartAnimationDurationMs(
              context: context,
              styleDuration: style.animationDuration,
              defaultMs: AppChartEngineAnimationDefaults.cartesianSeriesMs,
            ),
            selectionBehavior: style.enableTapHighlight
                ? SelectionBehavior(
                    enable: true,
                    unselectedOpacity: style.tapHighlightDimmedOpacity
                        .clamp(0, 1)
                        .toDouble(),
                  )
                : null,
            dataLabelMapper: dataLabels == null
                ? null
                : (item, index) => dataLabels![index],
            dataLabelSettings: DataLabelSettings(
              isVisible: style.showDataLabels,
              textStyle: style.dataLabelTextStyle,
            ),
            onPointTap: onPointTap == null
                ? null
                : (details) {
                    final index = details.pointIndex;
                    if (index != null && index >= 0 && index < items.length) {
                      onPointTap!(index);
                    }
                  },
          ),
        ],
      ),
    );
  }
}
