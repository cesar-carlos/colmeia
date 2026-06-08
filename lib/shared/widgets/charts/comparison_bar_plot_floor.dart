import 'dart:math' as math;

import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:flutter/foundation.dart';

/// Applies optional minimum column heights for readability. Each point keeps
/// the true metric in [AppChartPoint.value]; when a lift is applied,
/// [AppChartPoint.plottedValue] holds the height used for drawing only.
List<AppChartPoint> applyComparisonBarPlotHeightFloor(
  List<AppChartPoint> points,
  double minShareOfMax, {
  required bool strictLinearBarHeights,
}) {
  if (strictLinearBarHeights || minShareOfMax <= 0 || points.isEmpty) {
    return points;
  }
  var maxPositive = 0.0;
  for (final p in points) {
    final v = p.value.toDouble();
    if (v > maxPositive) {
      maxPositive = v;
    }
  }
  if (maxPositive <= 0) {
    return points;
  }
  final denom = comparisonBarDenominatorForPlotFloor(maxPositive);
  final floor = denom * minShareOfMax;
  return points
      .map((p) {
        final v = p.value.toDouble();
        if (v > 0 && v < floor) {
          return AppChartPoint(
            label: p.label,
            value: p.value,
            plottedValue: floor,
          );
        }
        return AppChartPoint(label: p.label, value: p.value);
      })
      .toList(growable: false);
}

/// Upper bound of the Y range used only to derive a visible floor for tiny
/// bars. Mirrors common axis steps so the floor tracks an approximate axis
/// maximum, not only the largest category.
double comparisonBarDenominatorForPlotFloor(double maxPositive) {
  if (maxPositive <= 0 || !maxPositive.isFinite) {
    return 0;
  }
  return comparisonBarAxisSpreadNiceCeil(maxPositive * 1.32);
}

/// Upper bound for a numeric Y-axis from series values only (bars vs line).
double? comboNumericAxisMaximum(
  Iterable<num> values, {
  bool includeOuterLabelHeadroom = false,
}) {
  var maxPositive = 0.0;
  for (final value in values) {
    final v = value.toDouble();
    if (v > maxPositive) {
      maxPositive = v;
    }
  }
  if (maxPositive <= 0 || !maxPositive.isFinite) {
    return null;
  }
  final factor = includeOuterLabelHeadroom ? 1.12 : 1.05;
  return comparisonBarAxisSpreadNiceCeil(maxPositive * factor);
}

double comparisonBarAxisSpreadNiceCeil(double v) {
  if (v <= 0 || !v.isFinite) {
    return 0;
  }
  final log10 = math.log(v) / math.ln10;
  var magnitude = math.pow(10, log10.floor()).toDouble();
  if (magnitude <= 0 || !magnitude.isFinite) {
    magnitude = 1;
  }
  const multipliers = <double>[1, 2, 5, 10];
  while (true) {
    for (final m in multipliers) {
      final candidate = m * magnitude;
      if (candidate >= v) {
        return candidate;
      }
    }
    magnitude *= 10;
    if (!magnitude.isFinite) {
      return v;
    }
  }
}

/// When max/min among positive values exceeds [threshold], data may need a
/// second look (units, aggregation, outliers).
bool comparisonBarValuesHaveExtremeSpread(
  List<num> values, {
  double threshold = 10000,
}) {
  final pos = values
      .map((v) => v.toDouble())
      .where((v) => v > 0)
      .toList(growable: false);
  if (pos.length < 2) {
    return false;
  }
  final minV = pos.reduce(math.min);
  final maxV = pos.reduce(math.max);
  return minV > 0 && maxV / minV >= threshold;
}

void debugLogSuspiciousComparisonBarSpread(List<num> values) {
  if (!kDebugMode) {
    return;
  }
  if (!comparisonBarValuesHaveExtremeSpread(values)) {
    return;
  }
  final pos = values.map((v) => v.toDouble()).where((v) => v > 0).toList();
  final minV = pos.reduce(math.min);
  final maxV = pos.reduce(math.max);
  debugPrint(
    'AppComparisonBarChart: large value spread (max/min=${(maxV / minV).toStringAsFixed(0)}). '
    'Verify units and aggregation.',
  );
}
