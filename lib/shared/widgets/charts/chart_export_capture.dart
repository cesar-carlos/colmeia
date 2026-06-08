import 'dart:math' as math;

import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:flutter/material.dart';

/// Upper bound on logical width for offscreen cartesian chart export captures.
///
/// Prevents excessive memory use and raster cost when category counts are very
/// large; the chart may compress visually in the PDF via layout fitting.
const double kCartesianChartExportMaxLogicalWidth = 4096;

/// Logical width that fits every category at [minSlotWidth] without horizontal
/// scroll — used for offscreen PDF export captures.
double cartesianChartExportWidth({
  required int itemCount,
  required double minSlotWidth,
}) {
  final rawWidth = itemCount <= 0
      ? minSlotWidth.clamp(1, double.infinity)
      : minSlotWidth * itemCount;
  return math.min(rawWidth, kCartesianChartExportMaxLogicalWidth).toDouble();
}

/// Minimum bar slot width resolved the same way as the comparison bar engine.
double comparisonBarMinSlotWidth({double? minBarWidth}) {
  return minBarWidth ??
      AppChartEngineCartesianBarGeometryDefaults.minCategorySlotWidth;
}

/// Sizes [chart] for a full-width cartesian export capture (no scroll viewport).
Widget wrapCartesianChartForPdfExport({
  required BuildContext context,
  required Widget chart,
  required int itemCount,
  required double minSlotWidth,
  double? height,
}) {
  final width = cartesianChartExportWidth(
    itemCount: itemCount,
    minSlotWidth: minSlotWidth,
  );
  return ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: SizedBox(
      width: width,
      height: height,
      child: chart,
    ),
  );
}
