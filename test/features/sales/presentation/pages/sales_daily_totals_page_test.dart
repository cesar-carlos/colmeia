import 'dart:async';

import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/application/load_sales_daily_totals_use_case.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
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
  });

  setUp(() async {
    await getIt.reset();

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

    getIt
      ..registerSingleton<SalesPreferences>(salesPreferences)
      ..registerSingleton<AgentClientTokenReader>(tokenReader)
      ..registerSingleton<LoadAvailableAgentsForSales>(
        loadAvailableAgentsForSales,
      )
      ..registerSingleton<LoadSalesDailyTotalsUseCase>(loadDailyTotals);
  });

  tearDown(() async {
    await getIt.reset();
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
      ),
    ).thenAnswer((_) => completer.future);

    await _pumpPage(tester, authController: authController);
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
          body: SalesDailyTotalsPage(),
        ),
      ),
    ),
  );
}
