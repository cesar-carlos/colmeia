import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/dashboards/application/usecases/load_dashboard_overview_use_case.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_agent_ranking.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_overview.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_payment_kpis.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_payment_method_breakdown.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_user_ranking.dart';
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
            Success<DashboardOverview, AppFailure>(_overview('Pix')),
          ),
        ],
      );
      final controller = DashboardController(
        LoadDashboardOverviewUseCase(repository),
      );

      await controller.loadOverview(userId: 'demo-user');

      check(controller.overview).isNotNull();
      check(controller.overview!.paymentMethods.single.code).equals('Pix');
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
              Success<DashboardOverview, AppFailure>(_overview('Pix')),
            ),
            refreshCompleter.future,
          ],
        );
        final controller = DashboardController(
          LoadDashboardOverviewUseCase(repository),
        );

        await controller.loadOverview(userId: 'demo-user');

        final refreshFuture = controller.refreshOverview(userId: 'demo-user');

        await Future<void>.delayed(Duration.zero);

        check(controller.isRefreshing).isTrue();
        check(controller.isLoadingInitial).isFalse();
        check(controller.overview).isNotNull();
        check(controller.overview!.paymentMethods.single.code).equals('Pix');

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
        check(controller.overview!.paymentMethods.single.code).equals('Pix');
        check(controller.errorMessage).equals(
          'Nao foi possivel atualizar o dashboard.',
        );
        check(repository.requestedPolicies).deepEquals(<DashboardLoadPolicy>[
          DashboardLoadPolicy.defaultLoad,
          DashboardLoadPolicy.forceRefresh,
        ]);
      },
    );

    test('should clear stale content when a second load starts', () async {
      final secondLoadCompleter = Completer<AppResult<DashboardOverview>>();
      final repository = _QueuedDashboardRepository(
        <Future<AppResult<DashboardOverview>>>[
          Future<AppResult<DashboardOverview>>.value(
            Success<DashboardOverview, AppFailure>(_overview('Pix')),
          ),
          secondLoadCompleter.future,
        ],
      );
      final controller = DashboardController(
        LoadDashboardOverviewUseCase(repository),
      );

      await controller.loadOverview(userId: 'demo-user');

      final secondLoadFuture = controller.loadOverview(userId: 'demo-user');

      await Future<void>.delayed(Duration.zero);

      check(controller.overview).isNull();
      check(controller.hasContent).isFalse();
      check(controller.isLoadingInitial).isTrue();
      check(controller.isRefreshing).isFalse();

      secondLoadCompleter.complete(
        Success<DashboardOverview, AppFailure>(_overview('Credito')),
      );

      await secondLoadFuture;

      check(controller.overview).isNotNull();
      check(controller.overview!.paymentMethods.single.code).equals('Credito');
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

      final firstLoadFuture = controller.loadOverview(userId: 'demo-user');
      final secondLoadFuture = controller.loadOverview(userId: 'demo-user');

      firstLoadCompleter.complete(
        Success<DashboardOverview, AppFailure>(_overview('Pix')),
      );
      await firstLoadFuture;

      check(controller.overview).isNull();
      check(controller.isLoadingInitial).isTrue();

      secondLoadCompleter.complete(
        Success<DashboardOverview, AppFailure>(_overview('Credito')),
      );

      await secondLoadFuture;

      check(controller.overview).isNotNull();
      check(controller.overview!.paymentMethods.single.code).equals('Credito');
      check(controller.isLoadingInitial).isFalse();
    });

    test('should ignore late use case completion after dispose', () async {
      final completer = Completer<AppResult<DashboardOverview>>();
      final controller = DashboardController(
        LoadDashboardOverviewUseCase(
          _PendingDashboardRepository(completer.future),
        ),
      );

      final loadFuture = controller.loadOverview(userId: 'demo-user');

      await Future<void>.delayed(Duration.zero);
      controller.dispose();

      completer.complete(
        Success<DashboardOverview, AppFailure>(_overview('Pix')),
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
    DashboardLoadPolicy policy = DashboardLoadPolicy.defaultLoad,
    DashboardFilter filter = const DashboardFilter(),
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
    DashboardLoadPolicy policy = DashboardLoadPolicy.defaultLoad,
    DashboardFilter filter = const DashboardFilter(),
  }) {
    requestedPolicies.add(policy);
    return _results[_index++];
  }
}

DashboardOverview _overview(String paymentMethodCode) {
  return DashboardOverview(
    periodStart: DateTime(2026, 3, 9),
    periodEnd: DateTime(2026, 4, 7),
    kpis: const DashboardPaymentKpis(
      totalSalesCount: 100,
      totalAmount: 9000,
      averageTicket: 90,
      paymentMethodCount: 1,
    ),
    paymentMethods: <DashboardPaymentMethodBreakdown>[
      DashboardPaymentMethodBreakdown(
        code: paymentMethodCode,
        label: paymentMethodCode,
        totalSalesCount: 100,
        totalAmount: 9000,
        averageTicket: 90,
        sharePercent: 100,
      ),
    ],
    agentRankings: const <DashboardAgentRanking>[
      DashboardAgentRanking(
        agentId: 'a1',
        displayName: 'Agente 1',
        totalSalesCount: 100,
        totalAmount: 9000,
      ),
    ],
    userRankings: const <DashboardUserRanking>[
      DashboardUserRanking(
        userName: 'Caixa 01',
        totalSalesCount: 100,
        totalAmount: 9000,
        averageTicket: 90,
      ),
    ],
  );
}
