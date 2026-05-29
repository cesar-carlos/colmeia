import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Layout geometry shared by the cartesian engines (`SyncfusionComparisonBarChart`,
/// `SyncfusionComboChart`) to decide between fit-to-width, category viewport
/// pan, and horizontal scroll with an optional sticky Y-axis strip.
///
/// Centralizes the (subtle, previously duplicated) width/crowding math so both
/// engines compute slots identically; each engine keeps its own widget-tree
/// assembly (legend reserve, builders) on top of these values.
class CartesianScrollGeometry {
  const CartesianScrollGeometry({
    required this.layoutWidth,
    required this.itemCount,
    required this.useCategoryViewportPan,
    required this.slotDenom,
    required this.showPanFootnote,
    required this.footnoteText,
  });

  /// Resolves the base geometry from layout constraints and crowding.
  factory CartesianScrollGeometry.resolve({
    required BoxConstraints constraints,
    required double mediaWidth,
    required double minSlotWidth,
    required int itemCount,
    required bool enableAutoScroll,
    required int? categoryAutoScrollingDelta,
    required String? categoryViewportFootnote,
  }) {
    var layoutWidth =
        constraints.hasBoundedWidth &&
            constraints.maxWidth.isFinite &&
            constraints.maxWidth > 0
        ? constraints.maxWidth
        : mediaWidth;
    if (!layoutWidth.isFinite || layoutWidth <= 0) {
      layoutWidth = minSlotWidth * itemCount;
    }

    final delta = categoryAutoScrollingDelta;
    final crowded = itemCount > 1 && (layoutWidth / itemCount) < minSlotWidth;
    final useCategoryViewportPan =
        !enableAutoScroll &&
        delta != null &&
        delta > 0 &&
        itemCount > delta &&
        crowded;
    final slotDenom = useCategoryViewportPan
        ? math.min(itemCount, delta)
        : itemCount;
    final footRaw = categoryViewportFootnote?.trim();
    final showPanFootnote =
        useCategoryViewportPan && footRaw != null && footRaw.isNotEmpty;

    return CartesianScrollGeometry(
      layoutWidth: layoutWidth,
      itemCount: itemCount,
      useCategoryViewportPan: useCategoryViewportPan,
      slotDenom: slotDenom,
      showPanFootnote: showPanFootnote,
      footnoteText: footRaw ?? '',
    );
  }

  final double layoutWidth;
  final int itemCount;
  final bool useCategoryViewportPan;
  final int slotDenom;
  final bool showPanFootnote;
  final String footnoteText;

  /// Slot width used on the non-auto-scroll path.
  double get nonScrollSlotWidth => layoutWidth / slotDenom;

  /// Resolves the horizontal-scroll plot metrics (used on the auto-scroll
  /// path), accounting for the optional sticky Y-axis strip width.
  CartesianScrollPlot resolveScrollPlot({
    required double minSlotWidth,
    required bool sticky,
    required double stickyWidth,
  }) {
    final requiredFull = math.max(layoutWidth, minSlotWidth * itemCount);
    final needsScroll = requiredFull > layoutWidth;
    final effectiveStickyWidth = sticky ? stickyWidth : 0.0;
    final plotViewport = (layoutWidth - effectiveStickyWidth)
        .clamp(1, double.infinity)
        .toDouble();
    final requiredPlot = math.max(plotViewport, minSlotWidth * itemCount);
    return CartesianScrollPlot(
      needsScroll: needsScroll,
      requiredPlot: requiredPlot,
      slotWidth: requiredPlot / itemCount,
      stickyWidth: effectiveStickyWidth,
    );
  }
}

/// Horizontal-scroll plot metrics derived from [CartesianScrollGeometry].
class CartesianScrollPlot {
  const CartesianScrollPlot({
    required this.needsScroll,
    required this.requiredPlot,
    required this.slotWidth,
    required this.stickyWidth,
  });

  final bool needsScroll;
  final double requiredPlot;
  final double slotWidth;
  final double stickyWidth;
}
