import 'dart:convert';

import 'package:colmeia/features/dashboards/domain/entities/dashboard_ai_insight.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_category_share.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_chart_point.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_detail_highlight.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_overview.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_summary_metric.dart';

const DashboardAiInsight _kDashboardDefaultAiInsight = DashboardAiInsight(
  title: 'Insight de IA',
  body:
      'Aumentar equipe no horário de pico (11h–13h) pode reduzir a perda de '
      'conversão em até 15%.',
  ctaLabel: 'Aplicar estratégia',
);

const List<DashboardCategoryShare> _kDashboardDefaultCategoryShares =
    <DashboardCategoryShare>[
      DashboardCategoryShare(label: 'Bebidas', percent: 42),
      DashboardCategoryShare(label: 'Lanches', percent: 28),
      DashboardCategoryShare(label: 'Mercearia', percent: 18),
      DashboardCategoryShare(label: 'Outros', percent: 12),
    ];

class DashboardOverviewModel {
  const DashboardOverviewModel({
    required this.summaryMetrics,
    required this.revenuePoints,
    required this.sellerPerformancePoints,
    required this.operationalHighlights,
    required this.aiInsight,
    required this.categoryShares,
  });

  factory DashboardOverviewModel.fromJson(Map<String, dynamic> json) {
    final summaryMetricsJson = json['summaryMetrics'] as List<dynamic>;
    final revenuePointsJson = json['revenuePoints'] as List<dynamic>;
    final sellerPerformancePointsJson =
        json['sellerPerformancePoints'] as List<dynamic>? ?? <dynamic>[];
    final operationalHighlightsJson =
        json['operationalHighlights'] as List<dynamic>? ?? <dynamic>[];
    final aiJson = json['aiInsight'] as Map<String, dynamic>?;
    final categoryJson = json['categoryShares'] as List<dynamic>?;

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
      aiInsight: aiJson == null
          ? _kDashboardDefaultAiInsight
          : DashboardAiInsight(
              title:
                  aiJson['title'] as String? ??
                  _kDashboardDefaultAiInsight.title,
              body:
                  aiJson['body'] as String? ?? _kDashboardDefaultAiInsight.body,
              ctaLabel:
                  aiJson['ctaLabel'] as String? ??
                  _kDashboardDefaultAiInsight.ctaLabel,
            ),
      categoryShares: categoryJson == null
          ? _kDashboardDefaultCategoryShares
          : categoryJson
                .map((item) {
                  final row = item as Map<String, dynamic>;
                  return DashboardCategoryShare(
                    label: row['label'] as String,
                    percent: (row['percent'] as num).toDouble(),
                  );
                })
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
  final DashboardAiInsight aiInsight;
  final List<DashboardCategoryShare> categoryShares;

  DashboardOverview toEntity() {
    return DashboardOverview(
      summaryMetrics: summaryMetrics,
      revenuePoints: revenuePoints,
      sellerPerformancePoints: sellerPerformancePoints,
      operationalHighlights: operationalHighlights,
      aiInsight: aiInsight,
      categoryShares: categoryShares,
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
      'aiInsight': <String, Object?>{
        'title': aiInsight.title,
        'body': aiInsight.body,
        'ctaLabel': aiInsight.ctaLabel,
      },
      'categoryShares': categoryShares
          .map((row) {
            return <String, Object?>{
              'label': row.label,
              'percent': row.percent,
            };
          })
          .toList(growable: false),
    };
  }

  String encode() => jsonEncode(toJson());
}
