import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/features/overview/presentation/pages/overview_chart_not_found_page.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('renders not found message and navigates back to overview', (
    tester,
  ) async {
    var navigatedToDashboard = false;

    final router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => const OverviewChartNotFoundPage(),
        ),
        GoRoute(
          name: AppRoute.dashboard.name,
          path: AppRoute.dashboard.path,
          builder: (context, state) {
            navigatedToDashboard = true;
            return const Scaffold(body: Text('Dashboard'));
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

    expect(find.text('Chart not found'), findsOneWidget);
    expect(
      find.text(
        'This chart is not available. Return to the overview to choose another.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Back to overview'));
    await tester.pumpAndSettle();

    expect(navigatedToDashboard, isTrue);
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
