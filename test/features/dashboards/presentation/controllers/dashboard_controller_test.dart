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
      final repository = _QueuedDashboardRepository(
        <Future<AppResult<DashboardOverview>>>[
          Future<AppResult<DashboardOverview>>.value(
            Success<DashboardOverview, AppFailure>(_overview('Loja 03')),
          ),
        ],
      );
      final controller = DashboardController(
        LoadDashboardOverviewUseCase(repository),
      );

      await controller.loadOverview(
        userId: 'demo-user',
        storeId: StoreId('03'),
      );

      check(controller.overview).isNotNull();
      check(controller.overview!.summaryMetrics.single.title).equals('Loja 03');
      check(controller.errorMessage).isNull();
      check(controller.hasContent).isTrue();
      check(controller.isLoadingInitial).isFalse();
      check(controller.isRefreshing).isFalse();
      check(repository.requestedPolicies.single).equals(
        DashboardLoadPolicy.defaultLoad,
      );
    });

    test(
      'should keep content visible and expose refresh state '
      'during manual refresh',
      () async {
        final refreshCompleter = Completer<AppResult<DashboardOverview>>();
        final repository = _QueuedDashboardRepository(
          <Future<AppResult<DashboardOverview>>>[
            Future<AppResult<DashboardOverview>>.value(
              Success<DashboardOverview, AppFailure>(_overview('Atual')),
            ),
            refreshCompleter.future,
          ],
        );
        final controller = DashboardController(
          LoadDashboardOverviewUseCase(repository),
        );

        await controller.loadOverview(
          userId: 'demo-user',
          storeId: StoreId('03'),
        );

        final refreshFuture = controller.refreshOverview(
          userId: 'demo-user',
          storeId: StoreId('03'),
        );

        await Future<void>.delayed(Duration.zero);

        check(controller.isRefreshing).isTrue();
        check(controller.isLoadingInitial).isFalse();
        check(controller.overview).isNotNull();
        check(controller.overview!.summaryMetrics.single.title).equals('Atual');

        refreshCompleter.complete(
          const Failure<DashboardOverview, AppFailure>(
            UnknownFailure(
              message: 'Refresh failed',
              userMessage: 'Nao foi possivel atualizar o dashboard.',
            ),
          ),
        );

        await refreshFuture;

        check(controller.isRefreshing).isFalse();
        check(controller.overview).isNotNull();
        check(controller.overview!.summaryMetrics.single.title).equals('Atual');
        check(controller.errorMessage).equals(
          'Nao foi possivel atualizar o dashboard.',
        );
        check(repository.requestedPolicies).deepEquals(<DashboardLoadPolicy>[
          DashboardLoadPolicy.defaultLoad,
          DashboardLoadPolicy.forceRefresh,
        ]);
      },
    );

    test('should clear stale content when loading a different store', () async {
      final secondLoadCompleter = Completer<AppResult<DashboardOverview>>();
      final repository = _QueuedDashboardRepository(
        <Future<AppResult<DashboardOverview>>>[
          Future<AppResult<DashboardOverview>>.value(
            Success<DashboardOverview, AppFailure>(_overview('Loja 03')),
          ),
          secondLoadCompleter.future,
        ],
      );
      final controller = DashboardController(
        LoadDashboardOverviewUseCase(repository),
      );

      await controller.loadOverview(
        userId: 'demo-user',
        storeId: StoreId('03'),
      );

      final secondLoadFuture = controller.loadOverview(
        userId: 'demo-user',
        storeId: StoreId('08'),
      );

      await Future<void>.delayed(Duration.zero);

      check(controller.overview).isNull();
      check(controller.hasContent).isFalse();
      check(controller.isLoadingInitial).isTrue();
      check(controller.isRefreshing).isFalse();

      secondLoadCompleter.complete(
        Success<DashboardOverview, AppFailure>(_overview('Loja 08')),
      );

      await secondLoadFuture;

      check(controller.overview).isNotNull();
      check(controller.overview!.summaryMetrics.single.title).equals('Loja 08');
    });

    test('should ignore stale responses when a newer request wins', () async {
      final firstLoadCompleter = Completer<AppResult<DashboardOverview>>();
      final secondLoadCompleter = Completer<AppResult<DashboardOverview>>();
      final repository = _QueuedDashboardRepository(
        <Future<AppResult<DashboardOverview>>>[
          firstLoadCompleter.future,
          secondLoadCompleter.future,
        ],
      );
      final controller = DashboardController(
        LoadDashboardOverviewUseCase(repository),
      );

      final firstLoadFuture = controller.loadOverview(
        userId: 'demo-user',
        storeId: StoreId('03'),
      );
      final secondLoadFuture = controller.loadOverview(
        userId: 'demo-user',
        storeId: StoreId('08'),
      );

      firstLoadCompleter.complete(
        Success<DashboardOverview, AppFailure>(_overview('Loja 03')),
      );
      await firstLoadFuture;

      check(controller.overview).isNull();
      check(controller.isLoadingInitial).isTrue();

      secondLoadCompleter.complete(
        Success<DashboardOverview, AppFailure>(_overview('Loja 08')),
      );

      await secondLoadFuture;

      check(controller.overview).isNotNull();
      check(controller.overview!.summaryMetrics.single.title).equals('Loja 08');
      check(controller.isLoadingInitial).isFalse();
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
    DashboardLoadPolicy policy = DashboardLoadPolicy.defaultLoad,
  }) {
    return _resultFuture;
  }
}

class _QueuedDashboardRepository implements DashboardRepository {
  _QueuedDashboardRepository(this._results);

  final List<Future<AppResult<DashboardOverview>>> _results;
  final List<DashboardLoadPolicy> requestedPolicies = <DashboardLoadPolicy>[];
  int _index = 0;

  @override
  Future<AppResult<DashboardOverview>> loadOverview({
    required String userId,
    required StoreId storeId,
    DashboardLoadPolicy policy = DashboardLoadPolicy.defaultLoad,
  }) {
    requestedPolicies.add(policy);
    return _results[_index++];
  }
}

DashboardOverview _overview(String title) {
  return DashboardOverview(
    summaryMetrics: <DashboardSummaryMetric>[
      DashboardSummaryMetric(
        title: title,
        value: r'R$ 128,4 mil',
        deltaLabel: '+8,2% vs ontem',
        icon: DashboardSummaryMetricIcon.trendingUp,
      ),
    ],
    revenuePoints: const <DashboardChartPoint>[
      DashboardChartPoint(label: 'Seg', value: 92000),
    ],
    sellerPerformancePoints: const <DashboardChartPoint>[
      DashboardChartPoint(label: 'Amanda', value: 32400),
    ],
    operationalHighlights: const <DashboardDetailHighlight>[
      DashboardDetailHighlight(
        title: 'Ruptura controlada',
        subtitle: 'Itens criticos abaixo do limite nas ultimas 24h.',
        emphasis: '2 SKUs sob monitoramento',
      ),
    ],
    aiInsight: const DashboardAiInsight(
      title: 'Insight de IA',
      body: 'Corpo',
      ctaLabel: 'Aplicar',
    ),
    categoryShares: const <DashboardCategoryShare>[
      DashboardCategoryShare(label: 'A', percent: 50),
      DashboardCategoryShare(label: 'B', percent: 50),
    ],
  );
}
