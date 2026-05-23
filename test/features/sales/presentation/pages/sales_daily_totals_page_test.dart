import 'dart:async';

import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/core/refresh/auto_refresh_snapshot.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/overview/domain/entities/overview_daily_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/application/load_sales_available_agents_use_case.dart';
import 'package:colmeia/features/sales/application/load_sales_daily_totals_use_case.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_daily_totals_page.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_anchor_month_support.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAuthController extends Mock implements AuthController {}

class _MockSalesPreferences extends Mock implements SalesPreferences {}

class _MockAgentClientTokenReader extends Mock
    implements AgentClientTokenReader {}

class _MockLoadAvailableAgentsForSales extends Mock
    implements LoadAvailableAgentsForSales {}

class _MockLoadSalesDailyTotalsUseCase extends Mock
    implements LoadSalesDailyTotalsUseCase {}

void main() {
  late _MockAuthController authController;
  late _MockSalesPreferences salesPreferences;
  late _MockAgentClientTokenReader tokenReader;
  late _MockLoadAvailableAgentsForSales loadAvailableAgentsForSales;
  late _MockLoadSalesDailyTotalsUseCase loadDailyTotals;
  late OverviewYearMonth currentAnchor;

  setUpAll(() {
    Provider.debugCheckInvalidValueType = null;
    registerFallbackValue(
      const OverviewYearMonth(year: 2026, month: 5),
    );
    registerFallbackValue(<String>['agent-1']);
    registerFallbackValue(AutoRefreshSnapshot.disabled);
    registerFallbackValue(SalesAutoRefreshOptions.optionSet);
  });

  setUp(() async {
    authController = _MockAuthController();
    salesPreferences = _MockSalesPreferences();
    tokenReader = _MockAgentClientTokenReader();
    loadAvailableAgentsForSales = _MockLoadAvailableAgentsForSales();
    loadDailyTotals = _MockLoadSalesDailyTotalsUseCase();
    currentAnchor = salesMonthlyPnlAnchorMonthChoices().first;

    when(() => authController.session).thenReturn(
      AuthSession(
        userId: 'user-1',
        email: EmailAddress('user@example.com'),
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        expiresAt: DateTime(2099),
      ),
    );
    when(() => salesPreferences.selectedAgentId).thenReturn('agent-1');
    when(
      () => salesPreferences.restoreSalesChartReferenceMonth(),
    ).thenReturn(currentAnchor);
    when(() => salesPreferences.setSelectedAgentId(any())).thenAnswer(
      (_) async {},
    );
    when(
      () => salesPreferences.persistSalesChartReferenceMonth(any()),
    ).thenAnswer((_) async {});
    when(
      () => salesPreferences.restoreSalesDailyTotalsUseCustomRange(),
    ).thenReturn(false);
    when(
      () => salesPreferences.restoreSalesDailyTotalsDateRange(),
    ).thenReturn(null);
    when(
      () => salesPreferences.persistSalesDailyTotalsDateRange(
        useCustomRange: any(named: 'useCustomRange'),
        range: any(named: 'range'),
      ),
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
      () => tokenReader.readMany(
        userId: any(named: 'userId'),
        agentIds: any(named: 'agentIds'),
      ),
    ).thenAnswer((_) async => <String, String>{'agent-1': 'client-token'});
    when(
      () => loadAvailableAgentsForSales.call(any()),
    ).thenAnswer(
      (_) async => <OverviewAgentOption>[
        const OverviewAgentOption(
          agentId: 'agent-1',
          name: 'Agent One',
        ),
      ],
    );
    when(
      () => loadDailyTotals.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        anchor: any(named: 'anchor'),
        dailySaleDateRange: any(named: 'dailySaleDateRange'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer(
      (_) async => (
        points: const <OverviewDailySalesTrendPoint>[],
        loadFailed: false,
        loadFailureMessage: null,
      ),
    );
  });

  testWidgets('uses a chart skeleton while daily totals load', (tester) async {
    final completer = Completer<SalesDailyTotalsLoadResult>();
    when(
      () => loadDailyTotals.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        anchor: any(named: 'anchor'),
        dailySaleDateRange: any(named: 'dailySaleDateRange'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer((_) => completer.future);

    await _pumpPage(
      tester,
      authController: authController,
      salesPreferences: salesPreferences,
      tokenReader: tokenReader,
      loadAvailableAgentsForSales: loadAvailableAgentsForSales,
      loadDailyTotals: loadDailyTotals,
      mediaSize: const Size(1400, 900),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppSkeleton), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('chart-loading-placeholder-timeSeries'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('auto-refresh reloads daily totals after selected interval', (
    tester,
  ) async {
    await _setDesktopSurface(tester);
    await _pumpPage(
      tester,
      authController: authController,
      salesPreferences: salesPreferences,
      tokenReader: tokenReader,
      loadAvailableAgentsForSales: loadAvailableAgentsForSales,
      loadDailyTotals: loadDailyTotals,
      mediaSize: const Size(1400, 900),
    );
    await tester.pumpAndSettle();

    verify(
      () => loadDailyTotals.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        anchor: any(named: 'anchor'),
        dailySaleDateRange: any(named: 'dailySaleDateRange'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).called(1);

    await tester.tap(find.text('Off'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('sales-auto-refresh-fiveMinutes')),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 5));
    await tester.pumpAndSettle();

    verify(
      () => loadDailyTotals.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        anchor: any(named: 'anchor'),
        dailySaleDateRange: any(named: 'dailySaleDateRange'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).called(1);
  });

  testWidgets(
    'keeps the selected auto-refresh option when the selected agent lacks local token',
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
        () => loadAvailableAgentsForSales.call(any()),
      ).thenAnswer(
        (_) async => <OverviewAgentOption>[
          const OverviewAgentOption(
            agentId: 'agent-1',
            name: 'Agent One',
            missingLocalClientToken: true,
          ),
        ],
      );
      when(
        () => tokenReader.readMany(
          userId: any(named: 'userId'),
          agentIds: any(named: 'agentIds'),
        ),
      ).thenAnswer((_) async => <String, String>{});

      await _pumpPage(
        tester,
        authController: authController,
        salesPreferences: salesPreferences,
        tokenReader: tokenReader,
        loadAvailableAgentsForSales: loadAvailableAgentsForSales,
        loadDailyTotals: loadDailyTotals,
        mediaSize: const Size(1400, 900),
      );
      await tester.pumpAndSettle();

      expect(find.text('5 min'), findsOneWidget);
      expect(find.text('Off'), findsNothing);
      expect(
        find.text('Auto-refresh paused: local token required'),
        findsOneWidget,
      );
      verifyNever(
        () => loadDailyTotals.call(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          anchor: any(named: 'anchor'),
          dailySaleDateRange: any(named: 'dailySaleDateRange'),
          clientToken: any(named: 'clientToken'),
          cancelScope: any(named: 'cancelScope'),
        ),
      );
    },
  );
}

Future<void> _setDesktopSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required AuthController authController,
  required SalesPreferences salesPreferences,
  required AgentClientTokenReader tokenReader,
  required LoadAvailableAgentsForSales loadAvailableAgentsForSales,
  required LoadSalesDailyTotalsUseCase loadDailyTotals,
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
            body: SalesDailyTotalsPage(
              sessionService: SalesSessionService(salesPreferences),
              loadSalesAvailableAgentsUseCase: LoadSalesAvailableAgentsUseCase(
                loadAvailableAgentsForSales,
              ),
              loadSalesDailyTotalsUseCase: loadDailyTotals,
              resolveSalesAgentClientTokenUseCase:
                  ResolveSalesAgentClientTokenUseCase(tokenReader),
            ),
          ),
        ),
      ),
    ),
  );
}
