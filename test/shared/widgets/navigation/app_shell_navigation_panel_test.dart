import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_navigation_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAuthController extends Mock implements AuthController {}

void main() {
  late _MockAuthController authController;
  late CurrentUserContextController currentUserContextController;

  setUp(() {
    authController = _MockAuthController();
    currentUserContextController = CurrentUserContextController.seeded();

    when(() => authController.isLoading).thenReturn(false);
    when(() => authController.addListener(any())).thenReturn(null);
    when(() => authController.removeListener(any())).thenReturn(null);
  });

  tearDown(() {
    currentUserContextController.dispose();
  });

  testWidgets(
    'returns to the shell root when tapping the current section from a subroute',
    (tester) async {
      final router = _buildRouter(
        authController: authController,
        currentUserContextController: currentUserContextController,
        initialLocation: '/sales/produto_rank_lucro',
      );

      await tester.pumpWidget(_buildApp(router));
      await tester.pumpAndSettle();

      expect(find.text('sales-card-page'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('shell-nav-sales')));
      await tester.pumpAndSettle();

      expect(find.text('sales-root-page'), findsOneWidget);
      expect(find.text('sales-card-page'), findsNothing);
    },
  );

  testWidgets('does nothing when tapping the current section root', (
    tester,
  ) async {
    final router = _buildRouter(
      authController: authController,
      currentUserContextController: currentUserContextController,
      initialLocation: '/sales',
    );

    await tester.pumpWidget(_buildApp(router));
    await tester.pumpAndSettle();

    expect(find.text('sales-root-page'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('shell-nav-sales')));
    await tester.pumpAndSettle();

    expect(find.text('sales-root-page'), findsOneWidget);
  });

  testWidgets('navigates normally when tapping a different shell section', (
    tester,
  ) async {
    final router = _buildRouter(
      authController: authController,
      currentUserContextController: currentUserContextController,
      initialLocation: '/sales/produto_rank_lucro',
    );

    await tester.pumpWidget(_buildApp(router));
    await tester.pumpAndSettle();

    expect(find.text('sales-card-page'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('shell-nav-dashboard')));
    await tester.pumpAndSettle();

    expect(find.text('dashboard-root-page'), findsOneWidget);
    expect(find.text('sales-card-page'), findsNothing);
  });

  testWidgets('returns to settings root from a nested settings page', (
    tester,
  ) async {
    final router = _buildRouter(
      authController: authController,
      currentUserContextController: currentUserContextController,
      initialLocation: '/settings/component-demos/app-buttons-demo',
    );

    await tester.pumpWidget(_buildApp(router));
    await tester.pumpAndSettle();

    expect(find.text('settings-demo-page'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('shell-nav-settings')));
    await tester.pumpAndSettle();

    expect(find.text('settings-root-page'), findsOneWidget);
    expect(find.text('settings-demo-page'), findsNothing);
  });
}

MaterialApp _buildApp(GoRouter router) {
  return MaterialApp.router(
    theme: AppTheme.light(),
    locale: const Locale('pt', 'BR'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

GoRouter _buildRouter({
  required AuthController authController,
  required CurrentUserContextController currentUserContextController,
  required String initialLocation,
}) {
  const visibleShellRoutes = <AppRoute>[
    AppRoute.dashboard,
    AppRoute.sales,
    AppRoute.settings,
  ];

  return GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      ShellRoute(
        builder: (context, state, child) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthController>.value(
                value: authController,
              ),
              ChangeNotifierProvider<CurrentUserContextController>.value(
                value: currentUserContextController,
              ),
            ],
            child: Scaffold(
              body: Row(
                children: <Widget>[
                  SizedBox(
                    width: 320,
                    child: AppShellNavigationPanel(
                      currentLocation: state.uri.path,
                      currentRoute: AppRoute.fromLocation(
                        state.matchedLocation,
                      ),
                      visibleShellRoutes: visibleShellRoutes,
                      closeOverlayBeforeNavigate: false,
                    ),
                  ),
                  Expanded(
                    child: Center(child: child),
                  ),
                ],
              ),
            ),
          );
        },
        routes: <RouteBase>[
          GoRoute(
            name: AppRoute.dashboard.name,
            path: AppRoute.dashboard.path,
            builder: (context, state) => const Text('dashboard-root-page'),
          ),
          GoRoute(
            name: AppRoute.sales.name,
            path: AppRoute.sales.path,
            builder: (context, state) => const Text('sales-root-page'),
          ),
          GoRoute(
            name: AppRoute.salesCard.name,
            path: AppRoute.salesCard.path,
            builder: (context, state) => const Text('sales-card-page'),
          ),
          GoRoute(
            name: AppRoute.settings.name,
            path: AppRoute.settings.path,
            builder: (context, state) => const Text('settings-root-page'),
            routes: <RouteBase>[
              GoRoute(
                path: 'component-demos/app-buttons-demo',
                builder: (context, state) => const Text('settings-demo-page'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
