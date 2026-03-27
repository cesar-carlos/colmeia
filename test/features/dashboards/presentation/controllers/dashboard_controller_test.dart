import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/dashboards/application/usecases/load_dashboard_overview_use_case.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_ai_insight.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_category_share.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_chart_point.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_detail_highlight.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_overview.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_summary_metric.dart';
import 'package:colmeia/features/dashboards/domain/repositories/dashboard_repository.dart';
import 'package:colmeia/features/dashboards/presentation/controllers/dashboard_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  group('DashboardController', () {
    test('should load overview from use case', () async {
      final controller = DashboardController(
        LoadDashboardOverviewUseCase(_FakeDashboardRepository()),
      );

      await controller.loadOverview(
        userId: 'demo-user',
        storeId: StoreId('03'),
      );

      check(controller.overview).isNotNull();
      check(controller.errorMessage).isNull();
      check(controller.overview!.summaryMetrics.length).equals(1);
    });

    test('should ignore late use case completion after dispose', () async {
      final completer = Completer<AppResult<DashboardOverview>>();
      final controller = DashboardController(
        LoadDashboardOverviewUseCase(
          _PendingDashboardRepository(completer.future),
        ),
      );

      final loadFuture = controller.loadOverview(
        userId: 'demo-user',
        storeId: StoreId('03'),
      );

      await Future<void>.delayed(Duration.zero);
      controller.dispose();

      completer.complete(
        const Success<DashboardOverview, AppFailure>(
          DashboardOverview(
            summaryMetrics: <DashboardSummaryMetric>[
              DashboardSummaryMetric(
                title: 'Faturamento do dia',
                value: r'R$ 128,4 mil',
                deltaLabel: '+8,2% vs ontem',
                icon: DashboardSummaryMetricIcon.trendingUp,
              ),
            ],
            revenuePoints: <DashboardChartPoint>[
              DashboardChartPoint(label: 'Seg', value: 92000),
            ],
            sellerPerformancePoints: <DashboardChartPoint>[
              DashboardChartPoint(label: 'Amanda', value: 32400),
            ],
            operationalHighlights: <DashboardDetailHighlight>[
              DashboardDetailHighlight(
                title: 'Ruptura controlada',
                subtitle: 'Itens criticos abaixo do limite nas ultimas 24h.',
                emphasis: '2 SKUs sob monitoramento',
              ),
            ],
            aiInsight: DashboardAiInsight(
              title: 'Insight de IA',
              body: 'Corpo',
              ctaLabel: 'Aplicar',
            ),
            categoryShares: <DashboardCategoryShare>[
              DashboardCategoryShare(label: 'A', percent: 50),
              DashboardCategoryShare(label: 'B', percent: 50),
            ],
          ),
        ),
      );

      await loadFuture;
    });
  });
}

class _PendingDashboardRepository implements DashboardRepository {
  _PendingDashboardRepository(this._resultFuture);

  final Future<AppResult<DashboardOverview>> _resultFuture;

  @override
  Future<AppResult<DashboardOverview>> loadOverview({
    required String userId,
    required StoreId storeId,
  }) {
    return _resultFuture;
  }
}

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<AppResult<DashboardOverview>> loadOverview({
    required String userId,
    required StoreId storeId,
  }) async {
    return const Success<DashboardOverview, AppFailure>(
      DashboardOverview(
        summaryMetrics: <DashboardSummaryMetric>[
          DashboardSummaryMetric(
            title: 'Faturamento do dia',
            value: r'R$ 128,4 mil',
            deltaLabel: '+8,2% vs ontem',
            icon: DashboardSummaryMetricIcon.trendingUp,
          ),
        ],
        revenuePoints: <DashboardChartPoint>[
          DashboardChartPoint(label: 'Seg', value: 92000),
        ],
        sellerPerformancePoints: <DashboardChartPoint>[
          DashboardChartPoint(label: 'Amanda', value: 32400),
        ],
        operationalHighlights: <DashboardDetailHighlight>[
          DashboardDetailHighlight(
            title: 'Ruptura controlada',
            subtitle: 'Itens criticos abaixo do limite nas ultimas 24h.',
            emphasis: '2 SKUs sob monitoramento',
          ),
        ],
        aiInsight: DashboardAiInsight(
          title: 'Insight de IA',
          body: 'Corpo',
          ctaLabel: 'Aplicar',
        ),
        categoryShares: <DashboardCategoryShare>[
          DashboardCategoryShare(label: 'A', percent: 50),
          DashboardCategoryShare(label: 'B', percent: 50),
        ],
      ),
    );
  }
}
