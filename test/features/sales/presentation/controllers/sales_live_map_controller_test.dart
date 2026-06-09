import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_diagnostic.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_retry_after.dart';
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
import 'package:colmeia/features/sales/presentation/rules/sales_live_map_presentation_rules.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
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
        bypassCatalogCache: any(named: 'bypassCatalogCache'),
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
          bypassCatalogCache: any(named: 'bypassCatalogCache'),
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
          bypassCatalogCache: any(named: 'bypassCatalogCache'),
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
          bypassCatalogCache: any(named: 'bypassCatalogCache'),
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
          bypassCatalogCache: any(named: 'bypassCatalogCache'),
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
          bypassCatalogCache: any(named: 'bypassCatalogCache'),
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
          bypassCatalogCache: any(named: 'bypassCatalogCache'),
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
        bypassCatalogCache: any(named: 'bypassCatalogCache'),
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

      expect(
        SalesLiveMapPresentationRules.canScheduleAutoRefresh(controller.state),
        isFalse,
      );
    },
  );

  test(
    'reload without force cancels the previous in-flight SQL token',
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
          bypassCatalogCache: any(named: 'bypassCatalogCache'),
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
      final secondReload = controller.reload();
      await Future<void>.delayed(Duration.zero);

      expect(capturedTokens, hasLength(2));
      expect(capturedTokens.first.isCancelled, isTrue);

      await firstStream.close();
      secondStream.add(_resultForRevenue(42));
      await secondStream.close();
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.result?.totalRevenue, 42);
      expect((await firstReload).isSuperseded, isTrue);
      expect((await secondReload).isCompleted, isTrue);
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
          bypassCatalogCache: any(named: 'bypassCatalogCache'),
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

  test('reload(force: true) requests a catalog-cache bypass', () async {
    await controller.bindUser('user-1');
    clearInteractions(loadLiveMap);
    when(
      () => loadLiveMap.loadProgressive(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        reason: any(named: 'reason'),
        cancelToken: any(named: 'cancelToken'),
        bypassCatalogCache: any(named: 'bypassCatalogCache'),
      ),
    ).thenAnswer((_) => Stream<SalesLiveMapLoadResult>.value(_loadedResult()));

    await controller.reload(force: true);

    verify(
      () => loadLiveMap.loadProgressive(
        userId: 'user-1',
        filter: any(named: 'filter'),
        cancelToken: any(named: 'cancelToken'),
        bypassCatalogCache: true,
      ),
    ).called(1);
  });

  test(
    'ignores late catalog-shell emissions after a mapped refresh snapshot',
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
          bypassCatalogCache: any(named: 'bypassCatalogCache'),
        ),
      ).thenAnswer((_) => stream.stream);

      final reloadFuture = controller.reload();
      await Future<void>.delayed(Duration.zero);

      stream
        ..add(_mappedTwentySevenPointResult())
        ..add(_catalogShellTwentySevenUnmapped(salesDataPending: true))
        ..add(_catalogShellTwentySevenUnmapped(salesDataPending: false));
      await stream.close();
      await reloadFuture;

      expect(controller.state.visualResult?.mappedBranchCount, 27);
      expect(controller.state.result?.mappedBranchCount, 27);
      expect(controller.state.result?.unmappedBranchOptions, isEmpty);
      expect(controller.state.result?.hasPartialIssue, isFalse);
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
          bypassCatalogCache: any(named: 'bypassCatalogCache'),
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
      expect(controller.state.result?.salesDataPending, isTrue);
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
    'updates operational KPI fields during soft refresh while preserving map snapshot',
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
          bypassCatalogCache: any(named: 'bypassCatalogCache'),
        ),
      ).thenAnswer((_) => stream.stream);

      final reloadFuture = controller.reload();
      await Future<void>.delayed(Duration.zero);

      stream.add(
        SalesLiveMapLoadResult(
          points: const <SalesLiveMapPoint>[],
          branchOptions: const <SalesLiveMapBranchOption>[],
          totalRevenue: 999,
          totalSalesCount: 99,
          totalBranchCount: 1,
          mappedBranchCount: 0,
          mappedMunicipalityCount: 0,
          queriedAgentCount: 3,
          plannedAgentCount: 3,
          failedAgentCount: 1,
          missingClientTokenAgentCount: 0,
          skippedOfflineAgentCount: 0,
          rowCapReachedAgentCount: 0,
          salesDataPending: true,
          refreshedAt: DateTime(2026, 5, 9, 13),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.visualResult?.totalRevenue, 1200);
      expect(controller.state.result?.totalRevenue, 999);
      expect(controller.state.result?.queriedAgentCount, 3);
      expect(controller.state.result?.failedAgentCount, 1);
      expect(controller.state.result?.salesDataPending, isTrue);
      expect(controller.state.result?.mappedBranchCount, 1);

      stream.add(_resultForRevenue(77));
      await stream.close();
      await reloadFuture;

      expect(controller.state.visualResult?.totalRevenue, 77);
      expect(controller.state.result?.salesDataPending, isFalse);
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
          bypassCatalogCache: any(named: 'bypassCatalogCache'),
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
          bypassCatalogCache: any(named: 'bypassCatalogCache'),
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
        bypassCatalogCache: any(named: 'bypassCatalogCache'),
      ),
    )..called(1);
    expect(
      verification.captured.single,
      SalesLiveMapReloadReason.manual,
    );
  });

  test(
    'bindUser persists the normalized filter when stale branches are dropped',
    () async {
      when(
        () => salesPreferences.restoreSalesLiveMapFilter(),
      ).thenReturn(
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

      await controller.bindUser('user-1');

      final persistedFilters = verify(
        () => salesPreferences.persistSalesLiveMapFilter(captureAny()),
      ).captured.cast<SalesLiveMapFilter>();
      // Two persists are expected: one from bindUser dropping the stale
      // branch selection, and one from _loadAgents normalizing agents.
      // Before the H1 fix the first one was never emitted.
      expect(persistedFilters.length, greaterThanOrEqualTo(2));
      expect(persistedFilters.first.selectedBranchIds, isNull);
      expect(persistedFilters.first.selectedAgentIds, isNull);
    },
  );

  test(
    'bindUser does not persist on disk when there is no stale branch to drop',
    () async {
      when(
        () => salesPreferences.restoreSalesLiveMapFilter(),
      ).thenReturn(const SalesLiveMapFilter());

      await controller.bindUser('user-1');

      // Only _loadAgents persists — bindUser must not write to disk just
      // because it ran the normalization no-op.
      verify(
        () => salesPreferences.persistSalesLiveMapFilter(any()),
      ).called(1);
    },
  );

  test(
    'applyFilter forces reload when sessionExpired even on visual-only change',
    () async {
      await controller.bindUser('user-1');
      expect(controller.state.sessionExpired, isFalse);

      await controller.bindUser(null);
      expect(controller.state.sessionExpired, isTrue);

      final stateLog = <bool>[];
      controller.addListener(() {
        stateLog.add(controller.state.sessionExpired);
      });

      // Visual-only change while session is expired. Before the bug 1.2
      // fix the apply would just flip sessionExpired to false in memory
      // without ever triggering a reload, hiding the missing data behind
      // a fake "success" state.
      await controller.applyFilter(
        controller.state.filter.copyWith(
          markerVisual: SalesLiveMapMarkerVisual.bubble,
        ),
      );

      expect(
        controller.state.sessionExpired,
        isTrue,
        reason:
            'reload must re-set sessionExpired=true because _boundUserId '
            'is still null',
      );
      expect(
        stateLog,
        contains(false),
        reason: 'state must momentarily transition to sessionExpired=false',
      );
      expect(
        stateLog.last,
        isTrue,
        reason: 'state must end with sessionExpired=true after the reload',
      );
    },
  );

  test(
    'updateMetric forces reload when sessionExpired',
    () async {
      await controller.bindUser('user-1');
      await controller.bindUser(null);
      expect(controller.state.sessionExpired, isTrue);

      final stateLog = <bool>[];
      controller
        ..addListener(() {
          stateLog.add(controller.state.sessionExpired);
        })
        ..updateMetric(SalesLiveMapMetric.salesCount);
      await Future<void>.delayed(Duration.zero);

      expect(stateLog, contains(false));
      expect(stateLog.last, isTrue);
    },
  );

  test(
    'reload applies progressive map point updates from the use case stream',
    () async {
      final ibgePending = SalesLiveMapLoadResult(
        points: <SalesLiveMapPoint>[
          const SalesLiveMapPoint(
            id: 'agent-1-1-1',
            name: 'Branch One',
            uf: 'MT',
            latitude: -11.86,
            longitude: -55.51,
            salesAmount: 0,
            salesCount: 0,
            city: 'Sinop',
            locationResolution:
                SalesLiveMapLocationResolution.ibgeMunicipalityCode,
          ),
        ],
        branchOptions: const <SalesLiveMapBranchOption>[],
        totalRevenue: 0,
        totalSalesCount: 0,
        totalBranchCount: 1,
        mappedBranchCount: 1,
        mappedMunicipalityCount: 1,
        queriedAgentCount: 0,
        plannedAgentCount: 0,
        failedAgentCount: 0,
        missingClientTokenAgentCount: 0,
        skippedOfflineAgentCount: 0,
        rowCapReachedAgentCount: 0,
        salesDataPending: true,
        refreshedAt: DateTime(2026, 5, 9, 12),
      );
      when(
        () => loadLiveMap.loadProgressive(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          reason: any(named: 'reason'),
          cancelToken: any(named: 'cancelToken'),
          bypassCatalogCache: any(named: 'bypassCatalogCache'),
        ),
      ).thenAnswer(
        (_) => Stream<SalesLiveMapLoadResult>.fromIterable(
          <SalesLiveMapLoadResult>[ibgePending, _loadedResult()],
        ),
      );

      await controller.bindUser('user-1');

      expect(controller.state.visualResult?.points, hasLength(1));
      expect(controller.state.visualResult?.points.single.latitude, -15.60);
      expect(controller.state.result?.salesDataPending, isFalse);
      expect(controller.state.result?.totalRevenue, 1200);
    },
  );

  test(
    'load failure technical details expose transport timeout class',
    () {
      const failure = NetworkFailure(
        message: 'bridge timeout',
        context: <String, Object?>{
          AgentSqlRpcFailureUiKey.field:
              AgentSqlRpcFailureUiKey.transportTimeout,
        },
      );
      final body = agentQueryFailureTechnicalDetailsBody(
        failure,
        l10n: AppLocalizationsEn(),
      );

      expect(
        body,
        contains(AppLocalizationsEn().agentSqlFailureTitleTransportTimeout),
      );
      expect(body, contains(AgentSqlRpcFailureUiKey.transportTimeout));
    },
  );

  test(
    'bindUser cancels stale agent load after rebinding to a different user',
    () async {
      final firstAgentsCompleter = Completer<List<DashboardAgentOption>>();
      when(
        () => loadAvailableAgentsForSales.call('user-1'),
      ).thenAnswer((_) => firstAgentsCompleter.future);
      when(
        () => loadAvailableAgentsForSales.call('user-2'),
      ).thenAnswer(
        (_) async => const <DashboardAgentOption>[
          DashboardAgentOption(agentId: 'agent-2', name: 'Agent Two'),
        ],
      );

      final firstBind = controller.bindUser('user-1');
      await Future<void>.delayed(Duration.zero);
      final secondBind = controller.bindUser('user-2');
      await secondBind;

      expect(
        controller.state.availableAgents.map((agent) => agent.agentId).toList(),
        <String>['agent-2'],
      );

      // Resolve user-1's pending agents load AFTER user-2 already bound.
      // Without the safety check inside _loadAgents the stale agents would
      // overwrite the live state and trigger a second reload with the
      // wrong filter.
      firstAgentsCompleter.complete(const <DashboardAgentOption>[
        DashboardAgentOption(agentId: 'agent-1', name: 'Agent One'),
      ]);
      await firstBind;
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.state.availableAgents.map((agent) => agent.agentId).toList(),
        <String>['agent-2'],
        reason: 'stale agent load must not pollute the new user state',
      );
    },
  );

  test('reload and applyFilter no-op while RetryAfterGate is closed', () async {
    final gate = RetryAfterGate(tickInterval: const Duration(milliseconds: 5))
      ..arm(const Duration(seconds: 30));
    controller = SalesLiveMapController(
      sessionService: SalesSessionService(salesPreferences),
      loadSalesAvailableAgentsUseCase: loadAvailableAgentsForSales,
      loadSalesLiveMapUseCase: loadLiveMap,
      retryAfterGate: gate,
    );

    await controller.bindUser('user-1');
    clearInteractions(loadLiveMap);

    final reloadOutcome = await controller.reload();
    final applyOutcome = await controller.applyFilter(controller.state.filter);

    expect(controller.isOnRetryCooldown, isTrue);
    expect(reloadOutcome.isBlockedByCooldown, isTrue);
    expect(applyOutcome, SalesLiveMapFilterMutationOutcome.blockedByCooldown);
    verifyNever(
      () => loadLiveMap.loadProgressive(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        reason: any(named: 'reason'),
        cancelToken: any(named: 'cancelToken'),
        bypassCatalogCache: any(named: 'bypassCatalogCache'),
      ),
    );
    gate.dispose();
  });

  test(
    'clearSelectedBranches and clearSavedFilters do not mutate filter while '
    'RetryAfterGate is closed',
    () async {
      final gate = RetryAfterGate(tickInterval: const Duration(milliseconds: 5))
        ..arm(const Duration(seconds: 30));
      controller = SalesLiveMapController(
        sessionService: SalesSessionService(salesPreferences),
        loadSalesAvailableAgentsUseCase: loadAvailableAgentsForSales,
        loadSalesLiveMapUseCase: loadLiveMap,
        retryAfterGate: gate,
      );

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
          periodMode: SalesLiveMapPeriodMode.lastSevenDays,
        ),
      );
      clearInteractions(loadLiveMap);
      clearInteractions(salesPreferences);
      final filterBeforeClear = controller.state.filter;
      final closeRequestBefore = controller.state.closeFullscreenRequestId;

      final clearBranchesOutcome = await controller.clearSelectedBranches();
      final clearSavedOutcome = await controller.clearSavedFilters();

      expect(clearBranchesOutcome,
          SalesLiveMapFilterMutationOutcome.blockedByCooldown);
      expect(clearSavedOutcome, SalesLiveMapFilterMutationOutcome.blockedByCooldown);
      expect(controller.state.filter, filterBeforeClear);
      expect(
        controller.state.closeFullscreenRequestId,
        closeRequestBefore,
      );
      verifyNever(
        () => loadLiveMap.loadProgressive(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          reason: any(named: 'reason'),
          cancelToken: any(named: 'cancelToken'),
          bypassCatalogCache: any(named: 'bypassCatalogCache'),
        ),
      );
      verifyNever(() => salesPreferences.persistSalesLiveMapFilter(any()));
      gate.dispose();
    },
  );

  test(
    'arms RetryAfterGate from rate-limited agent query failure on load',
    () async {
      final gate = RetryAfterGate(tickInterval: const Duration(milliseconds: 5));
      controller = SalesLiveMapController(
        sessionService: SalesSessionService(salesPreferences),
        loadSalesAvailableAgentsUseCase: loadAvailableAgentsForSales,
        loadSalesLiveMapUseCase: loadLiveMap,
        retryAfterGate: gate,
      );
      when(
        () => loadLiveMap.loadProgressive(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          reason: any(named: 'reason'),
          cancelToken: any(named: 'cancelToken'),
          bypassCatalogCache: any(named: 'bypassCatalogCache'),
        ),
      ).thenAnswer(
        (_) => Stream<SalesLiveMapLoadResult>.value(
          SalesLiveMapLoadResult(
            points: const <SalesLiveMapPoint>[],
            branchOptions: const <SalesLiveMapBranchOption>[],
            totalRevenue: 0,
            totalSalesCount: 0,
            totalBranchCount: 0,
            mappedBranchCount: 0,
            mappedMunicipalityCount: 0,
            queriedAgentCount: 0,
            plannedAgentCount: 0,
            failedAgentCount: 1,
            missingClientTokenAgentCount: 0,
            skippedOfflineAgentCount: 0,
            rowCapReachedAgentCount: 0,
            refreshedAt: DateTime(2026, 5, 9, 12),
            loadFailed: true,
            loadFailure: const RpcFailure(
              message: 'Rate limited',
              userMessage: 'Wait',
              rpcCode: -32013,
              retryable: true,
              retryAfter: Duration(seconds: 10),
            ),
            agentQueryFailures: const <AppFailure>[
              RpcFailure(
                message: 'Rate limited',
                userMessage: 'Wait',
                rpcCode: -32013,
                retryable: true,
                retryAfter: Duration(seconds: 10),
              ),
            ],
          ),
        ),
      );

      await controller.bindUser('user-1');

      expect(controller.isOnRetryCooldown, isTrue);
      gate.dispose();
    },
  );

  test(
    'arms RetryAfterGate from replay_detected agent query failure on load',
    () async {
      final gate = RetryAfterGate(tickInterval: const Duration(milliseconds: 5));
      controller = SalesLiveMapController(
        sessionService: SalesSessionService(salesPreferences),
        loadSalesAvailableAgentsUseCase: loadAvailableAgentsForSales,
        loadSalesLiveMapUseCase: loadLiveMap,
        retryAfterGate: gate,
      );
      when(
        () => loadLiveMap.loadProgressive(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          reason: any(named: 'reason'),
          cancelToken: any(named: 'cancelToken'),
          bypassCatalogCache: any(named: 'bypassCatalogCache'),
        ),
      ).thenAnswer(
        (_) => Stream<SalesLiveMapLoadResult>.value(
          SalesLiveMapLoadResult(
            points: const <SalesLiveMapPoint>[],
            branchOptions: const <SalesLiveMapBranchOption>[],
            totalRevenue: 0,
            totalSalesCount: 0,
            totalBranchCount: 0,
            mappedBranchCount: 0,
            mappedMunicipalityCount: 0,
            queriedAgentCount: 0,
            plannedAgentCount: 0,
            failedAgentCount: 1,
            missingClientTokenAgentCount: 0,
            skippedOfflineAgentCount: 0,
            rowCapReachedAgentCount: 0,
            refreshedAt: DateTime(2026, 5, 9, 12),
            loadFailed: true,
            loadFailure: const RpcFailure(
              message: 'Replay detected',
              userMessage: 'Duplicate request',
              rpcCode: -32014,
              retryable: false,
              reason: 'replay_detected',
            ),
            agentQueryFailures: const <AppFailure>[
              RpcFailure(
                message: 'Replay detected',
                userMessage: 'Duplicate request',
                rpcCode: -32014,
                retryable: false,
                reason: 'replay_detected',
              ),
            ],
          ),
        ),
      );

      await controller.bindUser('user-1');

      expect(controller.isOnRetryCooldown, isTrue);
      expect(gate.remaining, kAgentQueryReplayDetectedCooldown);
      gate.dispose();
    },
  );
}

SalesLiveMapLoadResult _mappedTwentySevenPointResult() {
  final branchOptions = List<SalesLiveMapBranchOption>.generate(
    27,
    (index) => SalesLiveMapBranchOption(
      id: 'branch-$index',
      agentId: 'agent-1',
      agentName: 'Agent One',
      codEmpresa: 1,
      codFilial: index + 1,
      registrationName: 'Branch $index',
      city: 'Cuiaba',
      uf: 'MT',
    ),
    growable: false,
  );
  final points = List<SalesLiveMapPoint>.generate(
    27,
    (index) => SalesLiveMapPoint(
      id: 'branch-$index',
      name: 'Branch $index',
      uf: 'MT',
      latitude: -15.60 - (index * 0.01),
      longitude: -56.10 - (index * 0.01),
      salesAmount: 100,
      salesCount: 1,
      city: 'Cuiaba',
    ),
    growable: false,
  );
  return SalesLiveMapLoadResult(
    points: points,
    branchOptions: branchOptions,
    totalRevenue: 2700,
    totalSalesCount: 27,
    totalBranchCount: 27,
    mappedBranchCount: 27,
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

SalesLiveMapLoadResult _catalogShellTwentySevenUnmapped({
  required bool salesDataPending,
}) {
  final branchOptions = List<SalesLiveMapBranchOption>.generate(
    27,
    (index) => SalesLiveMapBranchOption(
      id: 'branch-$index',
      agentId: 'agent-1',
      agentName: 'Agent One',
      codEmpresa: 1,
      codFilial: index + 1,
      registrationName: 'Branch $index',
      city: 'Cuiaba',
      uf: 'MT',
    ),
    growable: false,
  );
  return SalesLiveMapLoadResult(
    points: const <SalesLiveMapPoint>[],
    branchOptions: branchOptions,
    unmappedBranchOptions: branchOptions,
    totalRevenue: 0,
    totalSalesCount: 0,
    totalBranchCount: 27,
    mappedBranchCount: 0,
    mappedMunicipalityCount: 0,
    queriedAgentCount: 1,
    plannedAgentCount: 1,
    failedAgentCount: 0,
    missingClientTokenAgentCount: 0,
    skippedOfflineAgentCount: 0,
    rowCapReachedAgentCount: 0,
    salesDataPending: salesDataPending,
    refreshedAt: DateTime(2026, 5, 9, 13),
  );
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
