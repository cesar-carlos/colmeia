import 'dart:math' as math;

import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/chart_horizontal_scroll_shell.dart';
import 'package:colmeia/shared/widgets/charts/chart_pan_footnote_column.dart';
import 'package:colmeia/shared/widgets/charts/comparison_bar_chart_margin.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
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
    this.resolvedLoadingLabel,
    this.resolvedEmptyMessage,
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

  /// Falls back to [AppComparisonBarChartStyle.loadingLabel], then English.
  final String? resolvedLoadingLabel;

  /// Falls back to [AppComparisonBarChartStyle.emptyMessage], then English.
  final String? resolvedEmptyMessage;

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
        label:
            resolvedLoadingLabel ??
            style.loadingLabel ??
            'Loading comparison chart…',
      );
    }

    if (points.isEmpty) {
      return buildChartEmptyState(
        context: context,
        height: resolvedHeight,
        message:
            resolvedEmptyMessage ??
            style.emptyMessage ??
            'Nothing to compare right now.',
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
      required bool enableCategoryViewportPan,
    }) {
      final resolvedSpacing = spacingForSlotWidth(slotWidth);
      final resolvedRotation = xLabelRotationForSlotWidth(slotWidth);
      final delta = style.categoryAutoScrollingDelta;
      final useCategoryAxisPan =
          enableCategoryViewportPan &&
          enableInteraction &&
          delta != null &&
          delta > 0;
      final tooltipLabelList = tooltipLabels;
      return SfCartesianChart(
        margin: resolveComparisonBarChartMargin(
          chartContext,
          showDataLabels: style.showDataLabels,
          dataLabelAlignment: style.dataLabelAlignment,
          dataLabelOffset: style.dataLabelOffset,
          chartPadding: style.chartPadding,
          outerDataLabelTopReserve: style.outerDataLabelTopReserve,
        ),
        plotAreaBorderWidth: 0,
        plotAreaBackgroundColor: style.plotAreaBackgroundColor,
        zoomPanBehavior: useCategoryAxisPan
            ? ZoomPanBehavior(
                enablePanning: true,
                zoomMode: ZoomMode.x,
              )
            : null,
        onDataLabelRender: style.showDataLabels && enableInteraction
            ? (args) {
                final pointIndex = args.pointIndex;
                if (pointIndex < 0) {
                  return;
                }

                if (dataLabels != null &&
                    pointIndex < dataLabels!.length) {
                  final expected = dataLabels![pointIndex];
                  final text = args.text;
                  if (expected != null &&
                      expected.isNotEmpty &&
                      text != null &&
                      text.isNotEmpty &&
                      text != expected) {
                    args.text = '';
                    return;
                  }
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
        onTooltipRender: enableInteraction
            ? buildSanitizingTooltipRenderer(
                bodyResolver: tooltipLabelList == null
                    ? null
                    : (args) {
                        final index = args.pointIndex?.toInt();
                        if (index == null ||
                            index < 0 ||
                            index >= tooltipLabelList.length) {
                          return null;
                        }
                        return tooltipLabelList[index];
                      },
              )
            : null,
        tooltipBehavior: buildChartTooltipBehavior(
          context,
          enable: enableInteraction && style.showTooltip,
          canShowMarker: tooltipLabelList == null,
          builder: tooltipLabelList == null
              ? null
              : (data, point, series, pointIndex, seriesIndex) {
                  final labels = tooltipLabelList;
                  if (pointIndex < 0 || pointIndex >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  final text = labels[pointIndex];
                  if (text == null || text.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final colorScheme = Theme.of(chartContext).colorScheme;
                  return Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      text,
                      style: TextStyle(
                        color: colorScheme.onInverseSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      softWrap: true,
                      textAlign: TextAlign.start,
                    ),
                  );
                },
        ),
        primaryXAxis: CategoryAxis(
          isVisible: style.showXAxis && xAxisLabelsVisible,
          majorGridLines: const MajorGridLines(width: 0),
          labelRotation: resolvedRotation.round(),
          labelStyle: style.axisLabelTextStyle,
          labelIntersectAction: AxisLabelIntersectAction.none,
          title: AxisTitle(
            text: xAxisLabelsVisible ? (style.xAxisTitle ?? '') : '',
            textStyle: style.axisLabelTextStyle,
          ),
          autoScrollingDelta: useCategoryAxisPan ? delta : null,
          autoScrollingMode: style.categoryAutoScrollingMode,
        ),
        primaryYAxis: NumericAxis(
          isVisible: style.showYAxis,
          rangePadding: style.yAxisRangePadding ??
              (comparisonBarChartNeedsOuterDataLabelHeadroom(
                showDataLabels: style.showDataLabels,
                dataLabelAlignment: style.dataLabelAlignment,
              )
              // additionalEnd stacks with chart margin top; normal keeps labels
              // readable without a second tall empty band inside the plot.
              ? ChartRangePadding.normal
              : ChartRangePadding.auto),
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
        selectionType: style.enableTapHighlight && enableInteraction
            ? SelectionType.point
            : SelectionType.series,
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
            animationDuration: resolveChartAnimationDurationMs(
              context: context,
              styleDuration: style.animationDuration,
              defaultMs: AppChartEngineAnimationDefaults.cartesianSeriesMs,
            ),
            selectionBehavior: style.enableTapHighlight && enableInteraction
                ? SelectionBehavior(
                    enable: true,
                    unselectedOpacity:
                        style.tapHighlightDimmedOpacity.clamp(0, 1).toDouble(),
                  )
                : null,
            dataLabelSettings: DataLabelSettings(
              isVisible: style.showDataLabels && enableInteraction,
              textStyle: style.dataLabelTextStyle,
              labelAlignment: style.dataLabelAlignment,
              offset: style.dataLabelOffset ?? Offset.zero,
              color: style.dataLabelBackgroundColor,
              margin: style.dataLabelBackgroundColor != null
                  ? const EdgeInsets.symmetric(horizontal: 6, vertical: 8)
                  : const EdgeInsets.all(5),
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
          final delta = style.categoryAutoScrollingDelta;
          final crowded = n > 1 && (layoutWidth / n) < minBarWidth;
          final useCategoryViewportPan =
              !style.enableAutoScroll &&
              delta != null &&
              delta > 0 &&
              n > delta &&
              crowded;
          final slotDenom = useCategoryViewportPan ? math.min(n, delta) : n;
          final footRaw = style.categoryViewportFootnote?.trim();
          final showPanFootnote =
              useCategoryViewportPan && footRaw != null && footRaw.isNotEmpty;

          Widget sizedBarChart(
            double width,
            double slotW,
            double chartHeight, {
            required bool categoryViewportPan,
          }) {
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
                enableCategoryViewportPan: categoryViewportPan,
              ),
            );
          }

          if (!style.enableAutoScroll) {
            final slotW = layoutWidth / slotDenom;
            final footText = footRaw ?? '';
            // Pan footnote layout matches [SyncfusionComboChart] (shared
            // [ChartPanFootnoteColumn]).
            var chart = showPanFootnote
                ? ChartPanFootnoteColumn(
                    plot: SizedBox(
                      width: layoutWidth,
                      child: buildChart(
                        context,
                        slotW,
                        yAxisLabelsVisible: true,
                        xAxisLabelsVisible: true,
                        yAxisGridVisible: true,
                        enableInteraction: true,
                        enableCategoryViewportPan: useCategoryViewportPan,
                      ),
                    ),
                    footnoteText: footText,
                  )
                : sizedBarChart(
                    layoutWidth,
                    slotW,
                    resolvedHeight,
                    categoryViewportPan: useCategoryViewportPan,
                  );
            if (useCategoryViewportPan) {
              final panLabel = style.categoryViewportPanSemanticsLabel?.trim();
              final hint = style.horizontalScrollSemanticsHint?.trim();
              if ((panLabel != null && panLabel.isNotEmpty) ||
                  (hint != null && hint.isNotEmpty)) {
                chart = Semantics(
                  label: (panLabel != null && panLabel.isNotEmpty)
                      ? panLabel
                      : null,
                  hint: (hint != null && hint.isNotEmpty) ? hint : null,
                  child: chart,
                );
              }
            }
            return chart;
          }

          final requiredFull = math.max(layoutWidth, minBarWidth * n);
          final needsScroll = requiredFull > layoutWidth;

          if (!needsScroll) {
            final slotW = layoutWidth / n;
            return sizedBarChart(
              layoutWidth,
              slotW,
              resolvedHeight,
              categoryViewportPan: false,
            );
          }

          // Slot is scaled by [TextScaler] inside the shell — deduct the
          // resolved height here so accessible text scales don't overflow.
          final scrollSlot =
              chartHorizontalScrollBottomTrackSlotHeight(context);
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
              sizedBarChart(
                requiredPlot,
                slotW,
                chartBodyHeight,
                categoryViewportPan: false,
              ),
              bottomTrackSlot: kChartHorizontalScrollBottomTrackSlot,
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
                  enableCategoryViewportPan: false,
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
              enableCategoryViewportPan: false,
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
                    bottomTrackSlot: kChartHorizontalScrollBottomTrackSlot,
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

// Minimum pixel width reserved per bar slot (bar + gap).
const double _kDefaultMinBarWidth = 72;

// Default bar width ratio (fraction of bar slot occupied by the bar itself).
const double _kDefaultBarWidthRatio = 0.7;

// Default spacing ratio between bars when barGap is not specified.
const double _kDefaultSpacingRatio = 0.2;
