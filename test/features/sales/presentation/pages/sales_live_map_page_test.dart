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
      () => loadLiveMap.call(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
      ),
    ).thenAnswer((_) async => _loadedResult());

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
        () => loadLiveMap.call(
          userId: 'user-1',
          filter: any(named: 'filter'),
        ),
      ).called(1);
      expect(find.text('Total revenue'), findsOneWidget);

      await tester.pump(const Duration(minutes: 5));
      await tester.pump();

      verifyNever(
        () => loadLiveMap.call(
          userId: 'user-1',
          filter: any(named: 'filter'),
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
      () => loadLiveMap.call(
        userId: 'user-1',
        filter: any(named: 'filter'),
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
      () => loadLiveMap.call(
        userId: 'user-1',
        filter: any(named: 'filter'),
      ),
    ).called(1);
  });

  testWidgets('ignores auto-refresh tick while reload is still running', (
    tester,
  ) async {
    final completer = Completer<SalesLiveMapLoadResult>();
    when(
      () => loadLiveMap.call(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
      ),
    ).thenAnswer((_) => completer.future);

    await _pumpPage(tester, authController: authController);
    await tester.pump();
    await tester.pump();
    verify(
      () => loadLiveMap.call(
        userId: 'user-1',
        filter: any(named: 'filter'),
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
      () => loadLiveMap.call(
        userId: 'user-1',
        filter: any(named: 'filter'),
      ),
    );

    completer.complete(_loadedResult());
    await tester.pump();
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
    totalRevenue: 1200,
    totalSalesCount: 12,
    totalBranchCount: 1,
    mappedBranchCount: 1,
    queriedAgentCount: 1,
    plannedAgentCount: 1,
    failedAgentCount: 0,
    missingClientTokenAgentCount: 0,
    skippedOfflineAgentCount: 0,
    refreshedAt: DateTime(2026, 5, 9, 12),
  );
}
