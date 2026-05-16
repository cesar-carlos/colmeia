import 'dart:async';

import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_live_map_page.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAuthController extends Mock implements AuthController {}

class _MockSalesPreferences extends Mock implements SalesPreferences {}

class _MockLoadAvailableAgentsForSales extends Mock
    implements LoadAvailableAgentsForSales {}

class _MockLoadSalesLiveMapUseCase extends Mock
    implements LoadSalesLiveMapUseCase {}

void main() {
  late _MockAuthController authController;
  late _MockSalesPreferences salesPreferences;
  late _MockLoadAvailableAgentsForSales loadAvailableAgentsForSales;
  late _MockLoadSalesLiveMapUseCase loadLiveMap;

  setUpAll(() {
    Provider.debugCheckInvalidValueType = null;
    registerFallbackValue(const SalesLiveMapFilter());
    registerFallbackValue(SalesLiveMapLoadCancelToken());
  });

  setUp(() async {
    await getIt.reset();

    authController = _MockAuthController();
    salesPreferences = _MockSalesPreferences();
    loadAvailableAgentsForSales = _MockLoadAvailableAgentsForSales();
    loadLiveMap = _MockLoadSalesLiveMapUseCase();

    when(() => authController.session).thenReturn(
      AuthSession(
        userId: 'user-1',
        email: EmailAddress('user@example.com'),
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        expiresAt: DateTime(2099),
      ),
    );
    when(
      () => salesPreferences.restoreSalesLiveMapFilter(),
    ).thenReturn(const SalesLiveMapFilter());
    when(
      () => salesPreferences.persistSalesLiveMapFilter(any()),
    ).thenAnswer((_) async {});
    when(
      () => loadAvailableAgentsForSales.call('user-1'),
    ).thenAnswer(
      (_) async => const <OverviewAgentOption>[
        OverviewAgentOption(agentId: 'agent-1', name: 'Branch One'),
      ],
    );
    when(
      () => loadLiveMap.loadProgressive(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) => _streamResult(_loadedResult()));

    getIt
      ..registerSingleton<SalesPreferences>(salesPreferences)
      ..registerSingleton<LoadAvailableAgentsForSales>(
        loadAvailableAgentsForSales,
      )
      ..registerSingleton<LoadSalesLiveMapUseCase>(loadLiveMap);
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets(
    'loads the live map once and stays idle while auto-refresh is off',
    (
      tester,
    ) async {
      await _pumpPage(tester, authController: authController);
      await _pumpInitialLoad(tester);

      verify(
        () => loadLiveMap.loadProgressive(
          userId: 'user-1',
          filter: any(named: 'filter'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).called(1);
      expect(find.text('Total revenue'), findsOneWidget);

      await tester.pump(const Duration(minutes: 5));
      await tester.pump();

      verifyNever(
        () => loadLiveMap.loadProgressive(
          userId: 'user-1',
          filter: any(named: 'filter'),
          cancelToken: any(named: 'cancelToken'),
        ),
      );
    },
  );

  testWidgets('reloads the live map after the selected interval', (
    tester,
  ) async {
    await _pumpPage(tester, authController: authController);
    await _pumpInitialLoad(tester);
    verify(
      () => loadLiveMap.loadProgressive(
        userId: 'user-1',
        filter: any(named: 'filter'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).called(1);

    await tester.tap(find.text('Off'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(
      find.byKey(const ValueKey<String>('sales-auto-refresh-fiveMinutes')),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.pump(const Duration(minutes: 5));
    await tester.pump();

    verify(
      () => loadLiveMap.loadProgressive(
        userId: 'user-1',
        filter: any(named: 'filter'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).called(1);
  });

  testWidgets('ignores auto-refresh tick while reload is still running', (
    tester,
  ) async {
    final completer = Completer<SalesLiveMapLoadResult>();
    when(
      () => loadLiveMap.loadProgressive(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) => _streamFromFuture(completer.future));

    await _pumpPage(tester, authController: authController);
    await tester.pump();
    await tester.pump();
    verify(
      () => loadLiveMap.loadProgressive(
        userId: 'user-1',
        filter: any(named: 'filter'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).called(1);

    await tester.tap(find.text('Off'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(
      find.byKey(const ValueKey<String>('sales-auto-refresh-fiveMinutes')),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.pump(const Duration(minutes: 5));
    await tester.pump();

    verifyNever(
      () => loadLiveMap.loadProgressive(
        userId: 'user-1',
        filter: any(named: 'filter'),
        cancelToken: any(named: 'cancelToken'),
      ),
    );

    completer.complete(_loadedResult());
    await tester.pump();
  });

  testWidgets('ignores refresh-now while a reload is still running', (
    tester,
  ) async {
    final completer = Completer<SalesLiveMapLoadResult>();
    when(
      () => loadLiveMap.loadProgressive(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) => _streamFromFuture(completer.future));

    await _pumpPage(tester, authController: authController);
    await tester.pump();
    await tester.pump();
    verify(
      () => loadLiveMap.loadProgressive(
        userId: 'user-1',
        filter: any(named: 'filter'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).called(1);

    await tester.tap(find.text('Refresh now'));
    await tester.pump();

    verifyNever(
      () => loadLiveMap.loadProgressive(
        userId: 'user-1',
        filter: any(named: 'filter'),
        cancelToken: any(named: 'cancelToken'),
      ),
    );

    completer.complete(_loadedResult());
    await tester.pump();
  });

  testWidgets('keeps initial skeleton while agents are still loading', (
    tester,
  ) async {
    final agentsCompleter = Completer<List<OverviewAgentOption>>();
    when(
      () => loadAvailableAgentsForSales.call('user-1'),
    ).thenAnswer((_) => agentsCompleter.future);

    await _pumpPage(tester, authController: authController);
    await tester.pump();

    expect(find.text('Total revenue'), findsOneWidget);
    verifyNever(
      () => loadLiveMap.loadProgressive(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        cancelToken: any(named: 'cancelToken'),
      ),
    );

    agentsCompleter.complete(const <OverviewAgentOption>[
      OverviewAgentOption(agentId: 'agent-1', name: 'Branch One'),
    ]);
    await _pumpInitialLoad(tester);
  });

  testWidgets('shows the map while sales values are still loading', (
    tester,
  ) async {
    final controller = StreamController<SalesLiveMapLoadResult>();
    addTearDown(controller.close);
    when(
      () => loadLiveMap.loadProgressive(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) => controller.stream);

    await _pumpPage(tester, authController: authController);
    await tester.pump();
    await tester.pump();

    controller.add(_pendingMapResult());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.byType(AppBrazilStoreSalesMapChart), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(AppSkeleton), findsOneWidget);
    expect(find.text('No sales in period'), findsNothing);

    controller.add(_loadedResult());
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Total revenue'), findsOneWidget);
  });

  testWidgets('does not show the map region selector', (tester) async {
    await _pumpPage(tester, authController: authController);
    await _pumpInitialLoad(tester);

    final chart = tester.widget<AppBrazilStoreSalesMapChart>(
      find.byType(AppBrazilStoreSalesMapChart).last,
    );
    expect(chart.style.showRegionFilter, isFalse);
    expect(
      chart.style.stateLabelMode,
      AppBrazilStoreSalesStateLabelMode.stateName,
    );
  });

  testWidgets('shows explicit empty state when the query returns no sales', (
    tester,
  ) async {
    when(
      () => loadLiveMap.loadProgressive(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) => _streamResult(_emptyResult()));

    await _pumpPage(tester, authController: authController);
    await _pumpInitialLoad(tester);

    expect(find.text('No sales in period'), findsOneWidget);
    expect(
      find.text(
        'The query ran, but did not find sales for the current filters.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows unmapped branches in the partial tracking panel', (
    tester,
  ) async {
    when(
      () => loadLiveMap.loadProgressive(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) => _streamResult(_partialUnmappedResult()));

    await _pumpPage(tester, authController: authController);
    await _pumpInitialLoad(tester);

    expect(find.text('Partial tracking'), findsOneWidget);
    expect(
      find.textContaining('1 branch(es) without resolved coordinates.'),
      findsOneWidget,
    );
    expect(
      find.text('Branch Without Coordinates - Unknown City / MT - Agent Two'),
      findsOneWidget,
    );
  });

  testWidgets('shows all agents without sales in the partial panel', (
    tester,
  ) async {
    when(
      () => loadLiveMap.loadProgressive(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) => _streamResult(_partialNoSalesResult()));

    await _pumpPage(tester, authController: authController);
    await _pumpInitialLoad(tester);

    expect(find.text('Partial tracking'), findsOneWidget);
    expect(
      find.textContaining(
        'Agents: 3 planned | 3 queried | 1 with sales | 2 without sales',
      ),
      findsOneWidget,
    );
    expect(find.text('Agents without sales'), findsOneWidget);
    expect(find.text('Agent Two'), findsOneWidget);
    expect(find.text('Agent Three'), findsOneWidget);
  });

  testWidgets('shows unavailable sales branches in the partial panel', (
    tester,
  ) async {
    when(
      () => loadLiveMap.loadProgressive(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) => _streamResult(_partialUnavailableSalesResult()));

    await _pumpPage(tester, authController: authController);
    await _pumpInitialLoad(tester);

    expect(find.text('Partial tracking'), findsOneWidget);
    expect(
      find.textContaining(
        '1 branch(es) shown with sales unavailable due to query failure.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('does not show the technical diagnostics panel', (tester) async {
    await _pumpPage(tester, authController: authController);
    await _pumpInitialLoad(tester);

    expect(find.text('Technical diagnostics'), findsNothing);
    expect(find.textContaining('selectedAgentIds:'), findsNothing);
    expect(find.textContaining('plannedAgentCount:'), findsNothing);
    expect(find.textContaining('noSalesBranchCount:'), findsNothing);
    expect(find.textContaining('salesUnavailableBranchCount:'), findsNothing);
    expect(find.textContaining('geo.ibgeMunicipalityCode:'), findsNothing);
  });

  testWidgets(
    'changing the map metric does not call loadProgressive again',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpPage(tester, authController: authController);
      await _pumpInitialLoad(tester);
      clearInteractions(loadLiveMap);

      await tester.ensureVisible(find.text('Vendas'));
      await tester.pump();
      await tester.tap(find.text('Vendas'));
      await tester.pump();

      verifyNever(
        () => loadLiveMap.loadProgressive(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          cancelToken: any(named: 'cancelToken'),
        ),
      );
    },
  );

  testWidgets('keeps the last map visible while a manual refresh is running', (
    tester,
  ) async {
    await _pumpPage(tester, authController: authController);
    await _pumpInitialLoad(tester);
    verify(
      () => loadLiveMap.loadProgressive(
        userId: 'user-1',
        filter: any(named: 'filter'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).called(1);

    final reloadCompleter = Completer<SalesLiveMapLoadResult>();
    when(
      () => loadLiveMap.loadProgressive(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) => _streamFromFuture(reloadCompleter.future));

    await tester.tap(find.text('Refresh now'));
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Total revenue'), findsOneWidget);
    expect(find.byType(AppBrazilStoreSalesMapChart), findsOneWidget);

    reloadCompleter.complete(_loadedResult());
    await tester.pump();
  });

  testWidgets(
    'does not restore a stale selected branch filter when the result is empty',
    (
      tester,
    ) async {
      when(
        () => salesPreferences.restoreSalesLiveMapFilter(),
      ).thenReturn(
        const SalesLiveMapFilter(
          selectedAgentIds: <String>{'agent-1'},
          selectedBranchIds: <String>{'agent-1-1-1'},
        ),
      );
      var callCount = 0;
      when(
        () => loadLiveMap.loadProgressive(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) {
        callCount += 1;
        return _streamResult(callCount == 1 ? _emptyResult() : _loadedResult());
      });

      await _pumpPage(tester, authController: authController);
      await _pumpInitialLoad(tester);

      expect(find.text('No sales in period'), findsOneWidget);
      expect(find.text('Selection has no result'), findsNothing);

      final capturedFilters = verify(
        () => loadLiveMap.loadProgressive(
          userId: 'user-1',
          filter: captureAny(named: 'filter'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).captured.cast<SalesLiveMapFilter>().toList();
      expect(capturedFilters.first.selectedBranchIds, isNull);
      expect(capturedFilters.first.selectedAgentIds, isNull);
    },
  );

  testWidgets('clears restored branch selection before first load', (
    tester,
  ) async {
    when(
      () => salesPreferences.restoreSalesLiveMapFilter(),
    ).thenReturn(
      const SalesLiveMapFilter(
        selectedAgentIds: <String>{'agent-1'},
        selectedBranchIds: <String>{'agent-1-1-1'},
      ),
    );

    await _pumpPage(tester, authController: authController);
    await _pumpInitialLoad(tester);

    final capturedFilters = verify(
      () => loadLiveMap.loadProgressive(
        userId: 'user-1',
        filter: captureAny(named: 'filter'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).captured.cast<SalesLiveMapFilter>().toList();
    expect(capturedFilters.first.selectedBranchIds, isNull);
    expect(capturedFilters.first.selectedAgentIds, isNull);

    final persistedFilters = verify(
      () => salesPreferences.persistSalesLiveMapFilter(captureAny()),
    ).captured.cast<SalesLiveMapFilter>().toList();
    expect(persistedFilters.first.selectedBranchIds, isNull);
    expect(persistedFilters.first.selectedAgentIds, isNull);
  });

  testWidgets(
    'clears persisted filters and reloads with the default filter',
    (
      tester,
    ) async {
      when(
        () => salesPreferences.restoreSalesLiveMapFilter(),
      ).thenReturn(
        const SalesLiveMapFilter(
          selectedAgentIds: <String>{'agent-1'},
          selectedBranchIds: <String>{'agent-1-1-1'},
          periodMode: SalesLiveMapPeriodMode.lastSevenDays,
          detailLevel: SalesLiveMapMapDetail.municipalities,
          markerVisual: SalesLiveMapMarkerVisual.bubble,
          metric: AppBrazilStoreSalesMapMetric.salesCount,
        ),
      );

      await _pumpPage(tester, authController: authController);
      await _pumpInitialLoad(tester);

      final clearSaved = find.widgetWithText(
        OutlinedButton,
        'Clear saved filters',
      );
      expect(clearSaved, findsOneWidget);

      await tester.tap(clearSaved);
      await _pumpInitialLoad(tester);

      final persistedFilters = verify(
        () => salesPreferences.persistSalesLiveMapFilter(captureAny()),
      ).captured.cast<SalesLiveMapFilter>().toList();
      expect(persistedFilters.last.selectedAgentIds, isNull);
      expect(persistedFilters.last.selectedBranchIds, isNull);
      expect(
        persistedFilters.last.periodMode,
        SalesLiveMapPeriodMode.today,
      );
      expect(
        persistedFilters.last.detailLevel,
        SalesLiveMapMapDetail.branches,
      );
      expect(
        persistedFilters.last.markerVisual,
        SalesLiveMapMarkerVisual.dot,
      );
      expect(
        persistedFilters.last.metric,
        AppBrazilStoreSalesMapMetric.revenue,
      );

      final capturedFilters = verify(
        () => loadLiveMap.loadProgressive(
          userId: 'user-1',
          filter: captureAny(named: 'filter'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).captured.cast<SalesLiveMapFilter>().toList();
      expect(capturedFilters.last.selectedAgentIds, isNull);
      expect(capturedFilters.last.selectedBranchIds, isNull);
    },
  );

  testWidgets('toggles map branch focus without persisting it', (
    tester,
  ) async {
    await _pumpPage(tester, authController: authController);
    await _pumpInitialLoad(tester);
    clearInteractions(salesPreferences);

    var chart = tester.widget<AppBrazilStoreSalesMapChart>(
      find.byType(AppBrazilStoreSalesMapChart).last,
    );
    expect(chart.fixedBranchIds, isEmpty);

    chart.onBranchFilter!(
      const AppBrazilStoreSalesPointTapEvent(
        point: AppBrazilStoreSalesPoint(
          id: 'agent-1-1-1',
          name: 'Branch One',
          uf: 'MT',
          latitude: -15.60,
          longitude: -56.10,
          salesAmount: 1200,
          salesCount: 12,
          city: 'Cuiaba',
        ),
        index: 0,
        metric: AppBrazilStoreSalesMapMetric.revenue,
      ),
    );
    await tester.pump();

    chart = tester.widget(find.byType(AppBrazilStoreSalesMapChart).last);
    expect(chart.fixedBranchIds, <String>{'agent-1-1-1'});

    chart.onBranchFilter!(
      const AppBrazilStoreSalesPointTapEvent(
        point: AppBrazilStoreSalesPoint(
          id: 'agent-1-1-1',
          name: 'Branch One',
          uf: 'MT',
          latitude: -15.60,
          longitude: -56.10,
          salesAmount: 1200,
          salesCount: 12,
          city: 'Cuiaba',
        ),
        index: 0,
        metric: AppBrazilStoreSalesMapMetric.revenue,
      ),
    );
    await tester.pump();

    chart = tester.widget(find.byType(AppBrazilStoreSalesMapChart).last);
    expect(chart.fixedBranchIds, isEmpty);

    verify(
      () => loadLiveMap.loadProgressive(
        userId: 'user-1',
        filter: any(named: 'filter'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).called(1);
    verifyNever(() => salesPreferences.persistSalesLiveMapFilter(any()));
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required AuthController authController,
}) async {
  await tester.pumpWidget(
    Provider<AuthController>.value(
      value: authController,
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SalesLiveMapPage(),
        ),
      ),
    ),
  );
}

Future<void> _pumpInitialLoad(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

Stream<SalesLiveMapLoadResult> _streamResult(SalesLiveMapLoadResult result) {
  return Stream<SalesLiveMapLoadResult>.value(result);
}

Stream<SalesLiveMapLoadResult> _streamFromFuture(
  Future<SalesLiveMapLoadResult> future,
) {
  return Stream<SalesLiveMapLoadResult>.fromFuture(future);
}

SalesLiveMapLoadResult _loadedResult() {
  return SalesLiveMapLoadResult(
    points: const <AppBrazilStoreSalesPoint>[
      AppBrazilStoreSalesPoint(
        id: 'agent-1-1-1',
        name: 'Branch One',
        uf: 'MT',
        latitude: -15.60,
        longitude: -56.10,
        salesAmount: 1200,
        salesCount: 12,
        city: 'Cuiaba',
      ),
    ],
    branchOptions: const <SalesLiveMapBranchOption>[
      SalesLiveMapBranchOption(
        id: 'agent-1-1-1',
        agentId: 'agent-1',
        agentName: 'Branch One',
        codEmpresa: 1,
        codFilial: 1,
        name: 'Branch One',
        city: 'Cuiaba',
        uf: 'MT',
      ),
    ],
    totalRevenue: 1200,
    totalSalesCount: 12,
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

SalesLiveMapLoadResult _pendingMapResult() {
  return SalesLiveMapLoadResult(
    points: const <AppBrazilStoreSalesPoint>[
      AppBrazilStoreSalesPoint(
        id: 'agent-1-1-1',
        name: 'Branch One',
        uf: 'MT',
        latitude: -15.60,
        longitude: -56.10,
        salesAmount: 0,
        salesCount: 0,
        city: 'Cuiaba',
        salesDataLoading: true,
      ),
    ],
    branchOptions: const <SalesLiveMapBranchOption>[
      SalesLiveMapBranchOption(
        id: 'agent-1-1-1',
        agentId: 'agent-1',
        agentName: 'Branch One',
        codEmpresa: 1,
        codFilial: 1,
        name: 'Branch One',
        city: 'Cuiaba',
        uf: 'MT',
      ),
    ],
    totalRevenue: 0,
    totalSalesCount: 0,
    totalBranchCount: 1,
    mappedBranchCount: 1,
    mappedMunicipalityCount: 1,
    queriedAgentCount: 1,
    plannedAgentCount: 1,
    failedAgentCount: 0,
    missingClientTokenAgentCount: 0,
    skippedOfflineAgentCount: 0,
    rowCapReachedAgentCount: 0,
    salesDataPending: true,
    salesPendingBranchCount: 1,
    refreshedAt: DateTime(2026, 5, 9, 12),
  );
}

SalesLiveMapLoadResult _partialUnmappedResult() {
  return SalesLiveMapLoadResult(
    points: const <AppBrazilStoreSalesPoint>[
      AppBrazilStoreSalesPoint(
        id: 'agent-1-1-1',
        name: 'Branch One',
        uf: 'MT',
        latitude: -15.60,
        longitude: -56.10,
        salesAmount: 1200,
        salesCount: 12,
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
        name: 'Branch One',
        city: 'Cuiaba',
        uf: 'MT',
      ),
      SalesLiveMapBranchOption(
        id: 'agent-2-1-2',
        agentId: 'agent-2',
        agentName: 'Agent Two',
        codEmpresa: 1,
        codFilial: 2,
        name: 'Branch Without Coordinates',
        city: 'Unknown City',
        uf: 'MT',
      ),
    ],
    unmappedBranchOptions: const <SalesLiveMapBranchOption>[
      SalesLiveMapBranchOption(
        id: 'agent-2-1-2',
        agentId: 'agent-2',
        agentName: 'Agent Two',
        codEmpresa: 1,
        codFilial: 2,
        name: 'Branch Without Coordinates',
        city: 'Unknown City',
        uf: 'MT',
      ),
    ],
    totalRevenue: 1500,
    totalSalesCount: 15,
    totalBranchCount: 2,
    mappedBranchCount: 1,
    mappedMunicipalityCount: 1,
    queriedAgentCount: 2,
    plannedAgentCount: 2,
    failedAgentCount: 0,
    missingClientTokenAgentCount: 0,
    skippedOfflineAgentCount: 0,
    rowCapReachedAgentCount: 0,
    salesAgentCount: 2,
    refreshedAt: DateTime(2026, 5, 9, 12),
  );
}

SalesLiveMapLoadResult _partialNoSalesResult() {
  return SalesLiveMapLoadResult(
    points: const <AppBrazilStoreSalesPoint>[
      AppBrazilStoreSalesPoint(
        id: 'agent-1-1-1',
        name: 'Branch One',
        uf: 'MT',
        latitude: -15.60,
        longitude: -56.10,
        salesAmount: 1200,
        salesCount: 12,
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
        name: 'Branch One',
        city: 'Cuiaba',
        uf: 'MT',
      ),
    ],
    totalRevenue: 1200,
    totalSalesCount: 12,
    totalBranchCount: 1,
    mappedBranchCount: 1,
    mappedMunicipalityCount: 1,
    queriedAgentCount: 3,
    plannedAgentCount: 3,
    failedAgentCount: 0,
    missingClientTokenAgentCount: 0,
    skippedOfflineAgentCount: 0,
    rowCapReachedAgentCount: 0,
    salesAgentCount: 1,
    noSalesAgentOptions: const <SalesLiveMapAgentOption>[
      SalesLiveMapAgentOption(id: 'agent-2', name: 'Agent Two'),
      SalesLiveMapAgentOption(id: 'agent-3', name: 'Agent Three'),
    ],
    refreshedAt: DateTime(2026, 5, 9, 12),
  );
}

SalesLiveMapLoadResult _partialUnavailableSalesResult() {
  return SalesLiveMapLoadResult(
    points: const <AppBrazilStoreSalesPoint>[
      AppBrazilStoreSalesPoint(
        id: 'agent-1-1-1',
        name: 'Branch One',
        uf: 'MT',
        latitude: -15.60,
        longitude: -56.10,
        salesAmount: 0,
        salesCount: 0,
        city: 'Cuiaba',
        salesDataUnavailable: true,
        salesDataStatusLabel: 'Sales unavailable.',
      ),
    ],
    branchOptions: const <SalesLiveMapBranchOption>[
      SalesLiveMapBranchOption(
        id: 'agent-1-1-1',
        agentId: 'agent-1',
        agentName: 'Agent One',
        codEmpresa: 1,
        codFilial: 1,
        name: 'Branch One',
        city: 'Cuiaba',
        uf: 'MT',
      ),
    ],
    totalRevenue: 0,
    totalSalesCount: 0,
    totalBranchCount: 1,
    mappedBranchCount: 1,
    mappedMunicipalityCount: 1,
    queriedAgentCount: 1,
    plannedAgentCount: 1,
    failedAgentCount: 1,
    missingClientTokenAgentCount: 0,
    skippedOfflineAgentCount: 0,
    rowCapReachedAgentCount: 0,
    zeroedBranchCount: 1,
    salesUnavailableBranchCount: 1,
    failedSalesAgentCount: 1,
    refreshedAt: DateTime(2026, 5, 9, 12),
  );
}

SalesLiveMapLoadResult _emptyResult() {
  return SalesLiveMapLoadResult(
    points: const <AppBrazilStoreSalesPoint>[],
    branchOptions: const <SalesLiveMapBranchOption>[],
    totalRevenue: 0,
    totalSalesCount: 0,
    totalBranchCount: 0,
    mappedBranchCount: 0,
    mappedMunicipalityCount: 0,
    queriedAgentCount: 1,
    plannedAgentCount: 1,
    failedAgentCount: 0,
    missingClientTokenAgentCount: 0,
    skippedOfflineAgentCount: 0,
    rowCapReachedAgentCount: 0,
    refreshedAt: DateTime(2026, 5, 9, 12),
  );
}
