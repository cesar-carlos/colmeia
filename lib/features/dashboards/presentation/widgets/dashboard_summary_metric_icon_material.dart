import 'package:colmeia/features/dashboards/domain/entities/dashboard_summary_metric.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:flutter/material.dart';

extension DashboardSummaryMetricIconMaterial on DashboardSummaryMetricIcon {
  IconData get materialIconData => switch (this) {
    DashboardSummaryMetricIcon.trendingUp => Icons.trending_up,
    DashboardSummaryMetricIcon.trendingDown => Icons.trending_down,
    DashboardSummaryMetricIcon.receiptLong => Icons.receipt_long,
    DashboardSummaryMetricIcon.payments => Icons.payments_outlined,
    DashboardSummaryMetricIcon.insights => Icons.insights,
  };

  /// Pastel tile + icon colors for the KPI leading icon badge.
  (Color background, Color foreground) kpiBadgeColors(AppColors colors) {
    return switch (this) {
      DashboardSummaryMetricIcon.payments => (
        Color.alphaBlend(
          colors.tertiaryContainer.withValues(alpha: 0.72),
          colors.surfaceContainerLowest,
        ),
        colors.onTertiaryContainer,
      ),
      DashboardSummaryMetricIcon.receiptLong => (
        Color.alphaBlend(
          colors.primaryContainer.withValues(alpha: 0.75),
          colors.surfaceContainerLowest,
        ),
        colors.primary,
      ),
      DashboardSummaryMetricIcon.trendingUp => (
        Color.alphaBlend(
          colors.tertiaryContainer.withValues(alpha: 0.72),
          colors.surfaceContainerLowest,
        ),
        colors.tertiary,
      ),
      DashboardSummaryMetricIcon.trendingDown => (
        Color.alphaBlend(
          colors.errorContainer.withValues(alpha: 0.78),
          colors.surfaceContainerLowest,
        ),
        colors.error,
      ),
      DashboardSummaryMetricIcon.insights => (
        Color.alphaBlend(
          colors.secondaryContainer.withValues(alpha: 0.72),
          colors.surfaceContainerLowest,
        ),
        colors.onSecondaryContainer,
      ),
    };
  }
}
