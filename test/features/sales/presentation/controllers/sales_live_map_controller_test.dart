import 'dart:async';

import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/application/sales_live_map_reload_reason.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_metric.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_live_map_controller.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSalesPreferences extends Mock implements SalesPreferences {}

class _MockLoadAvailableAgentsForSales extends Mock
    implements LoadAvailableAgentsForSales {}

class _MockLoadSalesLiveMapUseCase extends Mock
    implements LoadSalesLiveMapUseCase {}

void main() {
  late _MockSalesPreferences salesPreferences;
  late _MockLoadAvailableAgentsForSales loadAvailableAgentsForSales;
  late _MockLoadSalesLiveMapUseCase loadLiveMap;
  late SalesLiveMapController controller;

  setUpAll(() {
    registerFallbackValue(const SalesLiveMapFilter());
    registerFallbackValue(SalesLiveMapLoadCancelToken());
    registerFallbackValue(SalesLiveMapReloadReason.manual);
  });

  setUp(() {
    salesPreferences = _MockSalesPreferences();
    loadAvailableAgentsForSales = _MockLoadAvailableAgentsForSales();
    loadLiveMap = _MockLoadSalesLiveMapUseCase();

    when(
      () => salesPreferences.restoreSalesLiveMapFilter(),
    ).thenReturn(const SalesLiveMapFilter());
    when(
      () => salesPreferences.persistSalesLiveMapFilter(any()),
    ).thenAnswer((_) async {});
    when(
      () => loadAvailableAgentsForSales.call('user-1'),
    ).thenAnswer(
      (_) async => const <DashboardAgentOption>[
        DashboardAgentOption(agentId: 'agent-1', name: 'Agent One'),
      ],
    );
    when(
      () => loadLiveMap.loadProgressive(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        reason: any(named: 'reason'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) => Stream<SalesLiveMapLoadResult>.value(_loadedResult()));

    controller = SalesLiveMapController(
      sessionService: SalesSessionService(salesPreferences),
      loadSalesAvailableAgentsUseCase: loadAvailableAgentsForSales,
      loadSalesLiveMapUseCase: loadLiveMap,
    );
  });

  test(
    'bindUser normalizes stale branch selection before first load',
    () async {
      when(
        () => salesPreferences.restoreSalesLiveMapFilter(),
      ).thenReturn(
        SalesLiveMapFilter(
          selectedAgentIds: const <String>{'agent-1'},
          selectedBranchIds: <SalesLiveMapBranchRef>{
            const SalesLiveMapBranchRef(
              agentId: 'agent-1',
              codEmpresa: 1,
              codFilial: 1,
            ),
          },
        ),
      );

      await controller.bindUser('user-1');

      expect(controller.state.filter.selectedBranchIds, isNull);
      expect(controller.state.filter.selectedAgentIds, isNull);

      final persistedFilters = verify(
        () => salesPreferences.persistSalesLiveMapFilter(captureAny()),
      ).captured.cast<SalesLiveMapFilter>();
      expect(persistedFilters.first.selectedBranchIds, isNull);
      expect(persistedFilters.first.selectedAgentIds, isNull);

      verify(
        () => loadLiveMap.loadProgressive(
          userId: 'user-1',
          filter: any(named: 'filter'),
          reason: SalesLiveMapReloadReason.initial,
          cancelToken: any(named: 'cancelToken'),
        ),
      ).called(1);
    },
  );

  test(
    'applyFilter skips equivalent state updates and does not notify listeners',
    () async {
      await controller.bindUser('user-1');
      clearInteractions(salesPreferences);
      clearInteractions(loadLiveMap);
      var listenerCount = 0;
      controller.addListener(() => listenerCount += 1);

      await controller.applyFilter(controller.state.filter);

      expect(listenerCount, 0);
      verifyNever(
        () => salesPreferences.persistSalesLiveMapFilter(any()),
      );
      verifyNever(
        () => loadLiveMap.loadProgressive(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          reason: any(named: 'reason'),
          cancelToken: any(named: 'cancelToken'),
        ),
      );
    },
  );

  test(
    'updateMetric persists the filter without triggering a reload',
    () async {
      await controller.bindUser('user-1');
      clearInteractions(loadLiveMap);

      controller.updateMetric(SalesLiveMapMetric.salesCount);

      expect(
        controller.state.filter.metric,
        SalesLiveMapMetric.salesCount,
      );
      verifyNever(
        () => loadLiveMap.loadProgressive(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          reason: any(named: 'reason'),
          cancelToken: any(named: 'cancelToken'),
        ),
      );
      final persistedFilters = verify(
        () => salesPreferences.persistSalesLiveMapFilter(captureAny()),
      ).captured.cast<SalesLiveMapFilter>();
      expect(
        persistedFilters.last.metric,
        SalesLiveMapMetric.salesCount,
      );
    },
  );

  test(
    'updateMetric skips equivalent values without notifying listeners',
    () async {
      await controller.bindUser('user-1');
      clearInteractions(salesPreferences);
      clearInteractions(loadLiveMap);
      var listenerCount = 0;
      controller
        ..addListener(() => listenerCount += 1)
        ..updateMetric(controller.state.filter.metric);

      expect(listenerCount, 0);
      verifyNever(
        () => salesPreferences.persistSalesLiveMapFilter(any()),
      );
      verifyNever(
        () => loadLiveMap.loadProgressive(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          reason: any(named: 'reason'),
          cancelToken: any(named: 'cancelToken'),
        ),
      );
    },
  );

  test(
    'applyFilter with visual-only changes does not trigger a reload',
    () async {
      await controller.bindUser('user-1');
      clearInteractions(loadLiveMap);

      await controller.applyFilter(
        const SalesLiveMapFilter(
          detailLevel: SalesLiveMapMapDetail.municipalities,
          markerVisual: SalesLiveMapMarkerVisual.bubble,
        ),
      );

      expect(
        controller.state.filter.detailLevel,
        SalesLiveMapMapDetail.municipalities,
      );
      expect(
        controller.state.filter.markerVisual,
        SalesLiveMapMarkerVisual.bubble,
      );
      verifyNever(
        () => loadLiveMap.loadProgressive(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          reason: any(named: 'reason'),
          cancelToken: any(named: 'cancelToken'),
        ),
      );
    },
  );

  test(
    'clearSelectedBranches resets branch scope, reloads, and requests fullscreen close',
    () async {
      await controller.bindUser('user-1');
      await controller.applyFilter(
        SalesLiveMapFilter(
          selectedBranchIds: <SalesLiveMapBranchRef>{
            const SalesLiveMapBranchRef(
              agentId: 'agent-1',
              codEmpresa: 1,
              codFilial: 1,
            ),
          },
        ),
      );
      clearInteractions(loadLiveMap);
      final previousCloseRequestId = controller.state.closeFullscreenRequestId;

      await controller.clearSelectedBranches();

      expect(controller.state.filter.selectedBranchIds, isNull);
      expect(controller.state.filter.selectedAgentIds, isNull);
      expect(
        controller.state.closeFullscreenRequestId,
        previousCloseRequestId + 1,
      );

      final capturedFilters = verify(
        () => loadLiveMap.loadProgressive(
          userId: 'user-1',
          filter: captureAny(named: 'filter'),
          reason: captureAny(named: 'reason'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).captured;
      final capturedFilter = capturedFilters[0] as SalesLiveMapFilter;
      final capturedReason = capturedFilters[1] as SalesLiveMapReloadReason;
      expect(capturedFilter.selectedBranchIds, isNull);
      expect(capturedFilter.selectedAgentIds, isNull);
      expect(capturedReason, SalesLiveMapReloadReason.filterChange);
    },
  );

  test('clearSavedFilters restores defaults and reloads', () async {
    await controller.bindUser('user-1');
    await controller.applyFilter(
      SalesLiveMapFilter(
        selectedAgentIds: const <String>{'agent-1'},
        selectedBranchIds: <SalesLiveMapBranchRef>{
          const SalesLiveMapBranchRef(
            agentId: 'agent-1',
            codEmpresa: 1,
            codFilial: 1,
          ),
        },
        periodMode: SalesLiveMapPeriodMode.lastSevenDays,
        detailLevel: SalesLiveMapMapDetail.municipalities,
        markerVisual: SalesLiveMapMarkerVisual.bubble,
        metric: SalesLiveMapMetric.salesCount,
      ),
    );
    clearInteractions(loadLiveMap);

    await controller.clearSavedFilters();

    expect(controller.state.filter.selectedAgentIds, isNull);
    expect(controller.state.filter.selectedBranchIds, isNull);
    expect(controller.state.filter.periodMode, SalesLiveMapPeriodMode.today);
    expect(controller.state.filter.detailLevel, SalesLiveMapMapDetail.branches);
    expect(controller.state.filter.markerVisual, SalesLiveMapMarkerVisual.dot);
    expect(
      controller.state.filter.metric,
      SalesLiveMapMetric.revenue,
    );

    final capturedFilters = verify(
      () => loadLiveMap.loadProgressive(
        userId: 'user-1',
        filter: captureAny(named: 'filter'),
        reason: captureAny(named: 'reason'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).captured;
    final capturedFilter = capturedFilters[0] as SalesLiveMapFilter;
    final capturedReason = capturedFilters[1] as SalesLiveMapReloadReason;
    expect(capturedFilter.selectedBranchIds, isNull);
    expect(capturedFilter.selectedAgentIds, isNull);
    expect(capturedReason, SalesLiveMapReloadReason.filterChange);
  });

  test(
    'canScheduleAutoRefresh is false when all agents miss local token',
    () async {
      when(
        () => loadAvailableAgentsForSales.call('user-1'),
      ).thenAnswer(
        (_) async => const <DashboardAgentOption>[
          DashboardAgentOption(
            agentId: 'agent-1',
            name: 'Agent One',
            missingLocalClientToken: true,
          ),
        ],
      );

      await controller.bindUser('user-1');

      expect(controller.state.canScheduleAutoRefresh, isFalse);
    },
  );

  test(
    'reload(force: true) cancels the previous generation and keeps the latest result',
    () async {
      await controller.bindUser('user-1');

      final firstStream = StreamController<SalesLiveMapLoadResult>();
      final secondStream = StreamController<SalesLiveMapLoadResult>();
      addTearDown(firstStream.close);
      addTearDown(secondStream.close);

      var progressiveCallCount = 0;
      final capturedTokens = <SalesLiveMapLoadCancelToken>[];
      when(
        () => loadLiveMap.loadProgressive(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          reason: any(named: 'reason'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((invocation) {
        progressiveCallCount += 1;
        capturedTokens.add(
          invocation.namedArguments[#cancelToken]
              as SalesLiveMapLoadCancelToken,
        );
        if (progressiveCallCount == 1) {
          return firstStream.stream;
        }
        return secondStream.stream;
      });

      final firstReload = controller.reload();
      await Future<void>.delayed(Duration.zero);
      final secondReload = controller.reload(force: true);
      await Future<void>.delayed(Duration.zero);

      expect(capturedTokens, hasLength(2));
      expect(capturedTokens.first.isCancelled, isTrue);

      firstStream.add(_resultForRevenue(10));
      await firstStream.close();
      await Future<void>.delayed(Duration.zero);
      expect(
        controller.state.result?.totalRevenue,
        _loadedResult().totalRevenue,
      );

      secondStream.add(_resultForRevenue(99));
      await secondStream.close();
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.result?.totalRevenue, 99);

      expect((await firstReload).isSuperseded, isTrue);
      expect((await secondReload).isCompleted, isTrue);
    },
  );

  test(
    'keeps the last visual snapshot while a manual refresh is pending',
    () async {
      await controller.bindUser('user-1');

      final stream = StreamController<SalesLiveMapLoadResult>();
      addTearDown(stream.close);
      when(
        () => loadLiveMap.loadProgressive(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          reason: any(named: 'reason'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) => stream.stream);

      final reloadFuture = controller.reload();
      await Future<void>.delayed(Duration.zero);

      stream.add(
        SalesLiveMapLoadResult(
          points: <SalesLiveMapPoint>[],
          branchOptions: <SalesLiveMapBranchOption>[],
          totalRevenue: 0,
          totalSalesCount: 0,
          totalBranchCount: 0,
          mappedBranchCount: 0,
          mappedMunicipalityCount: 0,
          queriedAgentCount: 0,
          plannedAgentCount: 0,
          failedAgentCount: 0,
          missingClientTokenAgentCount: 0,
          skippedOfflineAgentCount: 0,
          rowCapReachedAgentCount: 0,
          salesDataPending: true,
          refreshedAt: DateTime(2026, 5, 9, 12),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isLoading, isTrue);
      expect(controller.state.result?.salesDataPending, isFalse);
      expect(controller.state.visualResult?.totalRevenue, 1200);
      expect(controller.state.hasVisualResult, isTrue);

      stream.add(_resultForRevenue(77));
      await stream.close();
      await Future<void>.delayed(Duration.zero);

      expect((await reloadFuture).isCompleted, isTrue);
      expect(controller.state.visualResult?.totalRevenue, 77);
    },
  );

  test(
    'does not promote an empty pending result to the visual snapshot on first load',
    () async {
      final stream = StreamController<SalesLiveMapLoadResult>();
      addTearDown(stream.close);
      when(
        () => loadLiveMap.loadProgressive(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          reason: any(named: 'reason'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) => stream.stream);

      final bindFuture = controller.bindUser('user-1');
      await Future<void>.delayed(Duration.zero);

      stream.add(
        SalesLiveMapLoadResult(
          points: <SalesLiveMapPoint>[],
          branchOptions: <SalesLiveMapBranchOption>[],
          totalRevenue: 0,
          totalSalesCount: 0,
          totalBranchCount: 0,
          mappedBranchCount: 0,
          mappedMunicipalityCount: 0,
          queriedAgentCount: 0,
          plannedAgentCount: 0,
          failedAgentCount: 0,
          missingClientTokenAgentCount: 0,
          skippedOfflineAgentCount: 0,
          rowCapReachedAgentCount: 0,
          salesDataPending: true,
          refreshedAt: DateTime(2026, 5, 9, 12),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.result?.salesDataPending, isTrue);
      expect(controller.state.visualResult, isNull);
      expect(controller.state.hasVisualResult, isFalse);

      stream.add(_loadedResult());
      await stream.close();
      await bindFuture;

      expect(controller.state.visualResult?.totalRevenue, 1200);
      expect(controller.state.hasVisualResult, isTrue);
    },
  );

  test(
    'clears the visual snapshot while a data filter change reloads',
    () async {
      await controller.bindUser('user-1');

      final stream = StreamController<SalesLiveMapLoadResult>();
      addTearDown(stream.close);
      when(
        () => loadLiveMap.loadProgressive(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          reason: any(named: 'reason'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) => stream.stream);

      final reloadFuture = controller.applyFilter(
        SalesLiveMapFilter(
          selectedBranchIds: <SalesLiveMapBranchRef>{
            const SalesLiveMapBranchRef(
              agentId: 'agent-1',
              codEmpresa: 1,
              codFilial: 1,
            ),
          },
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isLoading, isTrue);
      expect(controller.state.visualResult, isNull);
      expect(controller.state.hasVisualResult, isFalse);

      stream.add(_loadedResult());
      await stream.close();
      await reloadFuture;

      expect(controller.state.visualResult, isNotNull);
    },
  );

  test('reload defaults to manual reason', () async {
    await controller.bindUser('user-1');
    clearInteractions(loadLiveMap);

    await controller.reload();

    final verification = verify(
      () => loadLiveMap.loadProgressive(
        userId: 'user-1',
        filter: any(named: 'filter'),
        reason: captureAny(named: 'reason'),
        cancelToken: any(named: 'cancelToken'),
      ),
    )..called(1);
    expect(
      verification.captured.single,
      SalesLiveMapReloadReason.manual,
    );
  });
}

SalesLiveMapLoadResult _loadedResult() {
  return _resultForRevenue(1200);
}

SalesLiveMapLoadResult _resultForRevenue(double revenue) {
  return SalesLiveMapLoadResult(
    points: <SalesLiveMapPoint>[
      SalesLiveMapPoint(
        id: 'agent-1-1-1',
        name: 'Branch One',
        uf: 'MT',
        latitude: -15.60,
        longitude: -56.10,
        salesAmount: revenue,
        salesCount: revenue.round(),
        city: 'Cuiaba',
      ),
    ],
    branchOptions: const <SalesLiveMapBranchOption>[
      SalesLiveMapBranchOption(
        id: 'agent-1-1-1',
        agentId: 'agent-1',
        agentName: 'Agent One',
        codEmpresa: 1,
        codFilial: 1,
        registrationName: 'Branch One',
        city: 'Cuiaba',
        uf: 'MT',
      ),
    ],
    totalRevenue: revenue,
    totalSalesCount: revenue.round(),
    totalBranchCount: 1,
    mappedBranchCount: 1,
    mappedMunicipalityCount: 1,
    queriedAgentCount: 1,
    plannedAgentCount: 1,
    failedAgentCount: 0,
    missingClientTokenAgentCount: 0,
    skippedOfflineAgentCount: 0,
    rowCapReachedAgentCount: 0,
    salesAgentCount: 1,
    refreshedAt: DateTime(2026, 5, 9, 12),
  );
}
