import 'package:flutter/material.dart';

/// One slice + legend row for the category donut dashboard card.
///
/// [value] drives the doughnut angles (typically currency, units, or shares).
/// Labels for the legend default from [value] and the sum of all segments.
class AppCategoryDonutSegment {
  const AppCategoryDonutSegment({
    required this.label,
    required this.value,
    this.valueLabel,
    this.percentLabel,
    this.color,
  });

  final String label;
  final num value;

  /// Legend primary line (e.g. formatted currency). If null, [value] is shown.
  final String? valueLabel;

  /// Legend secondary line (e.g. `40%`). If null, computed from [value] / total.
  final String? percentLabel;

  /// Slice color; when null, the chart palette assigns by index.
  final Color? color;

  String resolveValueLabel() => valueLabel ?? value.toString();

  String resolvePercentLabel(num totalValue) {
    if (percentLabel != null) {
      return percentLabel!;
    }
    if (totalValue <= 0) {
      return '—';
    }
    final p = value / totalValue * 100;
    return '${p.round()}%';
  }
}

extension AppCategoryDonutSegmentListX on List<AppCategoryDonutSegment> {
  /// Sum of segment values; minimum 1.0 to avoid division by zero.
  num get donutWeightTotal {
    final s = fold<num>(0, (a, x) => a + x.value);
    if (s <= 0) {
      return 1;
    }
    return s;
  }
}
