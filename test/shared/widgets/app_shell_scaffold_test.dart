import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/shell/app_shell_scaffold.dart';
import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
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
      initialLocation: '/sales',
    );

    await tester.pumpWidget(_buildApp(router));
    await tester.pumpAndSettle();

    expect(find.text('sales-root-page'), findsOneWidget);

    final scaffoldFinder = find.byType(Scaffold).first;
    expect(tester.state<ScaffoldState>(scaffoldFinder).hasDrawer, isTrue);

    router.go('/sales/produto_rank_lucro');
    await tester.pumpAndSettle();

    expect(find.text('sales-card-page'), findsOneWidget);
    expect(tester.state<ScaffoldState>(scaffoldFinder).hasDrawer, isFalse);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('sales-root-page'), findsOneWidget);
    expect(find.text('sales-card-page'), findsNothing);

    expect(tester.state<ScaffoldState>(scaffoldFinder).hasDrawer, isTrue);
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
      initialLocation: '/settings',
    );

    await tester.pumpWidget(_buildApp(router));
    await tester.pumpAndSettle();

    expect(find.text('settings-root-page'), findsOneWidget);

    final scaffoldFinder = find.byType(Scaffold).first;
    expect(tester.state<ScaffoldState>(scaffoldFinder).hasDrawer, isTrue);

    router.go('/settings/component-demos/app-buttons-demo');
    await tester.pumpAndSettle();

    expect(find.text('settings-demo-page'), findsOneWidget);
    expect(tester.state<ScaffoldState>(scaffoldFinder).hasDrawer, isFalse);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('settings-root-page'), findsOneWidget);
    expect(find.text('settings-demo-page'), findsNothing);

    expect(tester.state<ScaffoldState>(scaffoldFinder).hasDrawer, isTrue);
  });

  testWidgets(
    'nested shell route disables scaffold drawer and shows back leading',
    (tester) async {
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

      final scaffoldFinder = find.byType(Scaffold).first;
      expect(tester.state<ScaffoldState>(scaffoldFinder).hasDrawer, isFalse);

      final appBarFinder = find.byType(AppBar);
      expect(
        find.descendant(
          of: appBarFinder,
          matching: find.byIcon(Icons.arrow_back),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: appBarFinder,
          matching: find.byIcon(Icons.menu_rounded),
        ),
        findsNothing,
      );

      expect(
        find.descendant(
          of: appBarFinder,
          matching: find.byIcon(Icons.arrow_back_ios_new),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('shell section root exposes scaffold drawer', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = _buildRouter(
      authController: authController,
      currentUserContextController: currentUserContextController,
      initialLocation: '/sales',
    );

    await tester.pumpWidget(_buildApp(router));
    await tester.pumpAndSettle();

    final scaffoldFinder = find.byType(Scaffold).first;
    expect(tester.state<ScaffoldState>(scaffoldFinder).hasDrawer, isTrue);
  });

  testWidgets('shell app bar uses iOS-style back chevron on iOS', (
    tester,
  ) async {
    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
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

      final appBarFinder = find.byType(AppBar);
      expect(
        find.descendant(
          of: appBarFinder,
          matching: find.byIcon(Icons.arrow_back_ios_new),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: appBarFinder,
          matching: find.byIcon(Icons.arrow_back),
        ),
        findsNothing,
      );
    } finally {
      debugDefaultTargetPlatformOverride = previousPlatform;
    }
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
            name: AppRoute.agents.name,
            path: AppRoute.agents.path,
            builder: (context, state) => const Text('agents-root-page'),
          ),
        ],
      ),
    ],
  );
}
