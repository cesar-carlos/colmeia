import 'package:colmeia/shared/widgets/charts/chart_pan_footnote_column.dart';
import 'package:flutter/material.dart';

/// Wraps a category-viewport-pan chart with optional semantics label/hint.
///
/// Shared by `SyncfusionComparisonBarChart` and `SyncfusionComboChart`.
Widget wrapCartesianCategoryViewportPanSemantics({
  required Widget chart,
  required bool useCategoryViewportPan,
  required String? categoryViewportPanSemanticsLabel,
  required String? horizontalScrollSemanticsHint,
}) {
  if (!useCategoryViewportPan) {
    return chart;
  }
  final panLabel = categoryViewportPanSemanticsLabel?.trim();
  final hint = horizontalScrollSemanticsHint?.trim();
  if ((panLabel == null || panLabel.isEmpty) &&
      (hint == null || hint.isEmpty)) {
    return chart;
  }
  return Semantics(
    label: (panLabel != null && panLabel.isNotEmpty) ? panLabel : null,
    hint: (hint != null && hint.isNotEmpty) ? hint : null,
    child: chart,
  );
}

/// Non-auto-scroll layout: optional pan footnote column or a fixed-size chart.
///
/// Shared by `SyncfusionComparisonBarChart` and `SyncfusionComboChart`.
Widget buildCartesianNonAutoScrollLayout({
  required bool showPanFootnote,
  required double layoutWidth,
  required String footnoteText,
  required Widget panFootnotePlot,
  required Widget sizedChart,
}) {
  if (!showPanFootnote) {
    return sizedChart;
  }
  return ChartPanFootnoteColumn(
    plot: SizedBox(width: layoutWidth, child: panFootnotePlot),
    footnoteText: footnoteText,
  );
}
