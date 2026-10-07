import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/sales/application/load_sales_daily_totals_use_case.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_daily_totals_controller.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_point.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Loader extends Mock implements LoadSalesDailyTotalsUseCase {}

class _Tokens extends Mock implements ResolveSalesAgentClientTokenUseCase {}

void main() {
  late _Loader loader;
  late _Tokens tokens;
  late SalesDailyTotalsController controller;
  const anchor = DashboardYearMonth(year: 2026, month: 8);
  const success = (
    points: <DailySalesTrendPoint>[],
    loadFailed: false,
    loadFailure: null,
  );

  setUpAll(() {
    registerFallbackValue(anchor);
    registerFallbackValue(AgentQueriesCancelScope());
  });
  setUp(() {
    loader = _Loader();
    tokens = _Tokens();
    when(
      () => tokens(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer((_) async => 'client-token');
    when(
      () => loader(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        anchor: any(named: 'anchor'),
        dailySaleDateRange: any(named: 'dailySaleDateRange'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer((_) async => success);
    controller = SalesDailyTotalsController(
      loadDailyTotals: loader,
      resolveClientToken: tokens,
    );
    addTearDown(controller.dispose);
  });

  test(
    'cancel releases loading during token lookup and prevents a late query',
    () async {
      final token = Completer<String?>();
      when(() => tokens(userId: 'u', agentId: 'a'))
          .thenAnswer((_) => token.future);
      final load = controller.load(userId: 'u', agentId: 'a', anchor: anchor);
      expect(controller.loading, isTrue);
      controller.cancel();
      expect(await load, isNull);
      expect(controller.loading, isFalse);
      token.complete('late-token');
      await Future<void>.delayed(Duration.zero);
      verifyZeroInteractions(loader);
      expect(controller.failure, isNull);
    },
  );

  test('superseded query cannot replace the new filter result', () async {
    final old = Completer<SalesDailyTotalsLoadResult>();
    AgentQueriesCancelScope? oldScope;
    when(
      () => loader(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        anchor: any(named: 'anchor'),
        dailySaleDateRange: any(named: 'dailySaleDateRange'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer((invocation) {
      final agent = invocation.namedArguments[#agentId];
      if (agent == 'a') {
        oldScope =
            invocation.namedArguments[#cancelScope] as AgentQueriesCancelScope;
        return old.future;
      }
      return Future.value(success);
    });
    final first = controller.load(userId: 'u', agentId: 'a', anchor: anchor);
    await Future<void>.delayed(Duration.zero);
    final second = await controller.load(
      userId: 'u',
      agentId: 'b',
      anchor: anchor,
    );
    expect(await first, isNull);
    expect(second?.loadFailed, isFalse);
    expect(oldScope?.isCancelled, isTrue);
    old.complete((
      points: const <DailySalesTrendPoint>[],
      loadFailed: true,
      loadFailure: const NetworkFailure(message: 'late failure'),
    ));
    await Future<void>.delayed(Duration.zero);
    expect(controller.failure, isNull);
    expect(controller.loading, isFalse);
  });

  test(
    'dispose completes an abandoned load without waiting for its producer',
    () async {
      final token = Completer<String?>();
      when(() => tokens(userId: 'u', agentId: 'a'))
          .thenAnswer((_) => token.future);
      final load = controller.load(userId: 'u', agentId: 'a', anchor: anchor);
      controller.dispose();
      expect(await load, isNull);
      token.complete('late-token');
      await Future<void>.delayed(Duration.zero);
      verifyZeroInteractions(loader);
    },
  );

  test(
    'synchronous listener cancellation prevents starting a producer',
    () async {
      controller.addListener(() {
        if (controller.loading) controller.cancel();
      });
      expect(
        await controller.load(userId: 'u', agentId: 'a', anchor: anchor),
        isNull,
      );
      verifyZeroInteractions(tokens);
      verifyZeroInteractions(loader);
    },
  );

  test('maps a thrown token error and clears loading', () async {
    when(() => tokens(userId: 'u', agentId: 'a'))
        .thenThrow(StateError('lookup failed'));
    final result = await controller.load(
      userId: 'u',
      agentId: 'a',
      anchor: anchor,
    );
    expect(result?.loadFailed, isTrue);
    expect(controller.failure, isNotNull);
    expect(controller.loading, isFalse);
    verifyZeroInteractions(loader);
  });

  test('missing token becomes an authentication failure', () async {
    when(() => tokens(userId: 'u', agentId: 'a')).thenAnswer((_) async => null);
    final result = await controller.load(
      userId: 'u',
      agentId: 'a',
      anchor: anchor,
    );
    expect(result?.loadFailure, isA<SessionFailure>());
    expect(controller.loading, isFalse);
    verifyZeroInteractions(loader);
  });

  test('reuses a resolved token only for the same account and agent', () async {
    await controller.load(userId: 'u', agentId: 'a', anchor: anchor);
    await controller.load(userId: 'u', agentId: 'a', anchor: anchor);
    verify(() => tokens(userId: 'u', agentId: 'a')).called(1);
    await controller.load(userId: 'v', agentId: 'a', anchor: anchor);
    verify(() => tokens(userId: 'v', agentId: 'a')).called(1);
    await controller.load(userId: 'v', agentId: 'b', anchor: anchor);
    verify(() => tokens(userId: 'v', agentId: 'b')).called(1);
  });

  test(
    'forwards an independent custom range and existing timeout policy',
    () async {
      final range = DashboardDateRange.fromOrderedEndpoints(
        DateTime(2026, 9),
        DateTime(2026, 9, 30),
      );
      await controller.load(
        userId: 'u',
        agentId: ' a ',
        anchor: anchor,
        dailySaleDateRange: range,
      );
      verify(
        () => loader(
          userId: 'u',
          agentId: 'a',
          anchor: anchor,
          dailySaleDateRange: range,
          clientToken: 'client-token',
          cancelScope: any(named: 'cancelScope'),
        ),
      ).called(1);
      expect(LoadSalesDailyTotalsUseCase.bridgeTimeoutMs, 300000);
    },
  );
}
