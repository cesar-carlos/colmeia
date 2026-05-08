import 'dart:async';

import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_use_case.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_daily_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_monthly_parcel_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_controller.dart';
import 'package:colmeia/features/overview/presentation/pages/overview_home_page.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_weekday_sales_trend_chart.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    registerFallbackValue(const OverviewFilter());
    registerFallbackValue(OverviewLoadLabels.englishFallback);
  });

  setUp(() {
    authController = _MockAuthController();
    overviewRepository = _MockOverviewRepository();
    clientAgentsRepository = _MockClientAgentsRepository();
    currentUserContextController = _MockCurrentUserContextController();
    overviewController = OverviewController(
      LoadOverviewUseCase(overviewRepository),
      clientAgentsRepository,
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
      ),
    ).thenAnswer((_) async => Success<Overview, AppFailure>(_overview()));
  });

  testWidgets('renders weekday card in the home page after monthly chart', (
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
    // [OverviewHomeStagedBelowKpis] mounts charts over successive post-frames.
    for (var i = 0; i < 24; i++) {
      await tester.pump();
    }
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(OverviewWeekdaySalesTrendChart), findsOneWidget);
    expect(find.text('Sales by weekday'), findsOneWidget);
    expect(find.text('Last 12 months'), findsOneWidget);

    final dailyTitleTopLeft = tester.getTopLeft(find.text('Daily sales'));
    final monthlyTitleTopLeft = tester.getTopLeft(find.text('Last 12 months'));
    final paymentMixTitleTopLeft = tester.getTopLeft(
      find.text('Mix by payment method').first,
    );
    expect(monthlyTitleTopLeft.dy, greaterThan(dailyTitleTopLeft.dy));
    expect(monthlyTitleTopLeft.dy, lessThan(paymentMixTitleTopLeft.dy));

    final weekdayTitleTopLeft = tester.getTopLeft(
      find.text('Sales by weekday'),
    );
    expect(weekdayTitleTopLeft.dy, greaterThan(monthlyTitleTopLeft.dy));

    final weekdayChart = tester.widget<OverviewWeekdaySalesTrendChart>(
      find.byType(OverviewWeekdaySalesTrendChart),
    );
    expect(weekdayChart.points, hasLength(7));
    expect(weekdayChart.points.first.weekdayNumber, 1);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('keeps weekday card in the skeleton path while loading', (
    tester,
  ) async {
    final completer = Completer<AppResult<Overview>>();
    when(
      () => overviewRepository.loadOverview(
        userId: any(named: 'userId'),
        policy: any(named: 'policy'),
        filter: any(named: 'filter'),
        rowLabels: any(named: 'rowLabels'),
      ),
    ).thenAnswer((_) => completer.future);

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
    expect(find.byType(OverviewWeekdaySalesTrendChart), findsOneWidget);
    final weekdayChart = tester.widget<OverviewWeekdaySalesTrendChart>(
      find.byType(OverviewWeekdaySalesTrendChart),
    );
    expect(weekdayChart.points, isEmpty);

    completer.complete(Success<Overview, AppFailure>(_overview()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    for (var i = 0; i < 24; i++) {
      await tester.pump();
    }

    expect(find.text('Sales by weekday'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });
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
    dailySalesTrend: <OverviewDailySalesTrendPoint>[
      OverviewDailySalesTrendPoint(
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
