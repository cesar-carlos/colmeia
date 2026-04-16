import 'dart:math' as math;

import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_combo_chart.dart';
import 'package:colmeia/shared/widgets/charts/chart_horizontal_scroll_shell.dart';
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
    this.isLoading = false,
    this.emptyPlaceholder,
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
  final bool isLoading;
  final Widget? emptyPlaceholder;

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
        label: 'Carregando comparativo combinado...',
      );
    }

    if (items.isEmpty) {
      return buildChartEmptyState(
        context: context,
        height: resolvedHeight,
        message: 'Sem dados combinados para este recorte.',
        placeholder: emptyPlaceholder,
      );
    }

    final minSlotWidth = style.minCategorySlotWidth;

    AxisLabelIntersectAction xLabelIntersectFor(double slotWidth) {
      return slotWidth >= 48
          ? AxisLabelIntersectAction.none
          : AxisLabelIntersectAction.rotate45;
    }

    Widget buildCartesian({
      required _ComboLayout layout,
      required double slotWidth,
      required bool showLegendInChart,
      required bool enableTooltip,
      required bool showPrimaryYAxisLabels,
      required bool showXAxisLabels,
      required bool primaryYAxisGrid,
    }) {
      final primaryGridW = primaryYAxisGrid && style.showYGridLines ? 1.0 : 0.0;

      return SfCartesianChart(
        margin: style.chartPadding ?? EdgeInsets.zero,
        plotAreaBorderWidth: 0,
        tooltipBehavior: TooltipBehavior(
          enable: enableTooltip && style.showTooltip,
        ),
        legend: Legend(
          isVisible: showLegendInChart && style.showLegend,
          position: LegendPosition.bottom,
          textStyle: style.legendTextStyle,
          overflowMode: LegendItemOverflowMode.wrap,
        ),
        primaryXAxis: CategoryAxis(
          isVisible: showXAxisLabels && style.showXAxis,
          majorGridLines: const MajorGridLines(width: 0),
          labelStyle: style.axisLabelTextStyle,
          labelIntersectAction: xLabelIntersectFor(slotWidth),
          maximumLabels: items.length,
        ),
        primaryYAxis: NumericAxis(
          name: 'leftAxis',
          isVisible: showPrimaryYAxisLabels,
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
        axes: <ChartAxis>[
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
        ],
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
            width: style.barWidth ?? 0.6,
            spacing: style.barSpacing ?? 0.2,
            animationDuration:
                style.animationDuration?.inMilliseconds.toDouble() ?? 1200,
            dataLabelSettings: DataLabelSettings(
              isVisible:
                  style.showDataLabels && layout != _ComboLayout.yAxisStrip,
              textStyle: style.dataLabelTextStyle,
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
            animationDuration:
                style.animationDuration?.inMilliseconds.toDouble() ?? 1200,
            markerSettings: MarkerSettings(
              isVisible: style.showMarkers && layout != _ComboLayout.yAxisStrip,
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

          if (!style.enableAutoScroll) {
            final slotWidth = layoutWidth / n;
            return SizedBox(
              width: layoutWidth,
              height: resolvedHeight,
              child: buildCartesian(
                layout: _ComboLayout.full,
                slotWidth: slotWidth,
                showLegendInChart: true,
                enableTooltip: true,
                showPrimaryYAxisLabels: true,
                showXAxisLabels: true,
                primaryYAxisGrid: true,
              ),
            );
          }

          final requiredFull = math.max(layoutWidth, minSlotWidth * n);
          final needsScroll = requiredFull > layoutWidth;

          if (!needsScroll) {
            final slotWidth = layoutWidth / n;
            return buildCartesian(
              layout: _ComboLayout.full,
              slotWidth: slotWidth,
              showLegendInChart: true,
              enableTooltip: true,
              showPrimaryYAxisLabels: true,
              showXAxisLabels: true,
              primaryYAxisGrid: true,
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
          const scrollSlot = kChartHorizontalScrollBottomTrackSlot;
          final plotChartBodyHeight = coreH - scrollSlot;

          if (!sticky) {
            final plotInner = SizedBox(
              width: requiredPlot,
              height: plotChartBodyHeight,
              child: buildCartesian(
                layout: _ComboLayout.full,
                slotWidth: slotWidth,
                showLegendInChart: true,
                enableTooltip: true,
                showPrimaryYAxisLabels: true,
                showXAxisLabels: true,
                primaryYAxisGrid: true,
              ),
            );
            return ChartHorizontalScrollShell(
              plotInner,
              bottomTrackSlot: scrollSlot,
              showFade: style.showScrollFade,
              semanticsHint: style.horizontalScrollSemanticsHint,
            );
          }

          final plotChart = SizedBox(
            width: requiredPlot,
            height: plotChartBodyHeight,
            child: buildCartesian(
              layout: _ComboLayout.plotScroll,
              slotWidth: slotWidth,
              showLegendInChart: false,
              enableTooltip: true,
              showPrimaryYAxisLabels: false,
              showXAxisLabels: true,
              primaryYAxisGrid: true,
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
                  layout: _ComboLayout.yAxisStrip,
                  slotWidth: slotWidth,
                  showLegendInChart: false,
                  enableTooltip: false,
                  showPrimaryYAxisLabels: true,
                  showXAxisLabels: false,
                  primaryYAxisGrid: false,
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
                    bottomTrackSlot: scrollSlot,
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ComboExternalLegend extends StatelessWidget {
  const _ComboExternalLegend({
    required this.barColor,
    required this.lineColor,
    required this.barLabel,
    required this.lineLabel,
    this.textStyle,
  });

  final Color barColor;
  final Color lineColor;
  final String barLabel;
  final String lineLabel;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final resolvedStyle =
        textStyle ?? Theme.of(context).textTheme.bodySmall ?? const TextStyle();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _LegendSwatch(
            color: barColor,
            label: barLabel,
            textStyle: resolvedStyle,
            isLine: false,
          ),
          const SizedBox(width: 20),
          _LegendSwatch(
            color: lineColor,
            label: lineLabel,
            textStyle: resolvedStyle,
            isLine: true,
          ),
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
