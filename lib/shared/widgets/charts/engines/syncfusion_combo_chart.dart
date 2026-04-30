import 'dart:math' as math;

import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_combo_chart.dart';
import 'package:colmeia/shared/widgets/charts/chart_horizontal_scroll_shell.dart';
import 'package:colmeia/shared/widgets/charts/chart_pan_footnote_column.dart';
import 'package:colmeia/shared/widgets/charts/comparison_bar_chart_margin.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_states.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Reserved height for a simple two-row legend below the plot when the primary
/// Y-axis is sticky and the built-in chart legend is disabled on split charts.
const double _kComboExternalLegendHeight = 36;

enum _ComboLayout { full, yAxisStrip, plotScroll }

class SyncfusionComboChart<T> extends StatelessWidget {
  const SyncfusionComboChart({
    required this.items,
    required this.xLabelBuilder,
    required this.barValueBuilder,
    required this.barSeriesLabel,
    required this.lineValueBuilder,
    required this.lineSeriesLabel,
    required this.style,
    required this.preset,
    super.key,
    this.onBarTap,
    this.onLineTap,
    this.barDataLabelBuilder,
    this.isLoading = false,
    this.emptyPlaceholder,
    this.resolvedLoadingLabel,
    this.resolvedEmptyMessage,
  });

  final List<T> items;
  final String Function(T item) xLabelBuilder;
  final num Function(T item) barValueBuilder;
  final String barSeriesLabel;
  final num Function(T item) lineValueBuilder;
  final String lineSeriesLabel;
  final AppComboChartStyle style;
  final AppChartPreset preset;
  final void Function(T item, int index)? onBarTap;
  final void Function(T item, int index)? onLineTap;
  final String? Function(T item, num barValue)? barDataLabelBuilder;
  final bool isLoading;
  final Widget? emptyPlaceholder;
  final String? resolvedLoadingLabel;
  final String? resolvedEmptyMessage;

  @override
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(context, preset: preset);
    final colors = Theme.of(context).appColors;
    final resolvedHeight = style.height ?? chartTheme.height;
    final gridLineColor = colors.outlineVariant.withValues(alpha: 0.35);
    final resolvedBarColor = style.barColor ?? chartTheme.primaryColor;
    final resolvedLineColor = style.lineColor ?? colors.secondary;

    if (isLoading) {
      return buildChartLoadingState(
        context: context,
        height: resolvedHeight,
        indicatorColor: resolvedBarColor,
        label: resolvedLoadingLabel ?? 'Loading bar and line chart…',
      );
    }

    if (items.isEmpty) {
      return buildChartEmptyState(
        context: context,
        height: resolvedHeight,
        message: resolvedEmptyMessage ?? 'No combined data for this view.',
        placeholder: emptyPlaceholder,
      );
    }

    final minSlotWidth = style.minCategorySlotWidth;

    Widget buildCartesian(
      BuildContext chartContext, {
      required _ComboLayout layout,
      required double slotWidth,
      required bool showLegendInChart,
      required bool enableTooltip,
      required bool showPrimaryYAxisLabels,
      required bool showXAxisLabels,
      required bool primaryYAxisGrid,
      required bool enableCategoryViewportPan,
    }) {
      final showLine = style.showLineSeries;
      final primaryGridW = primaryYAxisGrid && style.showYGridLines ? 1.0 : 0.0;
      final barLabelsVisible =
          style.showDataLabels && layout != _ComboLayout.yAxisStrip;
      final chartMargin = resolveComparisonBarChartMargin(
        chartContext,
        showDataLabels: barLabelsVisible,
        dataLabelAlignment: style.barDataLabelAlignment,
        dataLabelOffset: style.barDataLabelOffset,
        chartPadding: style.chartPadding,
      );
      final delta = style.categoryAutoScrollingDelta;
      final useCategoryAxisPan =
          enableCategoryViewportPan &&
          enableTooltip &&
          delta != null &&
          delta > 0;
      final colorScheme = Theme.of(chartContext).colorScheme;
      final useAnnotationBarLabels = barLabelsVisible &&
          (style.barDataLabelAlignment == ChartDataLabelAlignment.outer ||
              style.barDataLabelAlignment == ChartDataLabelAlignment.auto);
      final barValueAnnotations = useAnnotationBarLabels
          ? _comboBarValueLabelAnnotations<T>(
              items: items,
              barValueBuilder: barValueBuilder,
              barDataLabelBuilder: barDataLabelBuilder,
              style: style,
              colorScheme: colorScheme,
            )
          : null;

      return SfCartesianChart(
        annotations: barValueAnnotations,
        margin: chartMargin,
        plotAreaBorderWidth: 0,
        zoomPanBehavior: useCategoryAxisPan
            ? ZoomPanBehavior(
                enablePanning: true,
                zoomMode: ZoomMode.x,
              )
            : null,
        onTooltipRender:
            enableTooltip ? buildSanitizingTooltipRenderer() : null,
        // Shared tooltip when both series exist; single-series charts still work.
        tooltipBehavior: buildChartTooltipBehavior(
          context,
          enable: enableTooltip && style.showTooltip,
          shared: showLine,
        ),
        legend: Legend(
          isVisible: showLegendInChart && style.showLegend,
          position: LegendPosition.bottom,
          textStyle: style.legendTextStyle,
          overflowMode: LegendItemOverflowMode.wrap,
        ),
        primaryXAxis: CategoryAxis(
          arrangeByIndex: true,
          isVisible: showXAxisLabels && style.showXAxis,
          majorGridLines: const MajorGridLines(width: 0),
          labelStyle: style.axisLabelTextStyle,
          labelIntersectAction: style.categoryLabelIntersectAction ??
              AxisLabelIntersectAction.none,
          maximumLabels: items.length,
          autoScrollingDelta: useCategoryAxisPan ? delta : null,
          autoScrollingMode: style.categoryAutoScrollingMode,
        ),
        primaryYAxis: NumericAxis(
          name: 'leftAxis',
          isVisible: showPrimaryYAxisLabels,
          rangePadding:
              comparisonBarChartNeedsOuterDataLabelHeadroom(
                showDataLabels: barLabelsVisible,
                dataLabelAlignment: style.barDataLabelAlignment,
              )
              ? ChartRangePadding.normal
              : ChartRangePadding.auto,
          axisLine: const AxisLine(width: 0),
          majorGridLines: MajorGridLines(
            color: gridLineColor,
            width: primaryGridW,
          ),
          labelStyle: style.axisLabelTextStyle,
          numberFormat: style.leftAxisFormat,
          axisLabelFormatter: style.leftAxisFormat == null
              ? null
              : (details) => ChartAxisLabel(
                  style.leftAxisFormat!.format(details.value),
                  details.textStyle,
                ),
        ),
        axes: showLine
            ? <ChartAxis>[
                NumericAxis(
                  name: 'rightAxis',
                  isVisible:
                      layout != _ComboLayout.yAxisStrip && style.showRightYAxis,
                  opposedPosition: true,
                  axisLine: const AxisLine(width: 0),
                  majorGridLines: const MajorGridLines(width: 0),
                  labelStyle: style.axisLabelTextStyle,
                  numberFormat: style.rightAxisFormat,
                  axisLabelFormatter: style.rightAxisFormat == null
                      ? null
                      : (details) => ChartAxisLabel(
                          style.rightAxisFormat!.format(details.value),
                          details.textStyle,
                        ),
                ),
              ]
            : <ChartAxis>[],
        series: <CartesianSeries<T, String>>[
          ColumnSeries<T, String>(
            dataSource: items,
            xValueMapper: (item, _) => xLabelBuilder(item),
            yValueMapper: (item, _) => barValueBuilder(item),
            name: barSeriesLabel,
            yAxisName: 'leftAxis',
            color: layout == _ComboLayout.yAxisStrip
                ? resolvedBarColor.withValues(alpha: 0)
                : resolvedBarColor,
            width: style.barWidth ??
                AppChartEngineCartesianBarGeometryDefaults.columnWidthRatio,
            spacing: style.barSpacing ??
                AppChartEngineCartesianBarGeometryDefaults.columnSpacingRatio,
            borderRadius: style.barBorderRadius,
            animationDuration: resolveChartAnimationDurationMs(
              context: context,
              styleDuration: style.animationDuration,
              defaultMs: AppChartEngineAnimationDefaults.cartesianSeriesMs,
            ),
            dataLabelMapper: barLabelsVisible && !useAnnotationBarLabels
                ? (data, _) =>
                      barDataLabelBuilder?.call(data, barValueBuilder(data)) ??
                      barValueBuilder(data).toString()
                : null,
            dataLabelSettings: DataLabelSettings(
              isVisible: barLabelsVisible && !useAnnotationBarLabels,
              textStyle: style.dataLabelTextStyle,
              labelAlignment: style.barDataLabelAlignment,
              labelIntersectAction: LabelIntersectAction.none,
              offset: style.barDataLabelOffset ?? Offset.zero,
            ),
            onPointTap: onBarTap == null || layout == _ComboLayout.yAxisStrip
                ? null
                : (details) {
                    final idx = details.pointIndex;
                    if (idx != null && idx >= 0 && idx < items.length) {
                      onBarTap!(items[idx], idx);
                    }
                  },
          ),
          if (showLine)
            LineSeries<T, String>(
              dataSource: items,
              xValueMapper: (item, _) => xLabelBuilder(item),
              yValueMapper: (item, _) => lineValueBuilder(item),
              name: lineSeriesLabel,
              yAxisName: 'rightAxis',
              color: layout == _ComboLayout.yAxisStrip
                  ? resolvedLineColor.withValues(alpha: 0)
                  : resolvedLineColor,
              width: style.lineWidth ?? 2.5,
              animationDuration: resolveChartAnimationDurationMs(
                context: context,
                styleDuration: style.animationDuration,
                defaultMs: AppChartEngineAnimationDefaults.cartesianSeriesMs,
              ),
              markerSettings: MarkerSettings(
                isVisible:
                    style.showMarkers && layout != _ComboLayout.yAxisStrip,
                height: 6,
                width: 6,
                color: resolvedLineColor,
                borderColor: colors.surface,
              ),
              onPointTap: onLineTap == null || layout == _ComboLayout.yAxisStrip
                  ? null
                  : (details) {
                      final idx = details.pointIndex;
                      if (idx != null && idx >= 0 && idx < items.length) {
                        onLineTap!(items[idx], idx);
                      }
                    },
            ),
        ],
      );
    }

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
            layoutWidth = minSlotWidth * items.length;
          }

          final n = items.length;
          final delta = style.categoryAutoScrollingDelta;
          final crowded = n > 1 && (layoutWidth / n) < minSlotWidth;
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

          Widget sizedCombo(
            double width,
            double slotW,
            double chartHeight, {
            required bool categoryViewportPan,
          }) {
            return SizedBox(
              width: width,
              height: chartHeight,
              child: buildCartesian(
                context,
                layout: _ComboLayout.full,
                slotWidth: slotW,
                showLegendInChart: true,
                enableTooltip: true,
                showPrimaryYAxisLabels: true,
                showXAxisLabels: true,
                primaryYAxisGrid: true,
                enableCategoryViewportPan: categoryViewportPan,
              ),
            );
          }

          if (!style.enableAutoScroll) {
            final slotW = layoutWidth / slotDenom;
            final footText = footRaw ?? '';
            // Pan footnote layout matches [SyncfusionComparisonBarChart]
            // (shared [ChartPanFootnoteColumn]).
            var chart = showPanFootnote
                ? ChartPanFootnoteColumn(
                    plot: SizedBox(
                      width: layoutWidth,
                      child: buildCartesian(
                        context,
                        layout: _ComboLayout.full,
                        slotWidth: slotW,
                        showLegendInChart: true,
                        enableTooltip: true,
                        showPrimaryYAxisLabels: true,
                        showXAxisLabels: true,
                        primaryYAxisGrid: true,
                        enableCategoryViewportPan: useCategoryViewportPan,
                      ),
                    ),
                    footnoteText: footText,
                  )
                : sizedCombo(
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

          final requiredFull = math.max(layoutWidth, minSlotWidth * n);
          final needsScroll = requiredFull > layoutWidth;

          if (!needsScroll) {
            final slotWidth = layoutWidth / n;
            return buildCartesian(
              context,
              layout: _ComboLayout.full,
              slotWidth: slotWidth,
              showLegendInChart: true,
              enableTooltip: true,
              showPrimaryYAxisLabels: true,
              showXAxisLabels: true,
              primaryYAxisGrid: true,
              enableCategoryViewportPan: false,
            );
          }

          final sticky = style.stickyPrimaryYAxisWhileScrolling;
          final stickyW = sticky ? style.stickyPrimaryYAxisWidth : 0.0;
          final plotViewport = (layoutWidth - stickyW)
              .clamp(1, double.infinity)
              .toDouble();
          final requiredPlot = math.max(plotViewport, minSlotWidth * n);
          final slotWidth = requiredPlot / n;

          final legendReserve = sticky && style.showLegend
              ? _kComboExternalLegendHeight
              : 0.0;
          final coreH = resolvedHeight - legendReserve;
          // [ChartHorizontalScrollShell] scales its bottom strip by the
          // platform [TextScaler] for accessibility, so engines must deduct
          // the *resolved* slot — not the raw constant — to avoid the inner
          // column overflowing at large text scales (text scaler 2.25 turns
          // a 22 px slot into ~49 px).
          final resolvedScrollSlot =
              chartHorizontalScrollBottomTrackSlotHeight(context);
          final plotChartBodyHeight = coreH - resolvedScrollSlot;

          if (!sticky) {
            final plotInner = SizedBox(
              width: requiredPlot,
              height: plotChartBodyHeight,
              child: buildCartesian(
                context,
                layout: _ComboLayout.full,
                slotWidth: slotWidth,
                showLegendInChart: true,
                enableTooltip: true,
                showPrimaryYAxisLabels: true,
                showXAxisLabels: true,
                primaryYAxisGrid: true,
                enableCategoryViewportPan: false,
              ),
            );
            return ChartHorizontalScrollShell(
              plotInner,
              bottomTrackSlot: kChartHorizontalScrollBottomTrackSlot,
              showFade: style.showScrollFade,
              semanticsHint: style.horizontalScrollSemanticsHint,
            );
          }

          final plotChart = SizedBox(
            width: requiredPlot,
            height: plotChartBodyHeight,
            child: buildCartesian(
              context,
              layout: _ComboLayout.plotScroll,
              slotWidth: slotWidth,
              showLegendInChart: false,
              enableTooltip: true,
              showPrimaryYAxisLabels: false,
              showXAxisLabels: true,
              primaryYAxisGrid: true,
              enableCategoryViewportPan: false,
            ),
          );

          final stripChart = SizedBox(
            width: stickyW,
            height: coreH,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: plotChartBodyHeight,
                child: buildCartesian(
                  context,
                  layout: _ComboLayout.yAxisStrip,
                  slotWidth: slotWidth,
                  showLegendInChart: false,
                  enableTooltip: false,
                  showPrimaryYAxisLabels: true,
                  showXAxisLabels: false,
                  primaryYAxisGrid: false,
                  enableCategoryViewportPan: false,
                ),
              ),
            ),
          );

          final plotRow = SizedBox(
            height: coreH,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                stripChart,
                Expanded(
                  child: ChartHorizontalScrollShell(
                    plotChart,
                    bottomTrackSlot: kChartHorizontalScrollBottomTrackSlot,
                    showFade: style.showScrollFade,
                    semanticsHint: style.horizontalScrollSemanticsHint,
                  ),
                ),
              ],
            ),
          );

          if (legendReserve <= 0) {
            return SizedBox(height: resolvedHeight, child: plotRow);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(height: coreH, child: plotRow),
              SizedBox(
                height: legendReserve,
                child: _ComboExternalLegend(
                  barColor: resolvedBarColor,
                  lineColor: resolvedLineColor,
                  barLabel: barSeriesLabel,
                  lineLabel: lineSeriesLabel,
                  textStyle: style.legendTextStyle,
                  showLine: style.showLineSeries,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Bar value labels for [SyncfusionComboChart] with outer/auto alignment are
/// drawn as chart annotations above the column top. Syncfusion otherwise can
/// paint a second label inside the bar when using [ColumnSeries.dataLabelMapper].
List<CartesianChartAnnotation>? _comboBarValueLabelAnnotations<T>({
  required List<T> items,
  required num Function(T item) barValueBuilder,
  required String? Function(T item, num barValue)? barDataLabelBuilder,
  required AppComboChartStyle style,
  required ColorScheme colorScheme,
}) {
  final annotations = <CartesianChartAnnotation>[];
  final offset = style.barDataLabelOffset ?? Offset.zero;
  const outerMargin = EdgeInsets.all(5);
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    final v = barValueBuilder(item);
    final mapped = barDataLabelBuilder?.call(item, v);
    final text = mapped ?? v.toString();
    if (text.isEmpty) {
      continue;
    }
    final explicitColor = style.dataLabelTextStyle?.color;
    final textColor = explicitColor ?? colorScheme.onSurface;
    final baseStyle = style.dataLabelTextStyle ?? const TextStyle();
    final resolvedTextStyle = baseStyle.copyWith(color: textColor);
    Widget label = Padding(
      padding: outerMargin,
      child: Text(text, style: resolvedTextStyle),
    );
    label = Transform.translate(
      offset: Offset(offset.dx, -offset.dy),
      child: label,
    );
    // Same as comparison bars: [x] must be the category index when
    // [CategoryAxis.arrangeByIndex] is true; string labels can collapse via
    // [indexOf] and stack every value on one bar.
    annotations.add(
      CartesianChartAnnotation(
        coordinateUnit: CoordinateUnit.point,
        x: i,
        y: v,
        verticalAlignment: ChartAlignment.far,
        widget: label,
      ),
    );
  }
  return annotations.isEmpty ? null : annotations;
}

class _ComboExternalLegend extends StatelessWidget {
  const _ComboExternalLegend({
    required this.barColor,
    required this.lineColor,
    required this.barLabel,
    required this.lineLabel,
    required this.showLine,
    this.textStyle,
  });

  final Color barColor;
  final Color lineColor;
  final String barLabel;
  final String lineLabel;
  final bool showLine;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final resolvedStyle =
        textStyle ?? Theme.of(context).textTheme.bodySmall ?? const TextStyle();

    final bar = _LegendSwatch(
      color: barColor,
      label: barLabel,
      textStyle: resolvedStyle,
      isLine: false,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          bar,
          if (showLine) ...<Widget>[
            const SizedBox(width: 20),
            _LegendSwatch(
              color: lineColor,
              label: lineLabel,
              textStyle: resolvedStyle,
              isLine: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({
    required this.color,
    required this.label,
    required this.textStyle,
    required this.isLine,
  });

  final Color color;
  final String label;
  final TextStyle textStyle;
  final bool isLine;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (isLine)
          CustomPaint(
            size: const Size(18, 10),
            painter: _MiniLineLegendPainter(color: color),
          )
        else
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(width: 6),
        Text(label, style: textStyle),
      ],
    );
  }
}

class _MiniLineLegendPainter extends CustomPainter {
  _MiniLineLegendPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final y = size.height / 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), stroke);
    final fill = Paint()..color = color;
    canvas.drawCircle(Offset(size.width / 2, y), 3, fill);
  }

  @override
  bool shouldRepaint(covariant _MiniLineLegendPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
