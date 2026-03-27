import 'package:colmeia/features/dashboards/domain/entities/dashboard_summary_metric.dart';
import 'package:flutter/material.dart';

extension DashboardSummaryMetricIconMaterial on DashboardSummaryMetricIcon {
  IconData get materialIconData => switch (this) {
    DashboardSummaryMetricIcon.trendingUp => Icons.trending_up,
    DashboardSummaryMetricIcon.receiptLong => Icons.receipt_long,
    DashboardSummaryMetricIcon.insights => Icons.insights,
  };
}
