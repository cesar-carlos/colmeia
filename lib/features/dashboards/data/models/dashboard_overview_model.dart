import 'dart:convert';

import 'package:colmeia/features/dashboards/domain/entities/dashboard_chart_point.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_detail_highlight.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_overview.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_summary_metric.dart';

class DashboardOverviewModel {
  const DashboardOverviewModel({
    required this.summaryMetrics,
    required this.revenuePoints,
    required this.sellerPerformancePoints,
    required this.operationalHighlights,
  });

  factory DashboardOverviewModel.fromJson(Map<String, dynamic> json) {
    final summaryMetricsJson = json['summaryMetrics'] as List<dynamic>;
    final revenuePointsJson = json['revenuePoints'] as List<dynamic>;
    final sellerPerformancePointsJson =
        json['sellerPerformancePoints'] as List<dynamic>? ?? <dynamic>[];
    final operationalHighlightsJson =
        json['operationalHighlights'] as List<dynamic>? ?? <dynamic>[];

    return DashboardOverviewModel(
      summaryMetrics: summaryMetricsJson
          .map(
            (item) {
              final metricJson = item as Map<String, dynamic>;

              return DashboardSummaryMetric(
                title: metricJson['title'] as String,
                value: metricJson['value'] as String,
                deltaLabel: metricJson['deltaLabel'] as String,
                icon: DashboardSummaryMetricIcon.fromWireName(
                  metricJson['icon'] as String,
                ),
              );
            },
          )
          .toList(growable: false),
      revenuePoints: revenuePointsJson
          .map(
            (item) {
              final pointJson = item as Map<String, dynamic>;

              return DashboardChartPoint(
                label: pointJson['label'] as String,
                value: (pointJson['value'] as num).toDouble(),
              );
            },
          )
          .toList(growable: false),
      sellerPerformancePoints: sellerPerformancePointsJson
          .map(
            (item) {
              final pointJson = item as Map<String, dynamic>;

              return DashboardChartPoint(
                label: pointJson['label'] as String,
                value: (pointJson['value'] as num).toDouble(),
              );
            },
          )
          .toList(growable: false),
      operationalHighlights: operationalHighlightsJson
          .map(
            (item) {
              final highlightJson = item as Map<String, dynamic>;

              return DashboardDetailHighlight(
                title: highlightJson['title'] as String,
                subtitle: highlightJson['subtitle'] as String,
                emphasis: highlightJson['emphasis'] as String,
              );
            },
          )
          .toList(growable: false),
    );
  }

  factory DashboardOverviewModel.decode(String raw) {
    return DashboardOverviewModel.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  final List<DashboardSummaryMetric> summaryMetrics;
  final List<DashboardChartPoint> revenuePoints;
  final List<DashboardChartPoint> sellerPerformancePoints;
  final List<DashboardDetailHighlight> operationalHighlights;

  DashboardOverview toEntity() {
    return DashboardOverview(
      summaryMetrics: summaryMetrics,
      revenuePoints: revenuePoints,
      sellerPerformancePoints: sellerPerformancePoints,
      operationalHighlights: operationalHighlights,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'summaryMetrics': summaryMetrics
          .map((metric) {
            return <String, Object?>{
              'title': metric.title,
              'value': metric.value,
              'deltaLabel': metric.deltaLabel,
              'icon': metric.icon.wireName,
            };
          })
          .toList(growable: false),
      'revenuePoints': revenuePoints
          .map((point) {
            return <String, Object?>{
              'label': point.label,
              'value': point.value,
            };
          })
          .toList(growable: false),
      'sellerPerformancePoints': sellerPerformancePoints
          .map((point) {
            return <String, Object?>{
              'label': point.label,
              'value': point.value,
            };
          })
          .toList(growable: false),
      'operationalHighlights': operationalHighlights
          .map((highlight) {
            return <String, Object?>{
              'title': highlight.title,
              'subtitle': highlight.subtitle,
              'emphasis': highlight.emphasis,
            };
          })
          .toList(growable: false),
    };
  }

  String encode() => jsonEncode(toJson());
}
