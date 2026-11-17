import 'dart:math' as math;

import 'package:colmeia/core/layout/app_breakpoints.dart';

int resolveMetricGridColumns({
  required double width,
  required double gap,
  required double textScale,
  required int narrowColumns,
  required int wideColumns,
  required int extraWideColumns,
}) {
  final preferred = width >= AppBreakpoints.kpiGridExtraWide
      ? extraWideColumns
      : width >= AppBreakpoints.kpiGridWide
      ? wideColumns
      : narrowColumns;
  final minimumWidth = AppBreakpoints.kpiTileMinWidth * math.max(1, textScale);
  final capacity = ((width + gap) / (minimumWidth + gap)).floor();
  return math.max(1, math.min(preferred, capacity));
}
