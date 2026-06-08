import 'dart:async';

import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_use_case.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_monthly_parcel_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/entities/overview_section_request.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_controller.dart';
import 'package:colmeia/features/overview/presentation/pages/overview_home_page.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_chart_nav_grid.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_home_charts_below_kpis.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_monthly_parcels_combo_chart.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_weekday_sales_trend_chart.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_point.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:result_dart/result_dart.dart';

class _MockAuthController extends Mock implements AuthController {}

class _MockOverviewRepository extends Mock implements OverviewRepository {}

class _MockClientAgentsRepository extends Mock
    implements ClientAgentsRepository {}

class _MockCurrentUserContextController extends Mock
    implements CurrentUserContextController {}

void main() {
  late _MockAuthController authController;
  late _MockOverviewRepository overviewRepository;
  late _MockClientAgentsRepository clientAgentsRepository;
  late _MockCurrentUserContextController currentUserContextController;
  late OverviewController overviewController;

  setUpAll(() {
    Provider.debugCheckInvalidValueType = null;
    registerFallbackValue(OverviewLoadPolicy.defaultLoad);
    registerFallbackValue(const DashboardFilter());
    registerFallbackValue(OverviewLoadLabels.englishFallback);
    registerFallbackValue(OverviewSectionRequest.full);
  });

  setUp(() {
    authController = _MockAuthController();
    overviewRepository = _MockOverviewRepository();
    clientAgentsRepository = _MockClientAgentsRepository();
    currentUserContextController = _MockCurrentUserContextController();
    overviewController = OverviewController(
      LoadOverviewUseCase(overviewRepository),
    );

    when(() => authController.session).thenReturn(
      AuthSession(
        userId: 'user-1',
        email: EmailAddress('user@example.com'),
        accessToken: 'token',
        refreshToken: 'refresh',
        expiresAt: DateTime(2099),
      ),
    );
    when(
      () => clientAgentsRepository.loadOnlineAgentIds(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => null);
    when(() => currentUserContextController.isLoadingInitial).thenReturn(false);
    when(() => currentUserContextController.errorMessage).thenReturn(null);
    when(() => currentUserContextController.hasResolvedData).thenReturn(true);
    when(
      () => currentUserContextController.userScope,
    ).thenReturn(CurrentUserContextController.seeded().userScope);
    when(
      () => overviewRepository.loadOverview(
        userId: any(named: 'userId'),
        policy: any(named: 'policy'),
        filter: any(named: 'filter'),
        rowLabels: any(named: 'rowLabels'),
        cancelScope: any(named: 'cancelScope'),
        sectionRequest: any(named: 'sectionRequest'),
      ),
    ).thenAnswer((_) async => Success<Overview, AppFailure>(_overview()));
    when(
      () => overviewRepository.loadOverviewProgressively(
        userId: any(named: 'userId'),
        policy: any(named: 'policy'),
        filter: any(named: 'filter'),
        rowLabels: any(named: 'rowLabels'),
        cancelScope: any(named: 'cancelScope'),
        sectionRequest: any(named: 'sectionRequest'),
      ),
    ).thenAnswer(
      (_) => Stream<AppResult<OverviewProgressiveSnapshot>>.value(
        Success<OverviewProgressiveSnapshot, AppFailure>(
          _snapshot(_overview()),
        ),
      ),
    );
  });

  testWidgets('renders chart nav grid and embedded monthly chart on home', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthController>.value(value: authController),
          Provider<CurrentUserContextController>.value(
            value: currentUserContextController,
          ),
          ChangeNotifierProvider<OverviewController>.value(
            value: overviewController,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OverviewHomePage(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // [OverviewHomeChartsBelowKpis] mounts charts under skeletons that fade
    // in via [AppChartFadeIn]; a few extra frames let the post-skeleton
    // entrance settle before we assert against the final layout.
    for (var i = 0; i < 24; i++) {
      await tester.pump();
    }
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(OverviewChartNavGrid), findsOneWidget);
    expect(find.text('Daily sales'), findsOneWidget);
    expect(find.text('Mix by payment method'), findsOneWidget);
    expect(find.text('Last 12 months'), findsOneWidget);
    expect(find.byType(OverviewMonthlyParcelsComboChart), findsOneWidget);
    expect(find.byType(OverviewWeekdaySalesTrendChart), findsNothing);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets(
    'survives route provider teardown when RetryAfterGate is a shared singleton',
    (tester) async {
      final sharedGate = RetryAfterGate();
      addTearDown(sharedGate.dispose);

      Widget buildRoute() {
        return MultiProvider(
          providers: [
            Provider<AuthController>.value(value: authController),
            Provider<CurrentUserContextController>.value(
              value: currentUserContextController,
            ),
            ChangeNotifierProvider<OverviewController>(
              create: (_) => OverviewController(
                LoadOverviewUseCase(overviewRepository),
                retryAfterGate: sharedGate,
              ),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                context.read<OverviewController>();
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      }

      await tester.pumpWidget(buildRoute());
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(buildRoute());
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('waits for user context before loading overview', (
    tester,
  ) async {
    when(
      () => currentUserContextController.hasResolvedData,
    ).thenReturn(false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthController>.value(value: authController),
          Provider<CurrentUserContextController>.value(
            value: currentUserContextController,
          ),
          ChangeNotifierProvider<OverviewController>.value(
            value: overviewController,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OverviewHomePage(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    verifyNever(
      () => overviewRepository.loadOverviewProgressively(
        userId: any(named: 'userId'),
        policy: any(named: 'policy'),
        filter: any(named: 'filter'),
        rowLabels: any(named: 'rowLabels'),
        cancelScope: any(named: 'cancelScope'),
        sectionRequest: any(named: 'sectionRequest'),
      ),
    );
  });

  testWidgets('keeps monthly chart in the skeleton path while loading', (
    tester,
  ) async {
    final completer = Completer<AppResult<Overview>>();
    when(
      () => overviewRepository.loadOverviewProgressively(
        userId: any(named: 'userId'),
        policy: any(named: 'policy'),
        filter: any(named: 'filter'),
        rowLabels: any(named: 'rowLabels'),
        cancelScope: any(named: 'cancelScope'),
        sectionRequest: any(named: 'sectionRequest'),
      ),
    ).thenAnswer((_) async* {
      yield Success<OverviewProgressiveSnapshot, AppFailure>(
        _snapshot((await completer.future).getOrNull() ?? _overview()),
      );
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthController>.value(value: authController),
          Provider<CurrentUserContextController>.value(
            value: currentUserContextController,
          ),
          ChangeNotifierProvider<OverviewController>.value(
            value: overviewController,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OverviewHomePage(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.byType(AppSkeleton), findsWidgets);
    expect(find.byType(OverviewMonthlyParcelsComboChart), findsOneWidget);
    final monthlyChart = tester.widget<OverviewMonthlyParcelsComboChart>(
      find.byType(OverviewMonthlyParcelsComboChart),
    );
    expect(monthlyChart.points, isEmpty);

    completer.complete(Success<Overview, AppFailure>(_overview()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    for (var i = 0; i < 24; i++) {
      await tester.pump();
    }

    expect(find.text('Last 12 months'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets(
    'progressive below-kpis UI mounts only ready monthly parcels section',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return SingleChildScrollView(
                  child: OverviewHomeChartsBelowKpis(
                    tokens: Theme.of(context).extension<AppThemeTokens>()!,
                    l10n: AppLocalizations.of(context),
                    showSkeleton: false,
                    displayOverview: _overview(),
                    completedSections: const <OverviewProgressiveSection>{
                      OverviewProgressiveSection.monthlyParcels,
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(OverviewMonthlyParcelsComboChart), findsOneWidget);
      expect(find.text('Last 12 months'), findsOneWidget);
      expect(find.text('Ranking by branch'), findsNothing);

      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets('passes active dashboard filter as navigation extra', (
    tester,
  ) async {
    Object? capturedExtra;
    final activeFilter = DashboardFilter.initial().copyWith(
      selectedAgentIds: <String>{'agent-nav'},
    );
    unawaited(
      overviewController.applyFilter(
        userId: 'user-1',
        filter: activeFilter,
        failureMessageBuilder: (failure) => failure.message,
      ),
    );

    final router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => ChangeNotifierProvider<OverviewController>.value(
            value: overviewController,
            child: const Scaffold(body: OverviewChartNavGrid()),
          ),
        ),
        GoRoute(
          name: AppRoute.dashboardChart.name,
          path: AppRoute.dashboardChart.path,
          builder: (context, state) {
            capturedExtra = state.extra;
            return const SizedBox.shrink();
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Daily sales'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(capturedExtra, equals(activeFilter));
  });

  testWidgets('nav grid shows ready badge when section data is cached', (
    tester,
  ) async {
    when(
      () => overviewRepository.loadOverviewProgressively(
        userId: any(named: 'userId'),
        policy: any(named: 'policy'),
        filter: any(named: 'filter'),
        rowLabels: any(named: 'rowLabels'),
        cancelScope: any(named: 'cancelScope'),
        sectionRequest: any(named: 'sectionRequest'),
      ),
    ).thenAnswer(
      (_) => Stream<AppResult<OverviewProgressiveSnapshot>>.value(
        Success<OverviewProgressiveSnapshot, AppFailure>(
          _snapshot(_overview()),
        ),
      ),
    );
    unawaited(overviewController.loadOverview(userId: 'user-1'));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChangeNotifierProvider<OverviewController>.value(
          value: overviewController,
          child: const Scaffold(body: OverviewChartNavGrid()),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byIcon(Icons.check_circle_outline), findsNWidgets(6));
  });
}

OverviewProgressiveSnapshot _snapshot(Overview overview) {
  return OverviewProgressiveSnapshot(
    overview: overview,
    completedSections: Set<OverviewProgressiveSection>.of(
      OverviewProgressiveSection.values,
    ),
    pendingSections: const <OverviewProgressiveSection>{},
    isFinal: true,
  );
}

Overview _overview() {
  return Overview(
    periodStart: DateTime(2026, 3),
    periodEnd: DateTime(2026, 3, 31),
    kpis: const OverviewPaymentKpis(
      totalSalesCount: 42,
      totalAmount: 4200,
      averageTicket: 100,
      paymentMethodCount: 1,
    ),
    paymentMethods: const <OverviewPaymentMethodBreakdown>[
      OverviewPaymentMethodBreakdown(
        code: 'PIX',
        label: 'Pix',
        totalSalesCount: 42,
        totalAmount: 4200,
        averageTicket: 100,
        sharePercent: 100,
      ),
    ],
    agentRankings: const [],
    userRankings: const <OverviewUserRanking>[],
    monthlyParcelTrend: const <OverviewMonthlyParcelPoint>[
      OverviewMonthlyParcelPoint(
        anoMes: '2026/03',
        qtdVendas: 42,
        valorParcela: 4200,
      ),
    ],
    dailySalesTrend: <DailySalesTrendPoint>[
      DailySalesTrendPoint(
        saleDate: DateTime(2026, 3, 15),
        salesCount: 10,
        salesAmount: 1000,
      ),
    ],
    weekdaySalesTrend: const <OverviewWeekdaySalesTrendPoint>[
      OverviewWeekdaySalesTrendPoint(
        weekdayNumber: 1,
        salesCount: 4,
        salesAmount: 400,
      ),
      OverviewWeekdaySalesTrendPoint(
        weekdayNumber: 2,
        salesCount: 6,
        salesAmount: 600,
      ),
      OverviewWeekdaySalesTrendPoint(
        weekdayNumber: 3,
        salesCount: 8,
        salesAmount: 800,
      ),
      OverviewWeekdaySalesTrendPoint(
        weekdayNumber: 4,
        salesCount: 10,
        salesAmount: 1000,
      ),
      OverviewWeekdaySalesTrendPoint(
        weekdayNumber: 5,
        salesCount: 5,
        salesAmount: 500,
      ),
      OverviewWeekdaySalesTrendPoint(
        weekdayNumber: 6,
        salesCount: 7,
        salesAmount: 700,
      ),
      OverviewWeekdaySalesTrendPoint(
        weekdayNumber: 7,
        salesCount: 2,
        salesAmount: 200,
      ),
    ],
  );
}
