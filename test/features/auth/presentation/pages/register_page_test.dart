import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/auth/application/auth_registration_preferences_service.dart';
import 'package:colmeia/features/auth/application/usecases/register_use_case.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_submission.dart';
import 'package:colmeia/features/auth/domain/repositories/client_registration_repository.dart';
import 'package:colmeia/features/auth/presentation/controllers/register_page_controller.dart';
import 'package:colmeia/features/auth/presentation/pages/register_page.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:result_dart/result_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('should validate required owner e-mail', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final pageController = RegisterPageController(
      registerUseCase: RegisterUseCase(_RegisterTestRepository()),
      preferencesService: AuthRegistrationPreferencesService(prefs),
    );

    final router = GoRouter(
      initialLocation: AppRoute.register.path,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoute.register.path,
          name: AppRoute.register.name,
          builder: (context, state) {
            return RegisterPage(controller: pageController);
          },
        ),
        GoRoute(
          path: AppRoute.registrationStatus.path,
          name: AppRoute.registrationStatus.name,
          builder: (context, state) {
            return const Scaffold(
              body: Text('registration_status_route_marker'),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(Scaffold)),
    );

    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tester.enterText(find.byType(TextFormField).at(1), 'Maria');
    await tester.enterText(find.byType(TextFormField).at(2), 'Silva');
    await tester.enterText(
      find.byType(TextFormField).at(3),
      'maria@example.com',
    );
    await tester.enterText(
      find.byType(TextFormField).at(4),
      'maria+conta@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(4), '11999990000');
    await tester.enterText(find.byType(TextFormField).at(5), 'Password1');
    await tester.enterText(find.byType(TextFormField).at(6), 'Password1');

    final submit = find.text(l10n.authRegisterSubmitButton);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text(l10n.authRegisterOwnerEmailRequired), findsOneWidget);
  });

  testWidgets('should submit when form valid and go to status route', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final pageController = RegisterPageController(
      registerUseCase: RegisterUseCase(_RegisterSuccessRepository()),
      preferencesService: AuthRegistrationPreferencesService(prefs),
    );

    final router = GoRouter(
      initialLocation: AppRoute.register.path,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoute.register.path,
          name: AppRoute.register.name,
          builder: (context, state) {
            return RegisterPage(controller: pageController);
          },
        ),
        GoRoute(
          path: AppRoute.registrationStatus.path,
          name: AppRoute.registrationStatus.name,
          builder: (context, state) {
            return const Scaffold(
              body: Text('registration_status_route_marker'),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(Scaffold)),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'owner@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Maria');
    await tester.enterText(find.byType(TextFormField).at(2), 'Silva');
    await tester.enterText(
      find.byType(TextFormField).at(3),
      'maria2@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(4), '11999990000');
    await tester.enterText(find.byType(TextFormField).at(5), 'Password1');
    await tester.enterText(find.byType(TextFormField).at(6), 'Password1');

    final submit = find.text(l10n.authRegisterSubmitButton);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('registration_status_route_marker'), findsOneWidget);
  });
}

final class _RegisterTestRepository implements ClientRegistrationRepository {
  @override
  Future<AppResult<ClientRegistrationSubmission>> register({
    required String ownerEmail,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? mobile,
  }) async {
    return const Success<ClientRegistrationSubmission, AppFailure>(
      ClientRegistrationSubmission(
        status: ClientRegistrationStatus.pending,
        pollToken: 'abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqr',
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _RegisterSuccessRepository implements ClientRegistrationRepository {
  @override
  Future<AppResult<ClientRegistrationSubmission>> register({
    required String ownerEmail,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? mobile,
  }) async {
    return const Success<ClientRegistrationSubmission, AppFailure>(
      ClientRegistrationSubmission(
        status: ClientRegistrationStatus.pending,
        pollToken: 'abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqr',
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
