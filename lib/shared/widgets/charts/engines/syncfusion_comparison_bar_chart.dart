import 'dart:math' as math;

import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
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
    Widget buildChart(double slotWidth) {
      final resolvedSpacing = spacingForSlotWidth(slotWidth);
      final resolvedRotation = xLabelRotationForSlotWidth(slotWidth);
      return SfCartesianChart(
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
        onTooltipRender: tooltipLabels == null
            ? null
            : (args) {
                final index = args.pointIndex?.toInt();
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
          labelRotation: resolvedRotation.round(),
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
              : (details) => ChartAxisLabel(
                  style.yAxisFormat!.format(details.value),
                  details.textStyle,
                ),
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
            width: resolvedBarWidth,
            spacing: resolvedSpacing,
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
      );
    }

    final minBarWidth = style.minBarWidth ?? _kDefaultMinBarWidth;

    return SizedBox(
      height: resolvedHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : minBarWidth * points.length;

          if (!style.enableAutoScroll) {
            final slotWidth = points.isEmpty
                ? minBarWidth
                : availableWidth / points.length;
            return SizedBox(
              width: availableWidth,
              height: resolvedHeight,
              child: buildChart(slotWidth),
            );
          }

          final requiredWidth = math.max(
            availableWidth,
            minBarWidth * points.length,
          );
          final needsScroll = requiredWidth > availableWidth;
          final slotWidth = points.isEmpty
              ? minBarWidth
              : requiredWidth / points.length;

          final chartBox = SizedBox(
            width: requiredWidth,
            height: resolvedHeight,
            child: buildChart(slotWidth),
          );

          if (!needsScroll) {
            return chartBox;
          }

          if (!style.showScrollFade) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: chartBox,
            );
          }

          return _HorizontalScrollFade(chartContent: chartBox);
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

// Width of the edge fade overlays in logical pixels.
const double _kScrollFadeWidth = 32;

// Threshold below which scroll position is considered "at end" (float noise).
const double _kScrollEdgeThreshold = 0.5;

/// Wraps a horizontally scrollable chart with reactive edge-fade overlays.
///
/// A right-edge gradient is shown while the user has not yet scrolled to
/// the end. A left-edge gradient appears once the user has scrolled past
/// the start. Both fades disappear as the corresponding edge is reached,
/// giving a clear affordance without obscuring content after scrolling.
class _HorizontalScrollFade extends StatefulWidget {
  const _HorizontalScrollFade({required this.chartContent});

  final Widget chartContent;

  @override
  State<_HorizontalScrollFade> createState() => _HorizontalScrollFadeState();
}

class _HorizontalScrollFadeState extends State<_HorizontalScrollFade> {
  final ScrollController _controller = ScrollController();

  // Right fade visible by default: we only reach here when scroll is needed.
  bool _showLeftFade = false;
  bool _showRightFade = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    // Check initial state after the first frame so maxScrollExtent is known.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onScroll();
    });
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    final showLeft = pos.pixels > _kScrollEdgeThreshold;
    final showRight =
        pos.pixels < pos.maxScrollExtent - _kScrollEdgeThreshold;
    if (showLeft == _showLeftFade && showRight == _showRightFade) return;
    setState(() {
      _showLeftFade = showLeft;
      _showRightFade = showRight;
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fadeColor = Theme.of(context).colorScheme.surface;
    return Stack(
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _controller,
          child: widget.chartContent,
        ),
        if (_showLeftFade) _buildFade(fadeColor, isLeft: true),
        if (_showRightFade) _buildFade(fadeColor, isLeft: false),
      ],
    );
  }

  Widget _buildFade(Color fadeColor, {required bool isLeft}) {
    return Positioned(
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      top: 0,
      bottom: 0,
      width: _kScrollFadeWidth,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                fadeColor.withValues(alpha: isLeft ? 0.85 : 0),
                fadeColor.withValues(alpha: isLeft ? 0 : 0.85),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
