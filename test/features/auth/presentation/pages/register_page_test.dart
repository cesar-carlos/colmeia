import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/network/auth_session_events.dart';
import 'package:colmeia/features/auth/application/usecases/login_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/logout_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/register_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/restore_session_use_case.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_submission.dart';
import 'package:colmeia/features/auth/domain/repositories/auth_repository.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/auth/presentation/pages/register_page.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  testWidgets('should validate required owner e-mail', (
    tester,
  ) async {
    final auth = AuthController(
      loginUseCase: LoginUseCase(_RegisterTestAuthRepository()),
      logoutUseCase: LogoutUseCase(_RegisterTestAuthRepository()),
      registerUseCase: RegisterUseCase(_RegisterTestAuthRepository()),
      restoreSessionUseCase: RestoreSessionUseCase(
        _RegisterTestAuthRepository(),
      ),
      authSessionEvents: AuthSessionEvents(),
    );

    final router = GoRouter(
      initialLocation: AppRoute.register.path,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoute.register.path,
          name: AppRoute.register.name,
          builder: (context, state) {
            return ChangeNotifierProvider<AuthController>.value(
              value: auth,
              child: const RegisterPage(),
            );
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
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'Silva',
    );
    await tester.enterText(
      find.byType(TextFormField).at(3),
      'maria@example.com',
    );
    await tester.enterText(
      find.byType(TextFormField).at(4),
      'maria+conta@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(5), '12345678');
    await tester.enterText(find.byType(TextFormField).at(6), '12345678');

    final submit = find.text(l10n.authRegisterSubmitButton);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text(l10n.authRegisterOwnerEmailRequired), findsOneWidget);
    auth.dispose();
  });

  testWidgets('should submit when form valid and go to status route', (
    tester,
  ) async {
    final auth = AuthController(
      loginUseCase: LoginUseCase(_RegisterSuccessAuthRepository()),
      logoutUseCase: LogoutUseCase(_RegisterSuccessAuthRepository()),
      registerUseCase: RegisterUseCase(_RegisterSuccessAuthRepository()),
      restoreSessionUseCase: RestoreSessionUseCase(
        _RegisterSuccessAuthRepository(),
      ),
      authSessionEvents: AuthSessionEvents(),
    );

    final router = GoRouter(
      initialLocation: AppRoute.register.path,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoute.register.path,
          name: AppRoute.register.name,
          builder: (context, state) {
            return ChangeNotifierProvider<AuthController>.value(
              value: auth,
              child: const RegisterPage(),
            );
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
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Maria',
    );
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'Silva',
    );
    await tester.enterText(
      find.byType(TextFormField).at(3),
      'maria2@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(4), '11999990000');
    await tester.enterText(find.byType(TextFormField).at(5), '12345678');
    await tester.enterText(find.byType(TextFormField).at(6), '12345678');

    final submit = find.text(l10n.authRegisterSubmitButton);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('registration_status_route_marker'), findsOneWidget);
    auth.dispose();
  });
}

final class _RegisterTestAuthRepository implements AuthRepository {
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
        approvalToken: 'pending-token',
      ),
    );
  }

  @override
  Future<AppResult<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    return const Failure<AuthSession, AppFailure>(
      UnknownFailure(message: 'n', userMessage: 'n'),
    );
  }

  @override
  Future<AppResult<Unit>> logout() async => const Success<Unit, AppFailure>(
    unit,
  );

  @override
  Future<AppResult<ClientRegistrationStatus>> readRegistrationStatus({
    required String token,
  }) async {
    return const Success<ClientRegistrationStatus, AppFailure>(
      ClientRegistrationStatus.pending,
    );
  }

  @override
  Future<AppResult<AuthSession>> restoreSession() async {
    return const Failure<AuthSession, AppFailure>(
      SessionFailure(message: 'n', userMessage: 'n'),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _RegisterSuccessAuthRepository implements AuthRepository {
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
        approvalToken: 'pending-token',
      ),
    );
  }

  @override
  Future<AppResult<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    return const Failure<AuthSession, AppFailure>(
      UnknownFailure(message: 'n', userMessage: 'n'),
    );
  }

  @override
  Future<AppResult<Unit>> logout() async => const Success<Unit, AppFailure>(
    unit,
  );

  @override
  Future<AppResult<ClientRegistrationStatus>> readRegistrationStatus({
    required String token,
  }) async {
    return const Success<ClientRegistrationStatus, AppFailure>(
      ClientRegistrationStatus.pending,
    );
  }

  @override
  Future<AppResult<AuthSession>> restoreSession() async {
    return const Failure<AuthSession, AppFailure>(
      SessionFailure(message: 'n', userMessage: 'n'),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
