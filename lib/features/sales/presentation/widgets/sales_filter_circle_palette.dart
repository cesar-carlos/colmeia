import 'package:flutter/material.dart';

/// Palette for the circular "filter trigger" affordance used by sales
/// surfaces (the card filter trigger and the single-agent picker share the
/// same visual identity).
///
/// These colors are intentionally fixed brand accents rather than theme
/// tokens: the design calls for the same peach/brown pair regardless of
/// light/dark theme so the filter chip stays recognizable as a
/// sales-domain affordance.
abstract final class SalesFilterCirclePalette {
  /// Peach fill used as the circle background.
  static const Color fill = Color(0xFFFFE5D9);

  /// Dark brown used by the inner glyph when the filter is in its
  /// rest/active state. Callers may switch to the theme `onSurfaceVariant`
  /// when the affordance is in a disabled state.
  static const Color icon = Color(0xFF5D4037);
}
