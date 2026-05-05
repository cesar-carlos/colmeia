import 'dart:async';

import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/application/load_sales_monthly_pnl_lines_use_case.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_monthly_pnl_page.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/charts/chart_horizontal_scroll_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class _MockAuthController extends Mock implements AuthController {}

class _MockSalesPreferences extends Mock implements SalesPreferences {}

class _MockAgentClientTokenReader extends Mock
    implements AgentClientTokenReader {}

class _MockLoadAvailableAgentsForSales extends Mock
    implements LoadAvailableAgentsForSales {}

class _MockLoadSalesMonthlyPnlLinesUseCase extends Mock
    implements LoadSalesMonthlyPnlLinesUseCase {}

void main() {
  late _MockAuthController authController;
  late _MockSalesPreferences salesPreferences;
  late _MockAgentClientTokenReader tokenReader;
  late _MockLoadAvailableAgentsForSales loadAvailableAgentsForSales;
  late _MockLoadSalesMonthlyPnlLinesUseCase loadMonthlyPnlLines;
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
    loadMonthlyPnlLines = _MockLoadSalesMonthlyPnlLinesUseCase();
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
      () => salesPreferences.restoreMonthlyPnlAnchor(),
    ).thenReturn(currentAnchor);
    when(() => salesPreferences.setSelectedAgentId(any())).thenAnswer(
      (_) async {},
    );
    when(
      () => salesPreferences.persistMonthlyPnlAnchor(any()),
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
      ..registerSingleton<LoadSalesMonthlyPnlLinesUseCase>(loadMonthlyPnlLines);
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('uses a time-series skeleton while the monthly chart loads', (
    tester,
  ) async {
    final completer = Completer<SalesMonthlyPnlLinesLoadResult>();
    when(
      () => loadMonthlyPnlLines.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        anchor: any(named: 'anchor'),
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

  testWidgets('announces the horizontal scroll hint on the chart shell', (
    tester,
  ) async {
    when(
      () => loadMonthlyPnlLines.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        anchor: any(named: 'anchor'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer((_) async => _bundleWithBaseValue(120));

    await _pumpPage(tester, authController: authController);
    await tester.pumpAndSettle();

    final shell = tester.widget<ChartHorizontalScrollShell>(
      find.byType(ChartHorizontalScrollShell),
    );
    expect(
      shell.semanticsHint,
      'Swipe horizontally to see all items.',
    );
  });

  testWidgets('ignores stale reload results when a newer filter request wins', (
    tester,
  ) async {
    final anchors = salesMonthlyPnlAnchorMonthChoices();
    final secondAnchor = anchors[1];
    final thirdAnchor = anchors[2];
    final secondCompleter = Completer<SalesMonthlyPnlLinesLoadResult>();
    final thirdCompleter = Completer<SalesMonthlyPnlLinesLoadResult>();

    when(
      () => loadMonthlyPnlLines.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        anchor: any(named: 'anchor'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer((invocation) {
      final anchor =
          invocation.namedArguments[#anchor] as OverviewYearMonth;
      if (anchor == currentAnchor) {
        return Future<SalesMonthlyPnlLinesLoadResult>.value(
          _bundleWithBaseValue(100),
        );
      }
      if (anchor == secondAnchor) {
        return secondCompleter.future;
      }
      if (anchor == thirdAnchor) {
        return thirdCompleter.future;
      }
      throw StateError('Unexpected anchor: $anchor');
    });

    await _pumpPage(tester, authController: authController);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agent One'));
    await tester.pumpAndSettle();

    final dynamic sheet = tester.widget(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_SalesMonthlyPnlFiltersSheet',
      ),
    );
    // The filter sheet widget is private, so the test reads its public callback
    // through `dynamic` after confirming the modal is present.
    // ignore: avoid_dynamic_calls
    final onApply = sheet.onApply as ValueChanged<Map<String, Object?>>;

    onApply(<String, Object?>{
      'agentId': 'agent-1',
      'anchorYearMonth': secondAnchor,
    });
    await tester.pump();

    onApply(<String, Object?>{
      'agentId': 'agent-1',
      'anchorYearMonth': thirdAnchor,
    });
    await tester.pump();

    thirdCompleter.complete(_bundleWithBaseValue(900));
    await tester.pumpAndSettle();

    _expectSalesSeriesBaseValue(tester, 900);

    secondCompleter.complete(_bundleWithBaseValue(250));
    await tester.pumpAndSettle();

    _expectSalesSeriesBaseValue(tester, 900);
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
          body: SalesMonthlyPnlPage(),
        ),
      ),
    ),
  );
}

SalesMonthlyPnlLinesLoadResult _bundleWithBaseValue(double baseValue) => (
  points: List<SalesMonthlyPnlPoint>.generate(12, (index) {
    final date = DateTime(2025, index + 1);
    return SalesMonthlyPnlPoint(
      year: date.year,
      month: date.month,
      anoMes:
          '${date.year.toString().padLeft(4, '0')}/'
          '${date.month.toString().padLeft(2, '0')}',
      venda: baseValue + index,
      lucro: (baseValue / 2) + index,
      custoMercadoria: (baseValue / 3) + index,
    );
  }),
  loadFailed: false,
  loadFailureMessage: null,
);

void _expectSalesSeriesBaseValue(WidgetTester tester, double expectedValue) {
  final chart = tester.widget<SfCartesianChart>(find.byType(SfCartesianChart));
  final salesSeries =
      chart.series.first as LineSeries<SalesMonthlyPnlPoint, String>;
  final dataSource = salesSeries.dataSource!;
  expect(dataSource.first.venda, expectedValue);
}
