import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/horizontal_progress_chart_math.dart';
import 'package:colmeia/shared/widgets/charts/horizontal_progress_chart_typedefs.dart';
import 'package:flutter/material.dart';

class HorizontalProgressChartRow<T> extends StatelessWidget {
  const HorizontalProgressChartRow({
    required this.item,
    required this.itemIndex,
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
    super.key,
    this.valueLabelBuilder,
    this.valueLabelMode = AppHorizontalProgressValueLabelMode.auto,
    this.onItemTap,
    this.onItemTapEvent,
    this.barAnimationDuration,
  });

  final T item;
  final int itemIndex;
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
  final ValueChanged<AppChartItemTapEvent<T>>? onItemTapEvent;
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 280;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (isCompact)
                Column(
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
                      ],
                    ),
                    SizedBox(height: gapSm / 2),
                    Text(
                      valueLabel,
                      style: valueTextStyle,
                      textAlign: valueTextAlign,
                    ),
                  ],
                )
              else
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
                child: HorizontalProgressAnimatedBar(
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
          );
        },
      ),
    );

    Widget child = content;
    if (onItemTap != null) {
      child = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            onItemTap?.call(item);
            onItemTapEvent?.call(
              AppChartItemTapEvent<T>(item: item, index: itemIndex),
            );
          },
          borderRadius: BorderRadius.circular(4),
          child: content,
        ),
      );
    } else if (onItemTapEvent != null) {
      child = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            onItemTapEvent?.call(
              AppChartItemTapEvent<T>(item: item, index: itemIndex),
            );
          },
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

class HorizontalProgressAnimatedBar extends StatelessWidget {
  const HorizontalProgressAnimatedBar({
    required this.target,
    required this.duration,
    required this.minHeight,
    required this.trackColor,
    required this.barColor,
    required this.barGradient,
    required this.borderRadius,
    super.key,
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
      return HorizontalProgressDeterminateBar(
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
        return HorizontalProgressDeterminateBar(
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

class HorizontalProgressDeterminateBar extends StatelessWidget {
  const HorizontalProgressDeterminateBar({
    required this.value,
    required this.minHeight,
    required this.trackColor,
    required this.barColor,
    required this.barGradient,
    required this.borderRadius,
    super.key,
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
