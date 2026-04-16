import 'dart:math' as math;

import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/chart_horizontal_scroll_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_states.dart';
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
      return buildChartLoadingState(
        context: context,
        height: resolvedHeight,
        indicatorColor: chartTheme.primaryColor,
        label: style.loadingLabel ?? 'Carregando comparativo...',
      );
    }

    if (points.isEmpty) {
      return buildChartEmptyState(
        context: context,
        height: resolvedHeight,
        message: style.emptyMessage ?? 'Sem dados comparativos para exibir.',
        placeholder: emptyPlaceholder,
      );
    }

    // --- bar gap / spacing resolution ------------------------------------
    // barGap (absolute px) takes precedence over the relative spacing ratio.
    final resolvedBarWidth = style.barWidth ?? _kDefaultBarWidthRatio;

    double spacingForSlotWidth(double slotWidth) {
      final gap = style.barGap;
      if (gap == null) {
        return style.spacing ?? _kDefaultSpacingRatio;
      }
      final ratio = gap / math.max(slotWidth, 1);
      return ratio.clamp(0.0, 1.0 - resolvedBarWidth);
    }

    // --- auto X-label rotation -------------------------------------------
    // When autoRotateXLabels is true, estimate whether labels overflow the
    // bar visual width and apply 45° rotation automatically if needed.
    double xLabelRotationForSlotWidth(double slotWidth) {
      if (style.wrapXAxisLabelsInTwoLines || points.isEmpty) {
        return style.xLabelRotation;
      }
      if (!style.autoRotateXLabels) {
        return style.xLabelRotation;
      }
      final maxLen = points.map((p) => p.label.length).reduce(math.max);
      const estimatedCharWidthPx = 6.5;
      final labelWidthEstimate = maxLen * estimatedCharWidthPx;
      final barVisualWidth = slotWidth * resolvedBarWidth;
      return labelWidthEstimate > barVisualWidth ? 45.0 : style.xLabelRotation;
    }

    // --- build the inner Syncfusion chart --------------------------------
    Widget buildChart(
      BuildContext chartContext,
      double slotWidth, {
      required bool yAxisLabelsVisible,
      required bool xAxisLabelsVisible,
      required bool yAxisGridVisible,
      required bool enableInteraction,
    }) {
      final resolvedSpacing = spacingForSlotWidth(slotWidth);
      final resolvedRotation = xLabelRotationForSlotWidth(slotWidth);
      return SfCartesianChart(
        margin: _comparisonBarChartMargin(chartContext, style),
        plotAreaBorderWidth: 0,
        plotAreaBackgroundColor: style.plotAreaBackgroundColor,
        onDataLabelRender: style.showDataLabels && enableInteraction
            ? (args) {
                final pointIndex = args.pointIndex;
                if (pointIndex < 0) {
                  return;
                }

                final baseStyle = style.dataLabelTextStyle;
                if (baseStyle?.color != null) {
                  return;
                }

                final isInsideBarLabel = switch (style.dataLabelAlignment) {
                  ChartDataLabelAlignment.middle ||
                  ChartDataLabelAlignment.top ||
                  ChartDataLabelAlignment.bottom => true,
                  ChartDataLabelAlignment.auto ||
                  ChartDataLabelAlignment.outer => false,
                };
                final pointColor =
                    pointColors != null && pointIndex < pointColors!.length
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
        onTooltipRender: enableInteraction && tooltipLabels != null
            ? (args) {
                final index = args.pointIndex?.toInt();
                if (index != null &&
                    index >= 0 &&
                    index < tooltipLabels!.length) {
                  final tooltipLabel = tooltipLabels![index];
                  if (tooltipLabel?.trim().isNotEmpty ?? false) {
                    args.text = tooltipLabel;
                  }
                }
              }
            : null,
        tooltipBehavior: TooltipBehavior(
          enable: enableInteraction && style.showTooltip,
        ),
        primaryXAxis: CategoryAxis(
          isVisible: style.showXAxis && xAxisLabelsVisible,
          majorGridLines: const MajorGridLines(width: 0),
          labelRotation: resolvedRotation.round(),
          labelStyle: style.axisLabelTextStyle,
          title: AxisTitle(
            text: xAxisLabelsVisible ? (style.xAxisTitle ?? '') : '',
            textStyle: style.axisLabelTextStyle,
          ),
        ),
        primaryYAxis: NumericAxis(
          isVisible: style.showYAxis,
          rangePadding: _needsOuterDataLabelHeadroom(style)
              ? ChartRangePadding.additionalEnd
              : ChartRangePadding.auto,
          axisLine: const AxisLine(width: 0),
          // Column charts must anchor at zero when [style.minY] is unset.
          // Otherwise Syncfusion picks a data-relative minimum (often the
          // smallest value), which makes the minimum bar height ~0 and looks
          // like a missing category even though the data label is non-zero.
          minimum: style.minY?.toDouble() ?? 0,
          maximum: style.maxY?.toDouble(),
          interval: style.interval?.toDouble(),
          majorGridLines: MajorGridLines(
            width: yAxisGridVisible && style.showYGridLines ? 1 : 0,
          ),
          labelStyle: style.axisLabelTextStyle,
          title: AxisTitle(
            text: yAxisLabelsVisible ? (style.yAxisTitle ?? '') : '',
            textStyle: style.axisLabelTextStyle,
          ),
          numberFormat: style.yAxisFormat,
          axisLabelFormatter: !yAxisLabelsVisible
              ? (details) => ChartAxisLabel('', details.textStyle)
              : style.yAxisFormat == null
              ? null
              : (details) => ChartAxisLabel(
                  style.yAxisFormat!.format(details.value),
                  details.textStyle,
                ),
        ),
        series: <CartesianSeries<AppChartPoint, String>>[
          ColumnSeries<AppChartPoint, String>(
            dataSource: points,
            xValueMapper: (point, _) => point.label,
            yValueMapper: (point, _) => point.plottedValue ?? point.value,
            dataLabelMapper: dataLabels == null
                ? null
                : (point, index) => index >= 0 && index < dataLabels!.length
                      ? dataLabels![index]
                      : null,
            color: enableInteraction
                ? (pointColors == null ? resolvedBarColor : null)
                : resolvedBarColor.withValues(alpha: 0),
            pointColorMapper: enableInteraction && pointColors != null
                ? (point, index) => index >= 0 && index < pointColors!.length
                      ? pointColors![index] ?? resolvedBarColor
                      : resolvedBarColor
                : null,
            width: resolvedBarWidth,
            spacing: resolvedSpacing,
            borderRadius: style.barBorderRadius,
            borderColor: style.borderColor ?? Colors.transparent,
            borderWidth: style.borderWidth ?? 0,
            animationDuration:
                style.animationDuration?.inMilliseconds.toDouble() ?? 1500,
            dataLabelSettings: DataLabelSettings(
              isVisible: style.showDataLabels && enableInteraction,
              textStyle: style.dataLabelTextStyle,
              labelAlignment: style.dataLabelAlignment,
              offset: style.dataLabelOffset ?? Offset.zero,
            ),
            onPointTap: onPointTap == null || !enableInteraction
                ? null
                : (details) {
                    final index = details.pointIndex;
                    if (index != null && index >= 0 && index < points.length) {
                      onPointTap!(index);
                    }
                  },
          ),
        ],
      );
    }

    final minBarWidth = style.minBarWidth ?? _kDefaultMinBarWidth;

    return SizedBox(
      height: resolvedHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mediaWidth = MediaQuery.sizeOf(context).width;
          var layoutWidth =
              constraints.hasBoundedWidth &&
                  constraints.maxWidth.isFinite &&
                  constraints.maxWidth > 0
              ? constraints.maxWidth
              : mediaWidth;
          if (!layoutWidth.isFinite || layoutWidth <= 0) {
            layoutWidth = minBarWidth * points.length;
          }

          final n = points.length;

          Widget sizedBarChart(double width, double slotW, double chartHeight) {
            return SizedBox(
              width: width,
              height: chartHeight,
              child: buildChart(
                context,
                slotW,
                yAxisLabelsVisible: true,
                xAxisLabelsVisible: true,
                yAxisGridVisible: true,
                enableInteraction: true,
              ),
            );
          }

          if (!style.enableAutoScroll) {
            final slotW = layoutWidth / n;
            return sizedBarChart(layoutWidth, slotW, resolvedHeight);
          }

          final requiredFull = math.max(layoutWidth, minBarWidth * n);
          final needsScroll = requiredFull > layoutWidth;

          if (!needsScroll) {
            final slotW = layoutWidth / n;
            return sizedBarChart(layoutWidth, slotW, resolvedHeight);
          }

          const scrollSlot = kChartHorizontalScrollBottomTrackSlot;
          final chartBodyHeight = resolvedHeight - scrollSlot;

          final sticky = style.stickyPrimaryYAxisWhileScrolling;
          final stickyW = sticky ? style.stickyPrimaryYAxisWidth : 0.0;
          final plotViewport = (layoutWidth - stickyW)
              .clamp(1, double.infinity)
              .toDouble();
          final requiredPlot = math.max(plotViewport, minBarWidth * n);
          final slotW = requiredPlot / n;

          if (!sticky) {
            return ChartHorizontalScrollShell(
              sizedBarChart(requiredPlot, slotW, chartBodyHeight),
              bottomTrackSlot: scrollSlot,
              showFade: style.showScrollFade,
              semanticsHint: style.horizontalScrollSemanticsHint,
            );
          }

          final stripChart = SizedBox(
            width: stickyW,
            height: resolvedHeight,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: chartBodyHeight,
                child: buildChart(
                  context,
                  slotW,
                  yAxisLabelsVisible: true,
                  xAxisLabelsVisible: false,
                  yAxisGridVisible: false,
                  enableInteraction: false,
                ),
              ),
            ),
          );

          final plotInner = SizedBox(
            width: requiredPlot,
            height: chartBodyHeight,
            child: buildChart(
              context,
              slotW,
              yAxisLabelsVisible: false,
              xAxisLabelsVisible: true,
              yAxisGridVisible: true,
              enableInteraction: true,
            ),
          );

          return SizedBox(
            height: resolvedHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                stripChart,
                Expanded(
                  child: ChartHorizontalScrollShell(
                    plotInner,
                    bottomTrackSlot: scrollSlot,
                    showFade: style.showScrollFade,
                    semanticsHint: style.horizontalScrollSemanticsHint,
                  ),
                ),
              ],
            ),
          );
        },
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

/// Outer/auto data labels sit above column tops; a positive label offset moves
/// them further up. Reserve extra chart margin at the top so labels are not
/// clipped by the plot bounds.
EdgeInsets _comparisonBarChartMargin(
  BuildContext context,
  AppComparisonBarChartStyle style,
) {
  final base = style.chartPadding ?? EdgeInsets.zero;
  if (!_needsOuterDataLabelHeadroom(style)) {
    return base;
  }
  final theme = Theme.of(context);
  final tokens = theme.extension<AppThemeTokens>();
  final bodyStyle =
      theme.textTheme.bodySmall ??
      theme.textTheme.bodyMedium ??
      theme.textTheme.bodyLarge;
  final fontSize = bodyStyle?.fontSize ?? 12.0;
  final heightFactor = bodyStyle?.height ?? 1.25;
  final estimatedLineHeight = (fontSize * heightFactor).clamp(14.0, 32.0);
  final extraGap = tokens?.gapSm ?? 8.0;
  final lift = style.dataLabelOffset?.dy ?? 0;
  final headroomBoost = (tokens?.contentSpacing ?? 16.0) * 2;
  final minTop = estimatedLineHeight + lift.abs() + extraGap + headroomBoost;
  final top = math.max(base.top, minTop);
  return EdgeInsets.fromLTRB(base.left, top, base.right, base.bottom);
}

bool _needsOuterDataLabelHeadroom(AppComparisonBarChartStyle style) {
  if (!style.showDataLabels) {
    return false;
  }
  return switch (style.dataLabelAlignment) {
    ChartDataLabelAlignment.middle ||
    ChartDataLabelAlignment.top ||
    ChartDataLabelAlignment.bottom => false,
    ChartDataLabelAlignment.auto || ChartDataLabelAlignment.outer => true,
  };
}

// Minimum pixel width reserved per bar slot (bar + gap).
const double _kDefaultMinBarWidth = 72;

// Default bar width ratio (fraction of bar slot occupied by the bar itself).
const double _kDefaultBarWidthRatio = 0.7;

// Default spacing ratio between bars when barGap is not specified.
const double _kDefaultSpacingRatio = 0.2;
