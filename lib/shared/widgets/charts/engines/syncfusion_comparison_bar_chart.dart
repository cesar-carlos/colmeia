import 'dart:math' as math;

import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
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
    Widget buildChart(BuildContext chartContext, double slotWidth) {
      final resolvedSpacing = spacingForSlotWidth(slotWidth);
      final resolvedRotation = xLabelRotationForSlotWidth(slotWidth);
      return SfCartesianChart(
        margin: _comparisonBarChartMargin(chartContext, style),
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
              offset: style.dataLabelOffset ?? Offset.zero,
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
              child: buildChart(context, slotWidth),
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
            child: buildChart(context, slotWidth),
          );

          if (!needsScroll) {
            return chartBox;
          }

          return _ComparisonBarChartHorizontalScroll(
            chartContent: chartBox,
            showFade: style.showScrollFade,
            semanticsHint: style.horizontalScrollSemanticsHint,
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
  final minTop = estimatedLineHeight + lift + extraGap;
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

// Width of the edge fade overlays in logical pixels.
const double _kScrollFadeWidth = 32;

// Threshold below which scroll position is considered "at end" (float noise).
const double _kScrollEdgeThreshold = 0.5;

bool _comparisonChartScrollbarThumbVisible(BuildContext context) {
  switch (Theme.of(context).platform) {
    case TargetPlatform.windows:
    case TargetPlatform.macOS:
    case TargetPlatform.linux:
      return true;
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.iOS:
      return false;
  }
}

/// Horizontal scroll for wide bar charts: [Scrollbar] on desktop, optional
/// edge fades, optional semantics hint for the scroll gesture.
class _ComparisonBarChartHorizontalScroll extends StatefulWidget {
  const _ComparisonBarChartHorizontalScroll({
    required this.chartContent,
    this.showFade = true,
    this.semanticsHint,
  });

  final Widget chartContent;
  final bool showFade;
  final String? semanticsHint;

  @override
  State<_ComparisonBarChartHorizontalScroll> createState() =>
      _ComparisonBarChartHorizontalScrollState();
}

class _ComparisonBarChartHorizontalScrollState
    extends State<_ComparisonBarChartHorizontalScroll> {
  late final ScrollController _controller;
  bool _showLeftFade = false;
  bool _showRightFade = true;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    if (widget.showFade) {
      _controller.addListener(_onScroll);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _onScroll();
        }
      });
    }
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    final showLeft = pos.pixels > _kScrollEdgeThreshold;
    final showRight = pos.pixels < pos.maxScrollExtent - _kScrollEdgeThreshold;
    if (showLeft == _showLeftFade && showRight == _showRightFade) return;
    setState(() {
      _showLeftFade = showLeft;
      _showRightFade = showRight;
    });
  }

  @override
  void dispose() {
    if (widget.showFade) {
      _controller.removeListener(_onScroll);
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget scrollable = Scrollbar(
      controller: _controller,
      thumbVisibility: _comparisonChartScrollbarThumbVisible(context),
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        child: widget.chartContent,
      ),
    );
    final hint = widget.semanticsHint;
    if (hint != null && hint.isNotEmpty) {
      scrollable = Semantics(hint: hint, child: scrollable);
    }

    if (!widget.showFade) {
      return scrollable;
    }

    final fadeColor = Theme.of(context).colorScheme.surface;
    return Stack(
      children: <Widget>[
        scrollable,
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
