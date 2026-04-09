import 'package:colmeia/features/overview/domain/entities/overview_summary_metric.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:flutter/material.dart';

extension OverviewSummaryMetricIconMaterial on OverviewSummaryMetricIcon {
  IconData get materialIconData => switch (this) {
    OverviewSummaryMetricIcon.trendingUp => Icons.trending_up,
    OverviewSummaryMetricIcon.trendingDown => Icons.trending_down,
    OverviewSummaryMetricIcon.receiptLong => Icons.receipt_long,
    OverviewSummaryMetricIcon.payments => Icons.payments_outlined,
    OverviewSummaryMetricIcon.insights => Icons.insights,
  };

  /// Pastel tile + icon colors for the KPI leading icon badge.
  (Color background, Color foreground) kpiBadgeColors(AppColors colors) {
    return switch (this) {
      OverviewSummaryMetricIcon.payments => (
        Color.alphaBlend(
          colors.tertiaryContainer.withValues(alpha: 0.72),
          colors.surfaceContainerLowest,
        ),
        colors.onTertiaryContainer,
      ),
      OverviewSummaryMetricIcon.receiptLong => (
        Color.alphaBlend(
          colors.primaryContainer.withValues(alpha: 0.75),
          colors.surfaceContainerLowest,
        ),
        colors.primary,
      ),
      OverviewSummaryMetricIcon.trendingUp => (
        Color.alphaBlend(
          colors.tertiaryContainer.withValues(alpha: 0.72),
          colors.surfaceContainerLowest,
        ),
        colors.tertiary,
      ),
      OverviewSummaryMetricIcon.trendingDown => (
        Color.alphaBlend(
          colors.errorContainer.withValues(alpha: 0.78),
          colors.surfaceContainerLowest,
        ),
        colors.error,
      ),
      OverviewSummaryMetricIcon.insights => (
        Color.alphaBlend(
          colors.secondaryContainer.withValues(alpha: 0.72),
          colors.surfaceContainerLowest,
        ),
        colors.onSecondaryContainer,
      ),
    };
  }
}
