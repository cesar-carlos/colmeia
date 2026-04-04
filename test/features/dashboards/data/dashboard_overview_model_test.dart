import 'package:checks/checks.dart';
import 'package:colmeia/features/dashboards/data/models/dashboard_overview_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardOverviewModel.fromJson', () {
    test('should parse categoryMixTotalRevenue when present', () {
      final model = DashboardOverviewModel.fromJson(
        _minimalJson(
          categoryMixTotalRevenue: 1_500_000,
        ),
      );

      check(model.categoryMixTotalRevenue).equals(1_500_000);
      check(model.toEntity().categoryMixTotalRevenue).equals(1_500_000);
    });

    test('should leave categoryMixTotalRevenue null when absent', () {
      final model = DashboardOverviewModel.fromJson(_minimalJson());

      check(model.categoryMixTotalRevenue).isNull();
      check(model.toEntity().categoryMixTotalRevenue).isNull();
    });
  });
}

Map<String, dynamic> _minimalJson({double? categoryMixTotalRevenue}) {
  return <String, dynamic>{
    'summaryMetrics': <Map<String, dynamic>>[
      <String, dynamic>{
        'title': 'T',
        'value': '1',
        'deltaLabel': null,
        'icon': 'payments',
      },
    ],
    'revenuePoints': <Map<String, dynamic>>[
      <String, dynamic>{'label': 'A', 'value': 1},
    ],
    'sellerPerformancePoints': <Map<String, dynamic>>[],
    'operationalHighlights': <Map<String, dynamic>>[],
    'aiInsight': <String, dynamic>{
      'title': 'i',
      'body': 'b',
      'ctaLabel': 'c',
    },
    'categoryShares': <Map<String, dynamic>>[
      <String, dynamic>{
        'label': 'Cat',
        'percent': 100,
      },
    ],
    'categoryMixTotalRevenue': ?categoryMixTotalRevenue,
  };
}
