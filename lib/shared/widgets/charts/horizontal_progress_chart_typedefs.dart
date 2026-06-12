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
