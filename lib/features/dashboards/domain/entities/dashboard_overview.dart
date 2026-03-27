import 'package:colmeia/features/dashboards/domain/entities/dashboard_chart_point.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_detail_highlight.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_summary_metric.dart';

class DashboardOverview {
  const DashboardOverview({
    required this.summaryMetrics,
    required this.revenuePoints,
    required this.sellerPerformancePoints,
    required this.operationalHighlights,
  });

  final List<DashboardSummaryMetric> summaryMetrics;
  final List<DashboardChartPoint> revenuePoints;
  final List<DashboardChartPoint> sellerPerformancePoints;
  final List<DashboardDetailHighlight> operationalHighlights;
}
