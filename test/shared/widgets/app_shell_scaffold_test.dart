import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/app_shell_scaffold.dart';
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

  testWidgets('drawer closes after returning to the current section root', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = _buildRouter(
      authController: authController,
      currentUserContextController: currentUserContextController,
      initialLocation: '/sales/produto_rank_lucro',
    );

    await tester.pumpWidget(_buildApp(router));
    await tester.pumpAndSettle();

    expect(find.text('sales-card-page'), findsOneWidget);

    final scaffoldFinder = find.byType(Scaffold).first;
    tester.state<ScaffoldState>(scaffoldFinder).openDrawer();
    await tester.pumpAndSettle();

    expect(tester.state<ScaffoldState>(scaffoldFinder).isDrawerOpen, isTrue);

    await tester.tap(find.byKey(const ValueKey<String>('shell-nav-sales')));
    await tester.pumpAndSettle();

    expect(find.text('sales-root-page'), findsOneWidget);
    expect(find.text('sales-card-page'), findsNothing);
    expect(tester.state<ScaffoldState>(scaffoldFinder).isDrawerOpen, isFalse);
  });

  testWidgets('drawer returns to settings root from nested settings content', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = _buildRouter(
      authController: authController,
      currentUserContextController: currentUserContextController,
      initialLocation: '/settings/component-demos/app-buttons-demo',
    );

    await tester.pumpWidget(_buildApp(router));
    await tester.pumpAndSettle();

    expect(find.text('settings-demo-page'), findsOneWidget);

    final scaffoldFinder = find.byType(Scaffold).first;
    tester.state<ScaffoldState>(scaffoldFinder).openDrawer();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('shell-nav-settings')));
    await tester.pumpAndSettle();

    expect(find.text('settings-root-page'), findsOneWidget);
    expect(find.text('settings-demo-page'), findsNothing);
    expect(tester.state<ScaffoldState>(scaffoldFinder).isDrawerOpen, isFalse);
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
            child: AppShellScaffold(
              currentLocation: state.uri.path,
              currentRoute: AppRoute.fromLocation(state.matchedLocation),
              child: child,
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
          GoRoute(
            name: AppRoute.inventory.name,
            path: AppRoute.inventory.path,
            builder: (context, state) => const Text('inventory-root-page'),
          ),
          GoRoute(
            name: AppRoute.agents.name,
            path: AppRoute.agents.path,
            builder: (context, state) => const Text('agents-root-page'),
          ),
        ],
      ),
    ],
  );
}
