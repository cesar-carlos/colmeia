import 'dart:math' as math;

import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_bullet_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:flutter/material.dart';

class CustomBulletChart<T> extends StatelessWidget {
  const CustomBulletChart({
    required this.items,
    required this.labelBuilder,
    required this.valueBuilder,
    required this.targetValueBuilder,
    required this.rangesBuilder,
    required this.style,
    required this.preset,
    super.key,
    this.maxValueBuilder,
    this.onPointTap,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<T> items;
  final String Function(T item) labelBuilder;
  final num Function(T item) valueBuilder;
  final num Function(T item) targetValueBuilder;
  final List<AppBulletRange> Function(T item) rangesBuilder;
  final num Function(T item)? maxValueBuilder;
  final void Function(T item, int index)? onPointTap;
  final AppBulletChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final tokens = theme.extension<AppThemeTokens>()!;
    final chartTheme = AppChartTheme.fromContext(context, preset: preset);
    final resolvedHeight =
        style.height ??
        switch (preset) {
          AppChartPreset.compact => math.max(140, items.length * 56),
          AppChartPreset.standard => math.max(180, items.length * 72),
          AppChartPreset.explorable => math.max(200, items.length * 80),
        }.toDouble();

    if (isLoading) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(
          child: CircularProgressIndicator(color: chartTheme.primaryColor),
        ),
      );
    }

    if (items.isEmpty && emptyPlaceholder != null) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(child: emptyPlaceholder),
      );
    }

    final rowSpacing = style.rowSpacing ?? tokens.gapMd;

    return SizedBox(
      height: resolvedHeight,
      child: SingleChildScrollView(
        padding: style.chartPadding ?? EdgeInsets.zero,
        child: Column(
          children: items.indexed.map((entry) {
            final index = entry.$1;
            final item = entry.$2;
            final child = _BulletChartRow<T>(
              item: item,
              labelBuilder: labelBuilder,
              valueBuilder: valueBuilder,
              targetValueBuilder: targetValueBuilder,
              rangesBuilder: rangesBuilder,
              maxValueBuilder: maxValueBuilder,
              style: style,
              colors: colors,
              chartTheme: chartTheme,
            );

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == items.length - 1 ? 0 : rowSpacing,
              ),
              child: onPointTap == null
                  ? child
                  : InkWell(
                      borderRadius: BorderRadius.circular(tokens.cardRadius),
                      onTap: () => onPointTap!(item, index),
                      child: Padding(
                        padding: EdgeInsets.all(tokens.gapXs),
                        child: child,
                      ),
                    ),
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}

class _BulletChartRow<T> extends StatelessWidget {
  const _BulletChartRow({
    required this.item,
    required this.labelBuilder,
    required this.valueBuilder,
    required this.targetValueBuilder,
    required this.rangesBuilder,
    required this.maxValueBuilder,
    required this.style,
    required this.colors,
    required this.chartTheme,
  });

  final T item;
  final String Function(T item) labelBuilder;
  final num Function(T item) valueBuilder;
  final num Function(T item) targetValueBuilder;
  final List<AppBulletRange> Function(T item) rangesBuilder;
  final num Function(T item)? maxValueBuilder;
  final AppBulletChartStyle style;
  final AppColors colors;
  final AppChartTheme chartTheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final rawRanges = rangesBuilder(item)
      ..sort((a, b) => a.end.compareTo(b.end));
    final value = valueBuilder(item).toDouble();
    final target = targetValueBuilder(item).toDouble();
    final derivedMax = rawRanges.isEmpty
        ? math.max(value, target)
        : rawRanges.last.end.toDouble();
    final maxValue = math.max(
      maxValueBuilder?.call(item).toDouble() ?? derivedMax,
      1,
    );
    final labelTextStyle =
        style.labelTextStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );
    final valueTextStyle =
        style.valueTextStyle ??
        theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        );
    final captionTextStyle =
        style.captionTextStyle ??
        theme.textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        );
    final actualLabel =
        style.numberFormat?.format(value) ?? value.toStringAsFixed(0);
    final targetLabel =
        style.numberFormat?.format(target) ?? target.toStringAsFixed(0);
    final barHeight = style.barHeight ?? 18;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: style.labelWidth ?? 96,
          child: Padding(
            padding: EdgeInsets.only(top: tokens.gapXs),
            child: Text(labelBuilder(item), style: labelTextStyle),
          ),
        ),
        SizedBox(width: tokens.gapMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: barHeight,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final radius =
                        style.backgroundRadius ??
                        const BorderRadius.all(Radius.circular(6));
                    final actualWidth = constraints.maxWidth *
                        (value.clamp(0, maxValue) / maxValue);
                    final targetPosition = constraints.maxWidth *
                        (target.clamp(0, maxValue) / maxValue);

                    var previousEnd = 0.0;
                    final rangeWidgets = rawRanges.indexed.map((entry) {
                      final currentEnd =
                          entry.$2.end.toDouble().clamp(0, maxValue).toDouble();
                      final segmentLeft =
                          constraints.maxWidth * (previousEnd / maxValue);
                      final segmentWidth =
                          constraints.maxWidth *
                          ((currentEnd - previousEnd).clamp(0, maxValue) /
                              maxValue);
                      previousEnd = currentEnd;

                      return Positioned(
                        left: segmentLeft,
                        top: 0,
                        bottom: 0,
                        width: segmentWidth,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color:
                                entry.$2.color ?? _defaultRangeColor(entry.$1),
                            borderRadius: radius,
                          ),
                        ),
                      );
                    }).toList(growable: false);

                    return Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerLowest,
                              borderRadius: radius,
                            ),
                          ),
                        ),
                        ...rangeWidgets,
                        Positioned(
                          left: 0,
                          top: 2,
                          bottom: 2,
                          width: actualWidth,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: style.actualBarColor ??
                                  chartTheme.primaryColor,
                              borderRadius: radius,
                            ),
                          ),
                        ),
                        Positioned(
                          left: targetPosition -
                              ((style.targetMarkerWidth ?? 3) / 2),
                          top: -3,
                          bottom: -3,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color:
                                  style.targetMarkerColor ??
                                  chartTheme.paletteColor(1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: SizedBox(
                              width: style.targetMarkerWidth ?? 3,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (style.showValueLabels) ...<Widget>[
                SizedBox(height: tokens.gapXs),
                Row(
                  children: <Widget>[
                    Text('Atual: $actualLabel', style: valueTextStyle),
                    SizedBox(width: tokens.gapSm),
                    Text('Meta: $targetLabel', style: captionTextStyle),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Color _defaultRangeColor(int index) => switch (index) {
    0 => colors.surfaceContainerLow,
    1 => colors.surfaceContainerHigh,
    _ => colors.surfaceContainerHighest,
  };
}
