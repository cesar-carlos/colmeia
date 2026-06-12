import 'package:flutter/material.dart';

/// Slightly smaller type within this card (header, legend, center labels).
const double categoryDonutTypographyTightenFactor = 0.92;

/// Transition when the donut center label swaps on selection change.
const Duration categoryDonutCenterLabelSwitchDuration = Duration(
  milliseconds: 280,
);

/// Background highlight transition for a legend row on selection change.
const Duration categoryDonutLegendHighlightDuration = Duration(
  milliseconds: 180,
);

TextStyle tightenCategoryDonutTypographyFontSize(TextStyle style) {
  final fs = style.fontSize;
  if (fs == null) {
    return style;
  }
  return style.copyWith(
    fontSize: fs * categoryDonutTypographyTightenFactor,
  );
}
