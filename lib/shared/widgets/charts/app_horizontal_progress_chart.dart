import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/charts/horizontal_progress_chart_math.dart';
import 'package:flutter/material.dart';

typedef AppHorizontalProgressLabelBuilder<T> = String Function(T item);
typedef AppHorizontalProgressValueBuilder<T> = double Function(T item);

/// Optional bar numerator when it differs from the display `valueBuilder`.
typedef AppHorizontalProgressBarValueBuilder<T> = double Function(T item);

/// Per-row denominator; falls back to chart `maxValue` when omitted.
typedef AppHorizontalProgressMaxValueBuilder<T> = double Function(T item);

typedef AppHorizontalProgressValueLabelBuilder<T> =
    String Function(T item, double displayValue, double rowMaxValue);

typedef AppHorizontalProgressRowLeadingBuilder<T> =
    Widget? Function(BuildContext context, T item);

typedef AppHorizontalProgressTooltipBuilder<T> =
    String? Function(T item, double displayValue, double rowMaxValue);

typedef AppHorizontalProgressDividerBuilder =
    Widget Function(BuildContext context, int index);

class AppHorizontalProgressChartStyle {
  const AppHorizontalProgressChartStyle({
    this.barColor,
    this.trackColor,
    this.valueColor,
    this.barGradient,
    this.rowSpacing,
    this.barHeight = 8,
    this.barRadius,
    this.rowPadding,
    this.titleTextStyle,
    this.labelTextStyle,
    this.valueTextStyle,
    this.titleTextAlign,
    this.labelTextAlign,
    this.valueTextAlign,
    this.titleBottomSpacing,
    this.leadingSpacing,
    this.dividerPadding,
  });

  final Color? barColor;
  final Color? trackColor;
  final Color? valueColor;
  final Gradient? barGradient;
  final double? rowSpacing;
  final double barHeight;
  final BorderRadiusGeometry? barRadius;
  final EdgeInsetsGeometry? rowPadding;
  final TextStyle? titleTextStyle;
  final TextStyle? labelTextStyle;
  final TextStyle? valueTextStyle;
  final TextAlign? titleTextAlign;
  final TextAlign? labelTextAlign;
  final TextAlign? valueTextAlign;
  final double? titleBottomSpacing;
  final double? leadingSpacing;
  final EdgeInsetsGeometry? dividerPadding;
}

/// Horizontal list chart: label, trailing value, and a progress bar per row.
///
/// Pass any item type `T` and map label, display value, and bar fill via
/// builders. Bar fill is `barRaw / rowMax` where `barRaw` uses
/// `progressValueBuilder` when set, otherwise `valueBuilder`. `rowMax` uses
/// `maxValueBuilder` when set, otherwise `maxValue`.
///
/// Default trailing text uses `defaultHorizontalProgressValueLabel` (see
/// `horizontal_progress_chart_math.dart`) and can be customized with
/// [valueLabelMode].
class AppHorizontalProgressChart<T> extends StatelessWidget {
  const AppHorizontalProgressChart({
    required this.items,
    required this.labelBuilder,
    required this.valueBuilder,
    super.key,
    this.title,
    this.maxValue = 100,
    this.progressValueBuilder,
    this.maxValueBuilder,
    this.valueLabelBuilder,
    this.valueLabelMode = AppHorizontalProgressValueLabelMode.auto,
    this.titleWidget,
    this.rowLeadingBuilder,
    this.rowTooltipBuilder,
    this.showDividers = false,
    this.dividerBuilder,
    this.style = const AppHorizontalProgressChartStyle(),
    this.wrapInCard = true,
    this.cardColor,
    this.cardPadding,
    this.emptyPlaceholder,
    this.isLoading = false,
    this.loadingRowCount = 4,
    this.onItemTap,
    this.barAnimationDuration,
  });

  final List<T> items;
  final AppHorizontalProgressLabelBuilder<T> labelBuilder;
  final AppHorizontalProgressValueBuilder<T> valueBuilder;
  final String? title;
  final double maxValue;
  final AppHorizontalProgressBarValueBuilder<T>? progressValueBuilder;
  final AppHorizontalProgressMaxValueBuilder<T>? maxValueBuilder;
  final AppHorizontalProgressValueLabelBuilder<T>? valueLabelBuilder;
  final AppHorizontalProgressValueLabelMode valueLabelMode;
  final Widget? titleWidget;
  final AppHorizontalProgressRowLeadingBuilder<T>? rowLeadingBuilder;
  final AppHorizontalProgressTooltipBuilder<T>? rowTooltipBuilder;
  final bool showDividers;
  final AppHorizontalProgressDividerBuilder? dividerBuilder;
  final AppHorizontalProgressChartStyle style;
  final bool wrapInCard;
  final Color? cardColor;
  final EdgeInsetsGeometry? cardPadding;
  final Widget? emptyPlaceholder;
  final bool isLoading;
  final int loadingRowCount;
  final void Function(T item)? onItemTap;
  final Duration? barAnimationDuration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;
    final rowSpacing = style.rowSpacing ?? tokens.gapMd;
    final barColor = style.barColor ?? cs.primary;
    final trackColor = style.trackColor ?? cs.surfaceContainerHigh;
    final valueColor = style.valueColor ?? barColor;
    final barRadius =
        style.barRadius ?? BorderRadius.circular(tokens.formFieldRadius);
    final titleBottomSpacing =
        style.titleBottomSpacing ?? tokens.contentSpacing;
    final leadingSpacing = style.leadingSpacing ?? tokens.gapSm;
    final resolvedTitleStyle =
        style.titleTextStyle ??
        theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        );
    final resolvedLabelStyle =
        style.labelTextStyle ??
        theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        );
    final resolvedValueStyle =
        style.valueTextStyle ??
        theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: valueColor,
        );

    Widget body;
    if (isLoading) {
      body = _LoadingRows(
        rowCount: loadingRowCount,
        rowSpacing: rowSpacing,
        barHeight: style.barHeight,
        barRadius: barRadius,
        trackColor: trackColor,
        barColor: barColor,
        rowPadding: style.rowPadding,
        gapSm: tokens.gapSm,
        titleWidget: titleWidget,
        title: title,
        resolvedTitleStyle: resolvedTitleStyle,
        titleTextAlign: style.titleTextAlign,
        titleBottomSpacing: titleBottomSpacing,
      );
    } else if (items.isEmpty) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ..._buildChartHeader(
            titleWidget: titleWidget,
            title: title,
            resolvedTitleStyle: resolvedTitleStyle,
            titleTextAlign: style.titleTextAlign,
            titleBottomSpacing: titleBottomSpacing,
          ),
          emptyPlaceholder ?? const SizedBox.shrink(),
        ],
      );
    } else {
      final rows = <Widget>[];
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final displayValue = sanitizeHorizontalProgressNumber(
          valueBuilder(item),
        );
        final rowMax = sanitizeHorizontalProgressNumber(
          maxValueBuilder?.call(item) ?? maxValue,
        );
        final barRaw = sanitizeHorizontalProgressNumber(
          progressValueBuilder?.call(item) ?? displayValue,
        );
        final normalized = normalizedHorizontalProgress(
          rawValue: barRaw,
          maxValue: rowMax,
        );
        rows.add(
          _AppHorizontalProgressRow<T>(
            item: item,
            labelBuilder: labelBuilder,
            rowLeadingBuilder: rowLeadingBuilder,
            rowTooltipBuilder: rowTooltipBuilder,
            valueLabelBuilder: valueLabelBuilder,
            valueLabelMode: valueLabelMode,
            displayValue: displayValue,
            rowMaxValue: rowMax,
            normalized: normalized,
            barColor: barColor,
            trackColor: trackColor,
            barGradient: style.barGradient,
            barHeight: style.barHeight,
            barRadius: barRadius,
            rowPadding: style.rowPadding,
            labelTextStyle: resolvedLabelStyle,
            valueTextStyle: resolvedValueStyle,
            labelTextAlign: style.labelTextAlign,
            valueTextAlign: style.valueTextAlign,
            leadingSpacing: leadingSpacing,
            gapSm: tokens.gapSm,
            onItemTap: onItemTap,
            barAnimationDuration: barAnimationDuration,
          ),
        );
        if (i < items.length - 1) {
          if (showDividers) {
            rows.add(
              Padding(
                padding:
                    style.dividerPadding ??
                    EdgeInsets.symmetric(vertical: rowSpacing / 2),
                child:
                    dividerBuilder?.call(context, i) ??
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant,
                    ),
              ),
            );
          } else {
            rows.add(SizedBox(height: rowSpacing));
          }
        }
      }

      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ..._buildChartHeader(
            titleWidget: titleWidget,
            title: title,
            resolvedTitleStyle: resolvedTitleStyle,
            titleTextAlign: style.titleTextAlign,
            titleBottomSpacing: titleBottomSpacing,
          ),
          ...rows,
        ],
      );
    }

    if (!wrapInCard) {
      return body;
    }

    return AppSectionCard(
      color: cardColor,
      padding: cardPadding,
      child: body,
    );
  }
}

List<Widget> _buildChartHeader({
  required Widget? titleWidget,
  required String? title,
  required TextStyle? resolvedTitleStyle,
  required TextAlign? titleTextAlign,
  required double titleBottomSpacing,
}) {
  if (titleWidget != null) {
    return <Widget>[
      titleWidget,
      SizedBox(height: titleBottomSpacing),
    ];
  }

  if (title == null || title.trim().isEmpty) {
    return const <Widget>[];
  }

  return <Widget>[
    Text(
      title,
      style: resolvedTitleStyle,
      textAlign: titleTextAlign,
    ),
    SizedBox(height: titleBottomSpacing),
  ];
}

class _LoadingRows extends StatelessWidget {
  const _LoadingRows({
    required this.rowCount,
    required this.rowSpacing,
    required this.barHeight,
    required this.barRadius,
    required this.trackColor,
    required this.barColor,
    required this.rowPadding,
    required this.gapSm,
    required this.titleWidget,
    required this.title,
    required this.resolvedTitleStyle,
    required this.titleTextAlign,
    required this.titleBottomSpacing,
  });

  final int rowCount;
  final double rowSpacing;
  final double barHeight;
  final BorderRadiusGeometry barRadius;
  final Color trackColor;
  final Color barColor;
  final EdgeInsetsGeometry? rowPadding;
  final double gapSm;
  final Widget? titleWidget;
  final String? title;
  final TextStyle? resolvedTitleStyle;
  final TextAlign? titleTextAlign;
  final double titleBottomSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholderStyle = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    final rows = <Widget>[];
    for (var i = 0; i < rowCount; i++) {
      if (i > 0) {
        rows.add(SizedBox(height: rowSpacing));
      }
      rows.add(
        Padding(
          padding: rowPadding ?? EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text('Carregando…', style: placeholderStyle),
                  ),
                  SizedBox(
                    width: 40,
                    height: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: gapSm),
              ClipRRect(
                borderRadius: barRadius,
                child: LinearProgressIndicator(
                  minHeight: barHeight,
                  backgroundColor: trackColor,
                  color: barColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ..._buildChartHeader(
          titleWidget: titleWidget,
          title: title,
          resolvedTitleStyle: resolvedTitleStyle,
          titleTextAlign: titleTextAlign,
          titleBottomSpacing: titleBottomSpacing,
        ),
        ...rows,
      ],
    );
  }
}

class _AppHorizontalProgressRow<T> extends StatelessWidget {
  const _AppHorizontalProgressRow({
    required this.item,
    required this.labelBuilder,
    required this.rowLeadingBuilder,
    required this.rowTooltipBuilder,
    required this.displayValue,
    required this.rowMaxValue,
    required this.normalized,
    required this.barColor,
    required this.trackColor,
    required this.barGradient,
    required this.barHeight,
    required this.barRadius,
    required this.rowPadding,
    required this.labelTextStyle,
    required this.valueTextStyle,
    required this.labelTextAlign,
    required this.valueTextAlign,
    required this.leadingSpacing,
    required this.gapSm,
    this.valueLabelBuilder,
    this.valueLabelMode = AppHorizontalProgressValueLabelMode.auto,
    this.onItemTap,
    this.barAnimationDuration,
  });

  final T item;
  final AppHorizontalProgressLabelBuilder<T> labelBuilder;
  final AppHorizontalProgressRowLeadingBuilder<T>? rowLeadingBuilder;
  final AppHorizontalProgressTooltipBuilder<T>? rowTooltipBuilder;
  final AppHorizontalProgressValueLabelBuilder<T>? valueLabelBuilder;
  final AppHorizontalProgressValueLabelMode valueLabelMode;
  final double displayValue;
  final double rowMaxValue;
  final double normalized;
  final Color barColor;
  final Color trackColor;
  final Gradient? barGradient;
  final double barHeight;
  final BorderRadiusGeometry barRadius;
  final EdgeInsetsGeometry? rowPadding;
  final TextStyle? labelTextStyle;
  final TextStyle? valueTextStyle;
  final TextAlign? labelTextAlign;
  final TextAlign? valueTextAlign;
  final double leadingSpacing;
  final double gapSm;
  final void Function(T item)? onItemTap;
  final Duration? barAnimationDuration;

  @override
  Widget build(BuildContext context) {
    final valueLabel =
        valueLabelBuilder?.call(
          item,
          displayValue,
          rowMaxValue,
        ) ??
        defaultHorizontalProgressValueLabel(
          displayValue: displayValue,
          rowMaxValue: rowMaxValue,
          mode: valueLabelMode,
        );

    final labelText = labelBuilder(item);
    final leading = rowLeadingBuilder?.call(context, item);
    final tooltipMessage = rowTooltipBuilder?.call(
      item,
      displayValue,
      rowMaxValue,
    );

    final content = Padding(
      padding: rowPadding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (leading != null) ...<Widget>[
                leading,
                SizedBox(width: leadingSpacing),
              ],
              Expanded(
                child: Text(
                  labelText,
                  style: labelTextStyle,
                  textAlign: labelTextAlign,
                ),
              ),
              SizedBox(width: gapSm),
              Text(
                valueLabel,
                style: valueTextStyle,
                textAlign: valueTextAlign,
              ),
            ],
          ),
          SizedBox(height: gapSm),
          ExcludeSemantics(
            child: _AnimatedDeterminateBar(
              target: normalized,
              duration: barAnimationDuration,
              minHeight: barHeight,
              trackColor: trackColor,
              barColor: barColor,
              barGradient: barGradient,
              borderRadius: barRadius,
            ),
          ),
        ],
      ),
    );

    Widget child = content;
    if (onItemTap != null) {
      child = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => onItemTap!(item),
          borderRadius: BorderRadius.circular(4),
          child: content,
        ),
      );
    }
    if (tooltipMessage != null && tooltipMessage.trim().isNotEmpty) {
      child = Tooltip(message: tooltipMessage, child: child);
    }

    return Semantics(
      label: '$labelText. $valueLabel.',
      container: true,
      child: child,
    );
  }
}

class _AnimatedDeterminateBar extends StatelessWidget {
  const _AnimatedDeterminateBar({
    required this.target,
    required this.duration,
    required this.minHeight,
    required this.trackColor,
    required this.barColor,
    required this.barGradient,
    required this.borderRadius,
  });

  final double target;
  final Duration? duration;
  final double minHeight;
  final Color trackColor;
  final Color barColor;
  final Gradient? barGradient;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    if (duration == null) {
      return _DeterminateBar(
        value: target,
        minHeight: minHeight,
        trackColor: trackColor,
        barColor: barColor,
        barGradient: barGradient,
        borderRadius: borderRadius,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: target),
      duration: duration!,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return _DeterminateBar(
          value: animatedValue,
          minHeight: minHeight,
          trackColor: trackColor,
          barColor: barColor,
          barGradient: barGradient,
          borderRadius: borderRadius,
        );
      },
    );
  }
}

class _DeterminateBar extends StatelessWidget {
  const _DeterminateBar({
    required this.value,
    required this.minHeight,
    required this.trackColor,
    required this.barColor,
    required this.barGradient,
    required this.borderRadius,
  });

  final double value;
  final double minHeight;
  final Color trackColor;
  final Color barColor;
  final Gradient? barGradient;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0);
    return SizedBox(
      height: minHeight,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: trackColor,
              ),
            ),
            if (clampedValue > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: clampedValue,
                  child: SizedBox.expand(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: barGradient == null ? barColor : null,
                        gradient: barGradient,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
