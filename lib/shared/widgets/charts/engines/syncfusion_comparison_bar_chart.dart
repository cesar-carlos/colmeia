import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SyncfusionComparisonBarChart extends StatelessWidget {
  const SyncfusionComparisonBarChart({
    required this.points,
    required this.preset,
    required this.style,
    super.key,
    this.pointColors,
    this.dataLabels,
    this.tooltipLabels,
    this.onPointTap,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<AppChartPoint> points;
  final AppChartPreset preset;
  final AppComparisonBarChartStyle style;
  final List<Color?>? pointColors;
  final List<String?>? dataLabels;
  final List<String?>? tooltipLabels;
  final ValueChanged<int>? onPointTap;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(context, preset: preset);
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedHeight = style.height ?? chartTheme.height;
    final resolvedBarColor = style.barColor ?? chartTheme.primaryColor;

    if (isLoading) {
      return SizedBox(
        height: resolvedHeight,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (points.isEmpty && emptyPlaceholder != null) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(child: emptyPlaceholder),
      );
    }

    return SizedBox(
      height: resolvedHeight,
      child: SfCartesianChart(
        margin: style.chartPadding ?? EdgeInsets.zero,
        plotAreaBorderWidth: 0,
        plotAreaBackgroundColor: style.plotAreaBackgroundColor,
        onDataLabelRender: style.showDataLabels
            ? (args) {
                final pointIndex = args.pointIndex;
                if (pointIndex < 0) {
                  return;
                }

                final baseStyle = style.dataLabelTextStyle;
                if (baseStyle?.color != null) {
                  return;
                }

                final isInsideBarLabel =
                    style.dataLabelAlignment == ChartDataLabelAlignment.middle;
                final pointColor = pointColors != null &&
                        pointIndex < pointColors!.length
                    ? pointColors![pointIndex]
                    : resolvedBarColor;
                final textColor = isInsideBarLabel
                    ? _dataLabelTextColorForBar(pointColor ?? resolvedBarColor)
                    : colorScheme.onSurface;
                args.textStyle = (baseStyle ?? const TextStyle()).copyWith(
                  color: textColor,
                );
              }
            : null,
        onTooltipRender: tooltipLabels == null
            ? null
            : (args) {
                final pointIndex = args.pointIndex;
                final index = pointIndex?.toInt();
                if (index != null &&
                    index >= 0 &&
                    index < tooltipLabels!.length) {
                  final tooltipLabel = tooltipLabels![index];
                  if (tooltipLabel?.trim().isNotEmpty ?? false) {
                    args.text = tooltipLabel;
                  }
                }
              },
        tooltipBehavior: TooltipBehavior(enable: style.showTooltip),
        primaryXAxis: CategoryAxis(
          isVisible: style.showXAxis,
          majorGridLines: const MajorGridLines(width: 0),
          labelRotation: style.xLabelRotation.round(),
          labelStyle: style.axisLabelTextStyle,
          title: AxisTitle(
            text: style.xAxisTitle ?? '',
            textStyle: style.axisLabelTextStyle,
          ),
        ),
        primaryYAxis: NumericAxis(
          isVisible: style.showYAxis,
          axisLine: const AxisLine(width: 0),
          minimum: style.minY?.toDouble(),
          maximum: style.maxY?.toDouble(),
          interval: style.interval?.toDouble(),
          majorGridLines: MajorGridLines(
            width: style.showYGridLines ? 1 : 0,
          ),
          labelStyle: style.axisLabelTextStyle,
          title: AxisTitle(
            text: style.yAxisTitle ?? '',
            textStyle: style.axisLabelTextStyle,
          ),
          numberFormat: style.yAxisFormat,
          axisLabelFormatter: style.yAxisFormat == null
              ? null
              : (details) {
                  return ChartAxisLabel(
                    style.yAxisFormat!.format(details.value),
                    details.textStyle,
                  );
                },
        ),
        series: <CartesianSeries<AppChartPoint, String>>[
          ColumnSeries<AppChartPoint, String>(
            dataSource: points,
            xValueMapper: (point, _) => point.label,
            yValueMapper: (point, _) => point.value,
            dataLabelMapper: dataLabels == null
                ? null
                : (point, index) => index >= 0 && index < dataLabels!.length
                    ? dataLabels![index]
                    : null,
            color: pointColors == null ? resolvedBarColor : null,
            pointColorMapper: pointColors != null
                ? (point, index) => index >= 0 && index < pointColors!.length
                    ? pointColors![index] ?? resolvedBarColor
                    : resolvedBarColor
                : null,
            width: style.barWidth ?? 0.7,
            spacing: style.spacing ?? 0.2,
            borderRadius: style.barBorderRadius,
            borderColor: style.borderColor ?? Colors.transparent,
            borderWidth: style.borderWidth ?? 0,
            animationDuration:
                style.animationDuration?.inMilliseconds.toDouble() ?? 1500,
            dataLabelSettings: DataLabelSettings(
              isVisible: style.showDataLabels,
              textStyle: style.dataLabelTextStyle,
              labelAlignment: style.dataLabelAlignment,
            ),
            onPointTap: onPointTap == null
                ? null
                : (details) {
                    final index = details.pointIndex;
                    if (index != null && index >= 0 && index < points.length) {
                      onPointTap!(index);
                    }
                  },
          ),
        ],
      ),
    );
  }

  Color _dataLabelTextColorForBar(Color backgroundColor) {
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
    return brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.92)
        : Colors.black.withValues(alpha: 0.88);
  }
}
