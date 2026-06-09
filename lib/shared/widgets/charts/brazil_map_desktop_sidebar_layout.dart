import 'dart:math' as math;

import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_layout_constants.dart';

/// Pure geometry policy for the optional desktop branch sidebar overlaid on
/// the Brazil store-sales map. Extracted from the chart state so the sizing
/// rules live in one focused, testable place.
abstract final class BrazilMapDesktopSidebarLayout {
  static const double minWidth = 272;
  static const double maxWidth = 336;
  static const double minVisibleMapWidth = 760;
  static const double topInsetBase = 12;

  /// Sidebar width: 24% of the available width, clamped to [minWidth]..[maxWidth].
  static double width(double availableWidth) {
    if (!availableWidth.isFinite) {
      return minWidth;
    }
    return (availableWidth * 0.24).clamp(minWidth, maxWidth);
  }

  /// Whether the sidebar fits without squeezing the visible map below
  /// [minVisibleMapWidth] (and only on desktop-class widths).
  static bool shouldShow({
    required bool enabled,
    required double availableWidth,
    required double sidebarWidth,
    required double horizontalInset,
  }) {
    if (!enabled) {
      return false;
    }
    if (!availableWidth.isFinite || availableWidth < AppBreakpoints.desktop) {
      return false;
    }
    final remainingVisibleMapWidth =
        availableWidth - sidebarWidth - (horizontalInset * 2);
    return remainingVisibleMapWidth >= minVisibleMapWidth;
  }

  static double maxHeight({
    required double mapTileHeight,
    required double topInset,
  }) {
    const bottomInset = BrazilMapLayoutConstants.desktopSidebarBottomInset;
    final availableHeight = mapTileHeight - topInset - bottomInset;
    if (availableHeight <= 0) {
      return 0;
    }
    final proportionalCap =
        mapTileHeight *
        BrazilMapLayoutConstants.desktopSidebarProportionalCapFactor;
    final cappedHeight = availableHeight < proportionalCap
        ? availableHeight
        : proportionalCap;
    final lower = math.min(
      BrazilMapLayoutConstants.desktopSidebarMinHeight,
      availableHeight,
    );
    return cappedHeight.clamp(lower, availableHeight);
  }
}
