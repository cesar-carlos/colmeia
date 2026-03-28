import 'dart:math' as math;

import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppHeatmapCell {
  const AppHeatmapCell({
    required this.xLabel,
    required this.yLabel,
    required this.value,
    this.color,
  });

  final String xLabel;
  final String yLabel;
  final num value;
  final Color? color;
}

class AppHeatmapChartStyle {
  const AppHeatmapChartStyle({
    this.height,
    this.cellHeight,
    this.chartPadding,
    this.cellBorderRadius,
    this.axisLabelTextStyle,
    this.cellTextStyle,
    this.legendTextStyle,
    this.numberFormat,
    this.lowColor,
    this.highColor,
    this.emptyCellColor,
    this.minValue,
    this.maxValue,
    this.showCellValues = true,
    this.showLegend = true,
    this.yLabelWidth,
  });

  final double? height;
  final double? cellHeight;
  final EdgeInsets? chartPadding;
  final BorderRadius? cellBorderRadius;
  final TextStyle? axisLabelTextStyle;
  final TextStyle? cellTextStyle;
  final TextStyle? legendTextStyle;
  final NumberFormat? numberFormat;
  final Color? lowColor;
  final Color? highColor;
  final Color? emptyCellColor;
  final num? minValue;
  final num? maxValue;
  final bool showCellValues;
  final bool showLegend;
  final double? yLabelWidth;
}

class AppHeatmapChart extends StatelessWidget {
  const AppHeatmapChart({
    required this.cells,
    super.key,
    this.title,
    this.subtitle,
    this.titleTrailing,
    this.belowSubtitle,
    this.onCellTap,
    this.style = const AppHeatmapChartStyle(),
    this.preset = AppChartPreset.standard,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<AppHeatmapCell> cells;
  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;
  final void Function(AppHeatmapCell cell)? onCellTap;
  final AppHeatmapChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final innerChart = _HeatmapGrid(
      cells: cells,
      onCellTap: onCellTap,
      style: style,
      preset: preset,
      isLoading: isLoading,
      emptyPlaceholder: emptyPlaceholder,
    );

    if (title == null) {
      return innerChart;
    }

    return AppChartShell(
      title: title!,
      subtitle: subtitle,
      titleTrailing: titleTrailing,
      belowSubtitle: belowSubtitle,
      child: innerChart,
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({
    required this.cells,
    required this.style,
    required this.preset,
    this.onCellTap,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<AppHeatmapCell> cells;
  final void Function(AppHeatmapCell cell)? onCellTap;
  final AppHeatmapChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final tokens = theme.extension<AppThemeTokens>()!;
    final chartTheme = AppChartTheme.fromContext(context, preset: preset);

    final xLabels = <String>[];
    final yLabels = <String>[];
    final lookup = <String, AppHeatmapCell>{};

    for (final cell in cells) {
      if (!xLabels.contains(cell.xLabel)) {
        xLabels.add(cell.xLabel);
      }
      if (!yLabels.contains(cell.yLabel)) {
        yLabels.add(cell.yLabel);
      }
      lookup['${cell.yLabel}|${cell.xLabel}'] = cell;
    }

    final resolvedHeight =
        style.height ??
        math.max(
          chartTheme.height,
          ((style.cellHeight ?? 38) * (yLabels.length + 2)) + tokens.gapMd,
        );

    if (isLoading) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(
          child: CircularProgressIndicator(color: chartTheme.primaryColor),
        ),
      );
    }

    if (cells.isEmpty && emptyPlaceholder != null) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(child: emptyPlaceholder),
      );
    }

    final numericValues = cells.map((cell) => cell.value.toDouble()).toList();
    final minValue =
        style.minValue?.toDouble() ??
        (numericValues.isEmpty ? 0 : numericValues.reduce(math.min));
    final maxValue =
        style.maxValue?.toDouble() ??
        (numericValues.isEmpty ? 1 : numericValues.reduce(math.max));
    final range = (maxValue - minValue).abs() < 0.0001
        ? 1.0
        : maxValue - minValue;
    final lowColor =
        style.lowColor ?? chartTheme.primaryColor.withValues(alpha: 0.12);
    final highColor = style.highColor ?? chartTheme.primaryColor;
    final emptyCellColor = style.emptyCellColor ?? colors.surfaceContainerLow;
    final axisLabelTextStyle =
        style.axisLabelTextStyle ??
        theme.textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        );
    final cellTextStyle =
        style.cellTextStyle ??
        theme.textTheme.labelSmall?.copyWith(
          color: colors.onPrimary,
          fontWeight: FontWeight.w700,
        );
    final legendTextStyle =
        style.legendTextStyle ??
        theme.textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        );
    final borderRadius =
        style.cellBorderRadius ?? const BorderRadius.all(Radius.circular(8));

    Color resolveColor(AppHeatmapCell cell) {
      if (cell.color != null) {
        return cell.color!;
      }

      final t = ((cell.value.toDouble() - minValue) / range).clamp(0.0, 1.0);
      return Color.lerp(lowColor, highColor, t)!;
    }

    String resolveLabel(AppHeatmapCell cell) =>
        style.numberFormat?.format(cell.value) ?? cell.value.toStringAsFixed(0);

    return SizedBox(
      height: resolvedHeight,
      child: SingleChildScrollView(
        padding: style.chartPadding ?? EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                SizedBox(width: style.yLabelWidth ?? 72),
                SizedBox(width: tokens.gapSm),
                ...xLabels.map((label) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: tokens.gapSm),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: axisLabelTextStyle,
                      ),
                    ),
                  );
                }),
              ],
            ),
            ...yLabels.map((yLabel) {
              return Padding(
                padding: EdgeInsets.only(bottom: tokens.gapSm),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: style.yLabelWidth ?? 72,
                      child: Text(yLabel, style: axisLabelTextStyle),
                    ),
                    SizedBox(width: tokens.gapSm),
                    ...xLabels.map((xLabel) {
                      final cell = lookup['$yLabel|$xLabel'];

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: tokens.gapXs / 2,
                          ),
                          child: AspectRatio(
                            aspectRatio: 1.15,
                            child: cell == null
                                ? DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: emptyCellColor,
                                      borderRadius: borderRadius,
                                    ),
                                  )
                                : Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: borderRadius,
                                      onTap: onCellTap == null
                                          ? null
                                          : () => onCellTap!(cell),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: resolveColor(cell),
                                          borderRadius: borderRadius,
                                        ),
                                        child: Center(
                                          child: style.showCellValues
                                              ? Padding(
                                                  padding: EdgeInsets.all(
                                                    tokens.gapXs,
                                                  ),
                                                  child: Text(
                                                    resolveLabel(cell),
                                                    textAlign: TextAlign.center,
                                                    style: cellTextStyle,
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
            if (style.showLegend) ...<Widget>[
              SizedBox(height: tokens.gapSm),
              Row(
                children: <Widget>[
                  Text(
                    style.numberFormat?.format(minValue) ??
                        minValue.toStringAsFixed(0),
                    style: legendTextStyle,
                  ),
                  SizedBox(width: tokens.gapSm),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[lowColor, highColor],
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(999),
                        ),
                      ),
                      child: const SizedBox(height: 10),
                    ),
                  ),
                  SizedBox(width: tokens.gapSm),
                  Text(
                    style.numberFormat?.format(maxValue) ??
                        maxValue.toStringAsFixed(0),
                    style: legendTextStyle,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
