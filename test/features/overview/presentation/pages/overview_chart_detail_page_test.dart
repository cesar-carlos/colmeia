import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/overview/application/overview_shell_cache.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_sections_use_case.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/entities/overview_section_request.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_chart_detail_controller.dart';
import 'package:colmeia/features/overview/presentation/pages/overview_chart_detail_page.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_chart_detail_loading_block.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:result_dart/result_dart.dart';

class _MockAuthController extends Mock implements AuthController {}

class _MockOverviewRepository extends Mock implements OverviewRepository {}

void main() {
  late _MockAuthController authController;
  late _MockOverviewRepository overviewRepository;

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
    when(() => authController.session).thenReturn(
      AuthSession(
        userId: 'user-1',
        email: EmailAddress('user@example.com'),
        accessToken: 'token',
        refreshToken: 'refresh',
        expiresAt: DateTime.utc(2030),
      ),
    );
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
      (_) => const Stream<AppResult<OverviewProgressiveSnapshot>>.empty(),
    );
  });

  testWidgets('shows structural skeleton while chart section is loading', (
    tester,
  ) async {
    final controller = OverviewChartDetailController(
      chartId: 'daily_sales',
      loadOverviewSectionsUseCase: LoadOverviewSectionsUseCase(
        overviewRepository,
      ),
      shellCache: OverviewShellCache(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthController>.value(value: authController),
          ChangeNotifierProvider<OverviewChartDetailController>.value(
            value: controller,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OverviewChartDetailPage(chartId: 'daily_sales'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.byType(OverviewChartDetailLoadingBlock), findsOneWidget);
    expect(find.byType(AppSkeleton), findsOneWidget);

    controller.dispose();
  });
}
