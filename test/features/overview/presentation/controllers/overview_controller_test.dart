import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_use_case.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  group('OverviewController', () {
    test('should load overview from use case', () async {
      final repository = _QueuedOverviewRepository(
        <Future<AppResult<Overview>>>[
          Future<AppResult<Overview>>.value(
            Success<Overview, AppFailure>(_overview('Pix')),
          ),
        ],
      );
      final controller = OverviewController(
        LoadOverviewUseCase(repository),
      );

      await controller.loadOverview(userId: 'demo-user');

      check(controller.overview).isNotNull();
      check(controller.overview!.paymentMethods.single.code).equals('Pix');
      check(controller.errorMessage).isNull();
      check(controller.hasContent).isTrue();
      check(controller.isLoadingInitial).isFalse();
      check(controller.isRefreshing).isFalse();
      check(repository.requestedPolicies.single).equals(
        OverviewLoadPolicy.defaultLoad,
      );
    });

    test(
      'should keep content visible and expose refresh state '
      'during manual refresh',
      () async {
        final refreshCompleter = Completer<AppResult<Overview>>();
        final repository = _QueuedOverviewRepository(
          <Future<AppResult<Overview>>>[
            Future<AppResult<Overview>>.value(
              Success<Overview, AppFailure>(_overview('Pix')),
            ),
            refreshCompleter.future,
          ],
        );
        final controller = OverviewController(
          LoadOverviewUseCase(repository),
        );

        await controller.loadOverview(userId: 'demo-user');

        final refreshFuture = controller.refreshOverview(userId: 'demo-user');

        await Future<void>.delayed(Duration.zero);

        check(controller.isRefreshing).isTrue();
        check(controller.isLoadingInitial).isFalse();
        check(controller.overview).isNotNull();
        check(controller.overview!.paymentMethods.single.code).equals('Pix');

        refreshCompleter.complete(
          const Failure<Overview, AppFailure>(
            UnknownFailure(
              message: 'Refresh failed',
              userMessage: 'Could not refresh the overview.',
            ),
          ),
        );

        await refreshFuture;

        check(controller.isRefreshing).isFalse();
        check(controller.overview).isNotNull();
        check(controller.overview!.paymentMethods.single.code).equals('Pix');
        check(controller.errorMessage).equals(
          'Could not refresh the overview.',
        );
        check(repository.requestedPolicies).deepEquals(<OverviewLoadPolicy>[
          OverviewLoadPolicy.defaultLoad,
          OverviewLoadPolicy.forceRefresh,
        ]);
      },
    );

    test('should clear stale content when a second load starts', () async {
      final secondLoadCompleter = Completer<AppResult<Overview>>();
      final repository = _QueuedOverviewRepository(
        <Future<AppResult<Overview>>>[
          Future<AppResult<Overview>>.value(
            Success<Overview, AppFailure>(_overview('Pix')),
          ),
          secondLoadCompleter.future,
        ],
      );
      final controller = OverviewController(
        LoadOverviewUseCase(repository),
      );

      await controller.loadOverview(userId: 'demo-user');

      final secondLoadFuture = controller.loadOverview(userId: 'demo-user');

      await Future<void>.delayed(Duration.zero);

      check(controller.overview).isNull();
      check(controller.hasContent).isFalse();
      check(controller.isLoadingInitial).isTrue();
      check(controller.isRefreshing).isFalse();

      secondLoadCompleter.complete(
        Success<Overview, AppFailure>(_overview('Credito')),
      );

      await secondLoadFuture;

      check(controller.overview).isNotNull();
      check(controller.overview!.paymentMethods.single.code).equals('Credito');
    });

    test('should ignore stale responses when a newer request wins', () async {
      final firstLoadCompleter = Completer<AppResult<Overview>>();
      final secondLoadCompleter = Completer<AppResult<Overview>>();
      final repository = _QueuedOverviewRepository(
        <Future<AppResult<Overview>>>[
          firstLoadCompleter.future,
          secondLoadCompleter.future,
        ],
      );
      final controller = OverviewController(
        LoadOverviewUseCase(repository),
      );

      final firstLoadFuture = controller.loadOverview(userId: 'demo-user');
      final secondLoadFuture = controller.loadOverview(userId: 'demo-user');

      firstLoadCompleter.complete(
        Success<Overview, AppFailure>(_overview('Pix')),
      );
      await firstLoadFuture;

      check(controller.overview).isNull();
      check(controller.isLoadingInitial).isTrue();

      secondLoadCompleter.complete(
        Success<Overview, AppFailure>(_overview('Credito')),
      );

      await secondLoadFuture;

      check(controller.overview).isNotNull();
      check(controller.overview!.paymentMethods.single.code).equals('Credito');
      check(controller.isLoadingInitial).isFalse();
    });

    test('should ignore late use case completion after dispose', () async {
      final completer = Completer<AppResult<Overview>>();
      final controller = OverviewController(
        LoadOverviewUseCase(
          _PendingOverviewRepository(completer.future),
        ),
      );

      final loadFuture = controller.loadOverview(userId: 'demo-user');

      await Future<void>.delayed(Duration.zero);
      controller.dispose();

      completer.complete(
        Success<Overview, AppFailure>(_overview('Pix')),
      );

      await loadFuture;
    });
  });
}

class _PendingOverviewRepository implements OverviewRepository {
  _PendingOverviewRepository(this._resultFuture);

  final Future<AppResult<Overview>> _resultFuture;

  @override
  Future<AppResult<Overview>> loadOverview({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    OverviewFilter filter = const OverviewFilter(),
  }) {
    return _resultFuture;
  }
}

class _QueuedOverviewRepository implements OverviewRepository {
  _QueuedOverviewRepository(this._results);

  final List<Future<AppResult<Overview>>> _results;
  final List<OverviewLoadPolicy> requestedPolicies = <OverviewLoadPolicy>[];
  int _index = 0;

  @override
  Future<AppResult<Overview>> loadOverview({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    OverviewFilter filter = const OverviewFilter(),
  }) {
    requestedPolicies.add(policy);
    return _results[_index++];
  }
}

Overview _overview(String paymentMethodCode) {
  return Overview(
    periodStart: DateTime(2026, 3, 9),
    periodEnd: DateTime(2026, 4, 7),
    kpis: const OverviewPaymentKpis(
      totalSalesCount: 100,
      totalAmount: 9000,
      averageTicket: 90,
      paymentMethodCount: 1,
    ),
    paymentMethods: <OverviewPaymentMethodBreakdown>[
      OverviewPaymentMethodBreakdown(
        code: paymentMethodCode,
        label: paymentMethodCode,
        totalSalesCount: 100,
        totalAmount: 9000,
        averageTicket: 90,
        sharePercent: 100,
      ),
    ],
    agentRankings: const <OverviewAgentRanking>[
      OverviewAgentRanking(
        agentId: 'a1',
        displayName: 'Agente 1',
        totalSalesCount: 100,
        totalAmount: 9000,
      ),
    ],
    userRankings: const <OverviewUserRanking>[
      OverviewUserRanking(
        userName: 'Caixa 01',
        totalSalesCount: 100,
        totalAmount: 9000,
        averageTicket: 90,
      ),
    ],
  );
}
