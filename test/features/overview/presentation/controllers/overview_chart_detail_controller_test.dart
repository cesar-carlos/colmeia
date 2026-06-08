import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/overview/application/overview_shell_cache.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_sections_use_case.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/entities/overview_section_request.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/domain/overview_load_signature.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_chart_detail_controller.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_point.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  group('OverviewChartDetailController', () {
    late OverviewShellCache shellCache;

    setUp(() {
      shellCache = OverviewShellCache();
    });

    test('restores overview from shell cache when section is complete', () async {
      final filter = DashboardFilter.initial();
      final signature = overviewLoadSignature(userId: 'user', filter: filter);
      final cached = _overviewWithDailySales();
      shellCache.publish(
        signature: signature,
        overview: cached,
        activeFilter: filter,
        availableAgents: const <DashboardAgentOption>[],
        completedSections: <OverviewProgressiveSection>{
          OverviewProgressiveSection.dailySales,
        },
      );
      final repository = _RecordingSectionsRepository();
      final controller = OverviewChartDetailController(
        chartId: 'daily_sales',
        loadOverviewSectionsUseCase: LoadOverviewSectionsUseCase(repository),
        shellCache: shellCache,
        initialFilter: filter,
      );

      await controller.loadIfNeeded(userId: 'user');

      check(controller.overview).equals(cached);
      check(controller.isLoading).isFalse();
      check(repository.progressiveCallCount).equals(0);
    });

    test('loads section and merges into shell cache on success', () async {
      final filter = DashboardFilter.initial();
      final signature = overviewLoadSignature(userId: 'user', filter: filter);
      shellCache.publish(
        signature: signature,
        overview: _overview(),
        activeFilter: filter,
        availableAgents: const <DashboardAgentOption>[],
        completedSections: <OverviewProgressiveSection>{
          OverviewProgressiveSection.summary,
        },
      );
      final loaded = _overviewWithDailySales();
      final repository = _RecordingSectionsRepository(
        streams: <Stream<AppResult<OverviewProgressiveSnapshot>>>[
          Stream<AppResult<OverviewProgressiveSnapshot>>.value(
            Success<OverviewProgressiveSnapshot, AppFailure>(
              OverviewProgressiveSnapshot(
                overview: loaded,
                completedSections: <OverviewProgressiveSection>{
                  OverviewProgressiveSection.dailySales,
                },
                pendingSections: const <OverviewProgressiveSection>{},
                isFinal: true,
              ),
            ),
          ),
        ],
      );
      final controller = OverviewChartDetailController(
        chartId: 'daily_sales',
        loadOverviewSectionsUseCase: LoadOverviewSectionsUseCase(repository),
        shellCache: shellCache,
        initialFilter: filter,
      );

      await controller.loadIfNeeded(userId: 'user');

      check(controller.isLoading).isFalse();
      check(controller.overview).equals(loaded);
      check(repository.progressiveCallCount).equals(1);
      final entry = shellCache.read(signature);
      check(entry!.completedSections).contains(OverviewProgressiveSection.dailySales);
      check(entry.overview.dailySalesTrend).deepEquals(loaded.dailySalesTrend);
      check(entry.overview.kpis.totalAmount).equals(_overview().kpis.totalAmount);
    });

    test('surfaces failure without arming retry gate when no retry hint', () async {
      final repository = _RecordingSectionsRepository(
        streams: <Stream<AppResult<OverviewProgressiveSnapshot>>>[
          Stream<AppResult<OverviewProgressiveSnapshot>>.value(
            const Failure<OverviewProgressiveSnapshot, AppFailure>(
              NetworkFailure(message: 'offline'),
            ),
          ),
        ],
      );
      final gate = RetryAfterGate(tickInterval: const Duration(milliseconds: 5));
      addTearDown(gate.dispose);
      final controller = OverviewChartDetailController(
        chartId: 'daily_sales',
        loadOverviewSectionsUseCase: LoadOverviewSectionsUseCase(repository),
        shellCache: shellCache,
        retryAfterGate: gate,
      );

      await controller.loadIfNeeded(userId: 'user');

      check(controller.errorMessage).isNotNull();
      check(controller.isLoading).isFalse();
      check(controller.isOnRetryCooldown).isFalse();
    });

    test('blocks load while retry gate is closed', () async {
      final repository = _RecordingSectionsRepository(
        streams: <Stream<AppResult<OverviewProgressiveSnapshot>>>[
          Stream<AppResult<OverviewProgressiveSnapshot>>.value(
            const Failure<OverviewProgressiveSnapshot, AppFailure>(
              RpcFailure(
                message: 'Rate limited',
                userMessage: 'Wait',
                rpcCode: -32013,
                retryable: true,
                retryAfter: Duration(seconds: 10),
              ),
            ),
          ),
        ],
      );
      final gate = RetryAfterGate(tickInterval: const Duration(milliseconds: 5));
      addTearDown(gate.dispose);
      final controller = OverviewChartDetailController(
        chartId: 'daily_sales',
        loadOverviewSectionsUseCase: LoadOverviewSectionsUseCase(repository),
        shellCache: shellCache,
        retryAfterGate: gate,
      );

      await controller.loadIfNeeded(userId: 'user');
      check(controller.isOnRetryCooldown).isTrue();

      await controller.loadIfNeeded(userId: 'user');
      check(repository.progressiveCallCount).equals(1);
    });

    test('prioritizes initialFilter over shell cache latest entry', () async {
      final cacheFilter = DashboardFilter.initial();
      final initialFilter = DashboardFilter.initial().copyWith(
        selectedAgentIds: <String>{'agent-from-navigation'},
      );
      shellCache.publish(
        signature: overviewLoadSignature(userId: 'user', filter: cacheFilter),
        overview: _overview(),
        activeFilter: cacheFilter,
        availableAgents: const <DashboardAgentOption>[],
        completedSections: OverviewProgressiveSection.values.toSet(),
      );
      final repository = _RecordingSectionsRepository(
        streams: <Stream<AppResult<OverviewProgressiveSnapshot>>>[
          Stream<AppResult<OverviewProgressiveSnapshot>>.value(
            Success<OverviewProgressiveSnapshot, AppFailure>(
              OverviewProgressiveSnapshot(
                overview: _overviewWithDailySales(),
                completedSections: <OverviewProgressiveSection>{
                  OverviewProgressiveSection.dailySales,
                },
                pendingSections: const <OverviewProgressiveSection>{},
                isFinal: true,
              ),
            ),
          ),
        ],
      );
      final controller = OverviewChartDetailController(
        chartId: 'daily_sales',
        loadOverviewSectionsUseCase: LoadOverviewSectionsUseCase(repository),
        shellCache: shellCache,
        initialFilter: initialFilter,
      );

      await controller.loadIfNeeded(userId: 'user');

      check(controller.activeFilter).equals(initialFilter);
      check(repository.lastFilter?.selectedAgentIds)
          .equals(initialFilter.selectedAgentIds);
    });

    test('falls back to shell cache filter when initialFilter is null', () {
      final cacheFilter = DashboardFilter.initial().copyWith(
        selectedAgentIds: <String>{'cached-agent'},
      );
      shellCache.publish(
        signature: overviewLoadSignature(userId: 'user', filter: cacheFilter),
        overview: _overview(),
        activeFilter: cacheFilter,
        availableAgents: const <DashboardAgentOption>[],
        completedSections: OverviewProgressiveSection.values.toSet(),
      );

      final controller = OverviewChartDetailController(
        chartId: 'daily_sales',
        loadOverviewSectionsUseCase: LoadOverviewSectionsUseCase(
          _RecordingSectionsRepository(),
        ),
        shellCache: shellCache,
      );

      check(controller.activeFilter).equals(cacheFilter);
    });

    test('falls back to DashboardFilter.initial when cache is empty', () {
      final controller = OverviewChartDetailController(
        chartId: 'daily_sales',
        loadOverviewSectionsUseCase: LoadOverviewSectionsUseCase(
          _RecordingSectionsRepository(),
        ),
        shellCache: shellCache,
      );

      check(controller.activeFilter).equals(DashboardFilter.initial());
    });

    test('invalid chartId is a no-op', () async {
      final repository = _RecordingSectionsRepository();
      final controller = OverviewChartDetailController(
        chartId: 'unknown_chart',
        loadOverviewSectionsUseCase: LoadOverviewSectionsUseCase(repository),
        shellCache: shellCache,
      );

      await controller.loadIfNeeded(userId: 'user');

      check(controller.overview).isNull();
      check(controller.isLoading).isFalse();
      check(repository.progressiveCallCount).equals(0);
    });
  });
}

class _RecordingSectionsRepository implements OverviewRepository {
  _RecordingSectionsRepository({
    List<Stream<AppResult<OverviewProgressiveSnapshot>>> streams =
        const <Stream<AppResult<OverviewProgressiveSnapshot>>>[],
  }) : _streams = streams;

  final List<Stream<AppResult<OverviewProgressiveSnapshot>>> _streams;
  int progressiveCallCount = 0;
  DashboardFilter? lastFilter;
  int _index = 0;

  @override
  Future<AppResult<Overview>> loadOverview({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    DashboardFilter filter = const DashboardFilter(),
    OverviewLoadLabels? rowLabels,
    AgentQueriesCancelScope? cancelScope,
    OverviewSectionRequest sectionRequest = OverviewSectionRequest.full,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<AppResult<OverviewProgressiveSnapshot>> loadOverviewProgressively({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    DashboardFilter filter = const DashboardFilter(),
    OverviewLoadLabels? rowLabels,
    AgentQueriesCancelScope? cancelScope,
    OverviewSectionRequest sectionRequest = OverviewSectionRequest.full,
  }) {
    progressiveCallCount++;
    lastFilter = filter;
    if (_streams.isEmpty) {
      return const Stream<AppResult<OverviewProgressiveSnapshot>>.empty();
    }
    return _streams[_index++];
  }
}

Overview _overview() {
  return Overview(
    periodStart: DateTime(2026, 3, 9),
    periodEnd: DateTime(2026, 4, 7),
    kpis: const OverviewPaymentKpis(
      totalSalesCount: 100,
      totalAmount: 9000,
      averageTicket: 90,
      paymentMethodCount: 1,
    ),
    paymentMethods: const <OverviewPaymentMethodBreakdown>[
      OverviewPaymentMethodBreakdown(
        code: 'Pix',
        label: 'Pix',
        totalSalesCount: 100,
        totalAmount: 9000,
        averageTicket: 90,
        sharePercent: 100,
      ),
    ],
    agentRankings: const <OverviewAgentRanking>[],
    userRankings: const <OverviewUserRanking>[],
  );
}

Overview _overviewWithDailySales() {
  return _overview().copyWith(
    dailySalesTrend: <DailySalesTrendPoint>[
      DailySalesTrendPoint(
        saleDate: DateTime(2026, 3, 15),
        salesCount: 9,
        salesAmount: 90,
      ),
    ],
  );
}
