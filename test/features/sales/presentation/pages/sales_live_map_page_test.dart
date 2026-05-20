import 'dart:async';

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/core/refresh/auto_refresh_snapshot.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/application/load_sales_available_agents_use_case.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/application/sales_live_map_reload_reason.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_metric.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_live_map_controller.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_live_map_page.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAuthController extends Mock implements AuthController {}

class _MockSalesPreferences extends Mock implements SalesPreferences {}

class _MockLoadAvailableAgentsForSales extends Mock
    implements LoadAvailableAgentsForSales {}

class _MockLoadSalesLiveMapUseCase extends Mock
    implements LoadSalesLiveMapUseCase {}

late SalesPreferences _pumpSalesPreferences;
late LoadAvailableAgentsForSales _pumpLoadAvailableAgentsForSales;
late LoadSalesLiveMapUseCase _pumpLoadLiveMap;

void main() {
  late _MockAuthController authController;
  late _MockSalesPreferences salesPreferences;
  late _MockLoadAvailableAgentsForSales loadAvailableAgentsForSales;
  late _MockLoadSalesLiveMapUseCase loadLiveMap;

  setUpAll(() {
    Provider.debugCheckInvalidValueType = null;
    registerFallbackValue(const SalesLiveMapFilter());
    registerFallbackValue(SalesLiveMapLoadCancelToken());
    registerFallbackValue(SalesLiveMapReloadReason.manual);
    registerFallbackValue(AutoRefreshSnapshot.disabled);
    registerFallbackValue(SalesAutoRefreshOptions.optionSet);
  });

  setUp(() async {
    authController = _MockAuthController();
    salesPreferences = _MockSalesPreferences();
    loadAvailableAgentsForSales = _MockLoadAvailableAgentsForSales();
    loadLiveMap = _MockLoadSalesLiveMapUseCase();
    _pumpSalesPreferences = salesPreferences;
    _pumpLoadAvailableAgentsForSales = loadAvailableAgentsForSales;
    _pumpLoadLiveMap = loadLiveMap;

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
      () => salesPreferences.restoreAutoRefreshSnapshot(
        cardId: any(named: 'cardId'),
        optionSet: any(named: 'optionSet'),
      ),
    ).thenReturn(AutoRefreshSnapshot.disabled);
    when(
      () => salesPreferences.persistAutoRefreshSnapshot(
        cardId: any(named: 'cardId'),
        snapshot: any(named: 'snapshot'),
      ),
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
        reason: any(named: 'reason'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) => _streamResult(_loadedResult()));
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
          reason: any(named: 'reason'),
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
          reason: any(named: 'reason'),
          cancelToken: any(named: 'cancelToken'),
        ),
      );
    },
  );

  testWidgets('reloads the live map after the selected interval', (
    tester,
  ) async {
    await _setDesktopSurface(tester);
    await _pumpPage(
      tester,
      authController: authController,
      mediaSize: const Size(1400, 900),
    );
    await _pumpInitialLoad(tester);
    verify(
      () => loadLiveMap.loadProgressive(
        userId: 'user-1',
        filter: any(named: 'filter'),
        reason: any(named: 'reason'),
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
        reason: any(named: 'reason'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).called(1);
  });

  testWidgets(
    'restores the persisted auto-refresh interval and last updated label',
    (tester) async {
      await _setDesktopSurface(tester);
      when(
        () => salesPreferences.restoreAutoRefreshSnapshot(
          cardId: any(named: 'cardId'),
          optionSet: any(named: 'optionSet'),
        ),
      ).thenReturn(
        AutoRefreshSnapshot(
          option: SalesAutoRefreshOptions.fiveMinutes,
          lastSuccessfulRefreshAt: DateTime(2026, 5, 9, 11, 45),
          remainingDelay: const Duration(minutes: 5),
        ),
      );

      await _pumpPage(
        tester,
        authController: authController,
        mediaSize: const Size(1400, 900),
      );
      await _pumpInitialLoad(tester);

      expect(find.text('5 min'), findsOneWidget);
      expect(find.textContaining('Updated 12:00'), findsOneWidget);
      expect(find.textContaining('Next in'), findsOneWidget);
    },
  );

  testWidgets(
    'does not show the next auto-refresh countdown outside desktop viewports',
    (tester) async {
      when(
        () => salesPreferences.restoreAutoRefreshSnapshot(
          cardId: any(named: 'cardId'),
          optionSet: any(named: 'optionSet'),
        ),
      ).thenReturn(
        AutoRefreshSnapshot(
          option: SalesAutoRefreshOptions.fiveMinutes,
          lastSuccessfulRefreshAt: DateTime(2026, 5, 9, 11, 45),
          remainingDelay: const Duration(minutes: 5),
        ),
      );

      await _pumpPage(
        tester,
        authController: authController,
        mediaSize: const Size(800, 600),
      );
      await _pumpInitialLoad(tester);

      expect(find.textContaining('Updated 12:00'), findsOneWidget);
      expect(find.textContaining('Next in'), findsNothing);
      expect(find.text('5 min'), findsNothing);
      expect(
        find.text('Auto-refresh available on desktop'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'does not advance last updated label while progressive sales data is pending',
    (tester) async {
      await _setDesktopSurface(tester);
      final controller = StreamController<SalesLiveMapLoadResult>();
      addTearDown(controller.close);
      when(
        () => salesPreferences.restoreAutoRefreshSnapshot(
          cardId: any(named: 'cardId'),
          optionSet: any(named: 'optionSet'),
        ),
      ).thenReturn(
        AutoRefreshSnapshot(
          option: SalesAutoRefreshOptions.fiveMinutes,
          lastSuccessfulRefreshAt: DateTime(2026, 5, 9, 11, 45),
          remainingDelay: const Duration(minutes: 5),
        ),
      );
      when(
        () => loadLiveMap.loadProgressive(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          reason: any(named: 'reason'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) => controller.stream);

      await _pumpPage(
        tester,
        authController: authController,
        mediaSize: const Size(1400, 900),
      );
      await tester.pump();
      await tester.pump();

      controller.add(_pendingMapResult());
      await tester.pump();

      expect(find.textContaining('Updated 11:45'), findsOneWidget);
      expect(find.textContaining('Updated 12:00'), findsNothing);

      controller.add(_loadedResult());
      await tester.pump();

      expect(find.textContaining('Updated 12:00'), findsOneWidget);
    },
  );

  testWidgets(
    'does not advance last updated label when the reload fails',
    (tester) async {
      await _setDesktopSurface(tester);
      when(
        () => salesPreferences.restoreAutoRefreshSnapshot(
          cardId: any(named: 'cardId'),
          optionSet: any(named: 'optionSet'),
        ),
      ).thenReturn(
        AutoRefreshSnapshot(
          option: SalesAutoRefreshOptions.fiveMinutes,
          lastSuccessfulRefreshAt: DateTime(2026, 5, 9, 11, 45),
          remainingDelay: const Duration(minutes: 5),
        ),
      );
      when(
        () => loadLiveMap.loadProgressive(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          reason: any(named: 'reason'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) => _streamResult(_failedResult()));

      await _pumpPage(
        tester,
        authController: authController,
        mediaSize: const Size(1400, 900),
      );
      await _pumpInitialLoad(tester);

      expect(find.textContaining('Updated 11:45'), findsOneWidget);
      expect(find.textContaining('Updated 12:00'), findsNothing);
      expect(find.textContaining('Next in'), findsOneWidget);
    },
  );

  testWidgets(
    'keeps refresh now enabled when auto-refresh scheduling is unavailable',
    (tester) async {
      await _setDesktopSurface(tester);
      when(
        () => loadAvailableAgentsForSales.call('user-1'),
      ).thenAnswer(
        (_) async => const <OverviewAgentOption>[
          OverviewAgentOption(
            agentId: 'agent-1',
            name: 'Branch One',
            missingLocalClientToken: true,
          ),
        ],
      );

      await _pumpPage(
        tester,
        authController: authController,
        mediaSize: const Size(1400, 900),
      );
      await _pumpInitialLoad(tester);

      final refreshNowButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Refresh now'),
      );
      expect(refreshNowButton.onPressed, isNotNull);
    },
  );

  testWidgets('ignores refresh-now while a reload is still running', (
    tester,
  ) async {
    final completer = Completer<SalesLiveMapLoadResult>();
    when(
      () => loadLiveMap.loadProgressive(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        reason: any(named: 'reason'),
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
        reason: any(named: 'reason'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).called(1);

    await tester.tap(find.text('Refresh now'));
    await tester.pump();

    verifyNever(
      () => loadLiveMap.loadProgressive(
        userId: 'user-1',
        filter: any(named: 'filter'),
        reason: any(named: 'reason'),
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
        reason: any(named: 'reason'),
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
        reason: any(named: 'reason'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) => controller.stream);

    await _pumpPage(tester, authController: authController);
    await tester.pump();
    await tester.pump();

    controller.add(_pendingMapResult());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    final pendingChart = tester.widget<AppBrazilStoreSalesMapChart>(
      find.byType(AppBrazilStoreSalesMapChart).last,
    );
    expect(pendingChart.isRefreshing, isTrue);
    expect(find.byType(AppBrazilStoreSalesMapChart), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    expect(find.byType(AppSkeleton), findsOneWidget);
    expect(find.text('No sales in period'), findsNothing);

    controller.add(_loadedResult());
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Total revenue'), findsOneWidget);
  });

  testWidgets(
    'keeps the initial skeleton when the first pending emission has no map snapshot',
    (tester) async {
      final controller = StreamController<SalesLiveMapLoadResult>();
      addTearDown(controller.close);
      when(
        () => loadLiveMap.loadProgressive(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          reason: any(named: 'reason'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) => controller.stream);

      await _pumpPage(tester, authController: authController);
      await tester.pump();
      await tester.pump();

      controller.add(
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
      await tester.pump();

      final pendingChart = tester.widget<AppBrazilStoreSalesMapChart>(
        find.byType(AppBrazilStoreSalesMapChart).last,
      );
      expect(pendingChart.subtitle, isNull);
      expect(pendingChart.points, isEmpty);
      expect(find.byType(AppSkeleton), findsOneWidget);

      controller.add(_loadedResult());
      await tester.pump();

      final loadedChart = tester.widget<AppBrazilStoreSalesMapChart>(
        find.byType(AppBrazilStoreSalesMapChart).last,
      );
      expect(loadedChart.subtitle, isNotNull);
      expect(loadedChart.points, isNotEmpty);
    },
  );

  testWidgets('does not show the map region selector', (tester) async {
    await _pumpPage(tester, authController: authController);
    await _pumpInitialLoad(tester);

    final chart = tester.widget<AppBrazilStoreSalesMapChart>(
      find.byType(AppBrazilStoreSalesMapChart).last,
    );
    expect(chart.style.showRegionFilter, isFalse);
    expect(
      chart.presentationMode,
      AppBrazilStoreSalesMapPresentationMode.inlineOperational,
    );
    expect(chart.style.showLegend, isTrue);
    expect(chart.style.showMarkerScaleLegend, isTrue);
    expect(chart.style.height, 560);
    expect(
      chart.style.stateLabelMode,
      AppBrazilStoreSalesStateLabelMode.uf,
    );
  });

  testWidgets(
    'keeps the desktop branch sidebar disabled inline and enables it in fullscreen',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (context, state) =>
                ChangeNotifierProvider<SalesLiveMapController>(
                  create: (_) => SalesLiveMapController(
                    sessionService: SalesSessionService(_pumpSalesPreferences),
                    loadSalesAvailableAgentsUseCase:
                        LoadSalesAvailableAgentsUseCase(
                          _pumpLoadAvailableAgentsForSales,
                        ),
                    loadSalesLiveMapUseCase: _pumpLoadLiveMap,
                  ),
                  child: const Scaffold(body: SalesLiveMapPage()),
                ),
          ),
          ...buildAppChartFullscreenRoutes(),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        Provider<AuthController>.value(
          value: authController,
          child: MaterialApp.router(
            theme: AppTheme.light(),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await _pumpInitialLoad(tester);

      final inlineChart = tester.widget<AppBrazilStoreSalesMapChart>(
        find.byType(AppBrazilStoreSalesMapChart).last,
      );
      expect(inlineChart.showDesktopBranchSidebar, isFalse);
      expect(
        inlineChart.presentationMode,
        AppBrazilStoreSalesMapPresentationMode.inlineOperational,
      );

      final fullscreenFinder = find.byIcon(Icons.open_in_full);
      await tester.ensureVisible(fullscreenFinder);
      await tester.pump();
      await tester.tap(fullscreenFinder);
      await tester.pumpAndSettle();

      final fullscreenChart = tester.widget<AppBrazilStoreSalesMapChart>(
        find.byType(AppBrazilStoreSalesMapChart),
      );
      expect(find.byType(AppBrazilStoreSalesMapChart), findsOneWidget);
      expect(fullscreenChart.showDesktopBranchSidebar, isTrue);
      expect(
        fullscreenChart.presentationMode,
        AppBrazilStoreSalesMapPresentationMode.cleanFullscreen,
      );
      expect(fullscreenChart.style.showLegend, isTrue);
      expect(fullscreenChart.style.showMarkerScaleLegend, isTrue);
      expect(
        find.byKey(const ValueKey<String>('brazil-store-sales-map-sidebar')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-map-sidebar-floating'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Branches:'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('brazil-store-sales-map-legend-button'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'keeps fullscreen open and updates the map when the controller reloads new data',
    (tester) async {
      await _setDesktopSurface(tester);
      var callCount = 0;
      when(
        () => loadLiveMap.loadProgressive(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          reason: any(named: 'reason'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) {
        callCount += 1;
        return _streamResult(
          callCount == 1 ? _loadedResult() : _twoBranchLoadedResult(),
        );
      });

      final router = await _pumpPageWithRouter(
        tester,
        authController: authController,
      );
      await _pumpInitialLoad(tester);

      final controller = tester
          .element(find.byType(SalesLiveMapPage).first)
          .read<SalesLiveMapController>();
      final fullscreenFinder = find.byIcon(Icons.open_in_full);
      await tester.ensureVisible(fullscreenFinder);
      await tester.pump();
      await tester.tap(fullscreenFinder);
      await tester.pumpAndSettle();

      var fullscreenChart = tester.widget<AppBrazilStoreSalesMapChart>(
        find.byType(AppBrazilStoreSalesMapChart),
      );
      expect(find.byType(AppBrazilStoreSalesMapChart), findsOneWidget);
      expect(fullscreenChart.points, hasLength(1));
      expect(
        find.textContaining('data loaded when you opened fullscreen'),
        findsNothing,
      );

      await controller.reload();
      await tester.pumpAndSettle();

      fullscreenChart = tester.widget<AppBrazilStoreSalesMapChart>(
        find.byType(AppBrazilStoreSalesMapChart),
      );
      expect(find.byType(AppBrazilStoreSalesMapChart), findsOneWidget);
      expect(fullscreenChart.points, hasLength(2));
      expect(router.canPop(), isTrue);
      expect(router.state.matchedLocation, AppRoute.chartFullscreen.path);
    },
  );

  testWidgets(
    'rebuilds the inline chart from controller state after closing fullscreen without reloading',
    (tester) async {
      await _setDesktopSurface(tester);
      var callCount = 0;
      when(
        () => loadLiveMap.loadProgressive(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          reason: any(named: 'reason'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) {
        callCount += 1;
        return _streamResult(
          callCount == 1 ? _loadedResult() : _twoBranchLoadedResult(),
        );
      });

      final router = await _pumpPageWithRouter(
        tester,
        authController: authController,
      );
      await _pumpInitialLoad(tester);

      final controller = tester
          .element(find.byType(SalesLiveMapPage).first)
          .read<SalesLiveMapController>();
      final fullscreenFinder = find.byIcon(Icons.open_in_full);
      await tester.ensureVisible(fullscreenFinder);
      await tester.pump();
      await tester.tap(fullscreenFinder);
      await tester.pumpAndSettle();

      expect(find.byType(AppBrazilStoreSalesMapChart), findsOneWidget);

      await controller.reload();
      await tester.pumpAndSettle();

      expect(find.byType(AppBrazilStoreSalesMapChart), findsOneWidget);
      clearInteractions(loadLiveMap);

      router.pop();
      await tester.pumpAndSettle();

      final inlineChart = tester.widget<AppBrazilStoreSalesMapChart>(
        find.byType(AppBrazilStoreSalesMapChart),
      );
      expect(inlineChart.points, hasLength(2));
      expect(
        inlineChart.presentationMode,
        AppBrazilStoreSalesMapPresentationMode.inlineOperational,
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

  testWidgets('auto-refresh keeps reloading while fullscreen is open', (
    tester,
  ) async {
    await _setDesktopSurface(tester);
    when(
      () => salesPreferences.restoreAutoRefreshSnapshot(
        cardId: any(named: 'cardId'),
        optionSet: any(named: 'optionSet'),
      ),
    ).thenReturn(
      const AutoRefreshSnapshot(
        option: SalesAutoRefreshOptions.fiveMinutes,
        remainingDelay: Duration(minutes: 5),
      ),
    );
    final router = await _pumpPageWithRouter(
      tester,
      authController: authController,
    );
    await _pumpInitialLoad(tester);
    verify(
      () => loadLiveMap.loadProgressive(
        userId: 'user-1',
        filter: any(named: 'filter'),
        reason: any(named: 'reason'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).called(1);

    final fullscreenFinder = find.byIcon(Icons.open_in_full);
    await tester.ensureVisible(fullscreenFinder);
    await tester.pump();
    await tester.tap(fullscreenFinder);
    await tester.pumpAndSettle();
    clearInteractions(loadLiveMap);

    await tester.pump(const Duration(minutes: 5));
    await tester.pump();

    verify(
      () => loadLiveMap.loadProgressive(
        userId: 'user-1',
        filter: any(named: 'filter'),
        reason: any(named: 'reason'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).called(1);
    expect(router.canPop(), isTrue);
    expect(router.state.matchedLocation, AppRoute.chartFullscreen.path);
  });

  testWidgets('shows explicit empty state when the query returns no sales', (
    tester,
  ) async {
    when(
      () => loadLiveMap.loadProgressive(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        reason: any(named: 'reason'),
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
        reason: any(named: 'reason'),
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
      find.text('Branch Without Coordinates - Unknown City / MT - Two'),
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
        reason: any(named: 'reason'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) => _streamResult(_partialNoSalesResult()));

    await _pumpPage(tester, authController: authController);
    await _pumpInitialLoad(tester);

    expect(find.text('Partial tracking'), findsOneWidget);
    expect(
      find.textContaining(
        'Branches: 3 planned | 3 queried | 1 with sales | 2 without sales',
      ),
      findsOneWidget,
    );
    expect(find.text('Branches without sales'), findsOneWidget);
    expect(find.text('Two'), findsOneWidget);
    expect(find.text('Three'), findsOneWidget);
  });

  testWidgets('shows unavailable sales branches in the partial panel', (
    tester,
  ) async {
    when(
      () => loadLiveMap.loadProgressive(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        reason: any(named: 'reason'),
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

      final context = tester.element(find.byType(SalesLiveMapPage));
      final l10n = AppLocalizations.of(context);
      final salesMetricLabel = l10n.brazilStoreSalesMapMetricSalesShort;
      final salesMetricFinder = find.descendant(
        of: find.byKey(
          const ValueKey<String>('app-region-map-metric-selector'),
        ),
        matching: find.text(salesMetricLabel),
      );

      await tester.ensureVisible(salesMetricFinder);
      await tester.pump();
      await tester.tap(salesMetricFinder.last);
      await tester.pump();

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

  testWidgets('keeps the last map visible while a manual refresh is running', (
    tester,
  ) async {
    await _pumpPage(tester, authController: authController);
    await _pumpInitialLoad(tester);
    verify(
      () => loadLiveMap.loadProgressive(
        userId: 'user-1',
        filter: any(named: 'filter'),
        reason: any(named: 'reason'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).called(1);

    final reloadCompleter = Completer<SalesLiveMapLoadResult>();
    when(
      () => loadLiveMap.loadProgressive(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        reason: any(named: 'reason'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) => _streamFromFuture(reloadCompleter.future));

    await tester.tap(find.text('Refresh now'));
    await tester.pump();

    final refreshingChart = tester.widget<AppBrazilStoreSalesMapChart>(
      find.byType(AppBrazilStoreSalesMapChart).last,
    );
    expect(refreshingChart.isRefreshing, isTrue);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
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
      var callCount = 0;
      when(
        () => loadLiveMap.loadProgressive(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          reason: any(named: 'reason'),
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
          reason: any(named: 'reason'),
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

    await _pumpPage(tester, authController: authController);
    await _pumpInitialLoad(tester);

    final capturedFilters = verify(
      () => loadLiveMap.loadProgressive(
        userId: 'user-1',
        filter: captureAny(named: 'filter'),
        reason: any(named: 'reason'),
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
        SalesLiveMapMetric.revenue,
      );

      final capturedFilters = verify(
        () => loadLiveMap.loadProgressive(
          userId: 'user-1',
          filter: captureAny(named: 'filter'),
          reason: any(named: 'reason'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).captured.cast<SalesLiveMapFilter>().toList();
      expect(capturedFilters.last.selectedAgentIds, isNull);
      expect(capturedFilters.last.selectedBranchIds, isNull);
    },
  );

  testWidgets(
    'sheet single-branch filter exposes filterBranchIds and fixedBranchIds',
    (tester) async {
      when(
        () => loadLiveMap.loadProgressive(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          reason: any(named: 'reason'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) => _streamResult(_twoBranchLoadedResult()));

      await _pumpPage(tester, authController: authController);
      await _pumpInitialLoad(tester);

      await tester.tap(find.byIcon(Icons.filter_list_rounded));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Branch Two'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Branch Two'));
      await tester.pump();
      await tester.ensureVisible(find.text('Apply filters'));
      await tester.tap(find.text('Apply filters'));
      await tester.pumpAndSettle();

      final chart = tester.widget<AppBrazilStoreSalesMapChart>(
        find.byType(AppBrazilStoreSalesMapChart).last,
      );
      expect(chart.filterBranchIds, <String>{'agent-1-1-1'});
      expect(chart.fixedBranchIds, <String>{'agent-1-1-1'});
      expect(chart.selectedStoreId, isNull);
    },
  );

  testWidgets('closes fullscreen after a data filter change', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) =>
              ChangeNotifierProvider<SalesLiveMapController>(
                create: (_) => SalesLiveMapController(
                  sessionService: SalesSessionService(_pumpSalesPreferences),
                  loadSalesAvailableAgentsUseCase:
                      LoadSalesAvailableAgentsUseCase(
                        _pumpLoadAvailableAgentsForSales,
                      ),
                  loadSalesLiveMapUseCase: _pumpLoadLiveMap,
                ),
                child: const Scaffold(body: SalesLiveMapPage()),
              ),
        ),
        ...buildAppChartFullscreenRoutes(),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      Provider<AuthController>.value(
        value: authController,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await _pumpInitialLoad(tester);

    final controller = tester
        .element(find.byType(SalesLiveMapPage).first)
        .read<SalesLiveMapController>();
    final fullscreenFinder = find.byIcon(Icons.open_in_full);
    await tester.ensureVisible(fullscreenFinder);
    await tester.pump();
    await tester.tap(fullscreenFinder);
    await tester.pumpAndSettle();
    expect(router.canPop(), isTrue);
    expect(router.state.matchedLocation, AppRoute.chartFullscreen.path);

    await controller.applyFilter(
      const SalesLiveMapFilter(
        periodMode: SalesLiveMapPeriodMode.lastSevenDays,
      ),
    );
    await tester.pumpAndSettle();

    expect(router.canPop(), isFalse);
  });
}

Future<void> _setDesktopSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required AuthController authController,
  Size? mediaSize,
}) async {
  await tester.pumpWidget(
    Provider<AuthController>.value(
      value: authController,
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(size: mediaSize ?? const Size(800, 600)),
          child: Scaffold(
            body: ChangeNotifierProvider<SalesLiveMapController>(
              create: (_) => SalesLiveMapController(
                sessionService: SalesSessionService(_pumpSalesPreferences),
                loadSalesAvailableAgentsUseCase:
                    LoadSalesAvailableAgentsUseCase(
                      _pumpLoadAvailableAgentsForSales,
                    ),
                loadSalesLiveMapUseCase: _pumpLoadLiveMap,
              ),
              child: const SalesLiveMapPage(),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<GoRouter> _pumpPageWithRouter(
  WidgetTester tester, {
  required AuthController authController,
  Size mediaSize = const Size(1400, 900),
}) async {
  final router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => MediaQuery(
          data: MediaQueryData(size: mediaSize),
          child: ChangeNotifierProvider<SalesLiveMapController>(
            create: (_) => SalesLiveMapController(
              sessionService: SalesSessionService(_pumpSalesPreferences),
              loadSalesAvailableAgentsUseCase: LoadSalesAvailableAgentsUseCase(
                _pumpLoadAvailableAgentsForSales,
              ),
              loadSalesLiveMapUseCase: _pumpLoadLiveMap,
            ),
            child: const Scaffold(body: SalesLiveMapPage()),
          ),
        ),
      ),
      ...buildAppChartFullscreenRoutes(),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    Provider<AuthController>.value(
      value: authController,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );

  return router;
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

SalesLiveMapLoadResult _twoBranchLoadedResult() {
  return SalesLiveMapLoadResult(
    points: const <SalesLiveMapPoint>[
      SalesLiveMapPoint(
        id: 'agent-1-1-1',
        name: 'Branch One',
        uf: 'MT',
        latitude: -15.60,
        longitude: -56.10,
        salesAmount: 1200,
        salesCount: 12,
        city: 'Cuiaba',
      ),
      SalesLiveMapPoint(
        id: 'agent-1-1-2',
        name: 'Branch Two',
        uf: 'MT',
        latitude: -15.61,
        longitude: -56.11,
        salesAmount: 800,
        salesCount: 8,
        city: 'Sinop',
      ),
    ],
    branchOptions: const <SalesLiveMapBranchOption>[
      SalesLiveMapBranchOption(
        id: 'agent-1-1-1',
        agentId: 'agent-1',
        agentName: 'Branch One',
        codEmpresa: 1,
        codFilial: 1,
        registrationName: 'Branch One',
        city: 'Cuiaba',
        uf: 'MT',
      ),
      SalesLiveMapBranchOption(
        id: 'agent-1-1-2',
        agentId: 'agent-1',
        agentName: 'Branch One',
        codEmpresa: 1,
        codFilial: 2,
        registrationName: 'Branch Two',
        city: 'Sinop',
        uf: 'MT',
      ),
    ],
    totalRevenue: 2000,
    totalSalesCount: 20,
    totalBranchCount: 2,
    mappedBranchCount: 2,
    mappedMunicipalityCount: 2,
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

SalesLiveMapLoadResult _loadedResult() {
  return SalesLiveMapLoadResult(
    points: const <SalesLiveMapPoint>[
      SalesLiveMapPoint(
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
        registrationName: 'Branch One',
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
    points: const <SalesLiveMapPoint>[
      SalesLiveMapPoint(
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
        registrationName: 'Branch One',
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
    points: const <SalesLiveMapPoint>[
      SalesLiveMapPoint(
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
        registrationName: 'Branch One',
        city: 'Cuiaba',
        uf: 'MT',
      ),
      SalesLiveMapBranchOption(
        id: 'agent-2-1-2',
        agentId: 'agent-2',
        agentName: 'Agent Two',
        codEmpresa: 1,
        codFilial: 2,
        registrationName: 'Branch Without Coordinates',
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
        registrationName: 'Branch Without Coordinates',
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
    points: const <SalesLiveMapPoint>[
      SalesLiveMapPoint(
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
        registrationName: 'Branch One',
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
    points: const <SalesLiveMapPoint>[
      SalesLiveMapPoint(
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
        registrationName: 'Branch One',
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
    points: const <SalesLiveMapPoint>[],
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

SalesLiveMapLoadResult _failedResult() {
  return SalesLiveMapLoadResult(
    points: const <SalesLiveMapPoint>[],
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
    loadFailed: true,
    refreshedAt: DateTime(2026, 5, 9, 12),
  );
}
