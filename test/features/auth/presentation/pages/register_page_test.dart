import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/auth/application/usecases/login_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/logout_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/register_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/restore_session_use_case.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/domain/repositories/auth_repository.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/auth/presentation/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  testWidgets('should show store selection error when no unit selected', (
    tester,
  ) async {
    final auth = AuthController(
      loginUseCase: LoginUseCase(_RegisterTestAuthRepository()),
      logoutUseCase: LogoutUseCase(_RegisterTestAuthRepository()),
      registerUseCase: RegisterUseCase(_RegisterTestAuthRepository()),
      restoreSessionUseCase: RestoreSessionUseCase(
        _RegisterTestAuthRepository(),
      ),
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
          path: AppRoute.login.path,
          name: AppRoute.login.name,
          builder: (context, state) {
            return const Scaffold(body: Text('login_route_marker'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Maria Silva');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'maria@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'AB-99');
    await tester.enterText(find.byType(TextFormField).at(3), '123456');
    await tester.enterText(find.byType(TextFormField).at(4), '123456');

    final submit = find.text('Solicitar acesso');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(
      find.text('Selecione pelo menos uma unidade.'),
      findsOneWidget,
    );
    auth.dispose();
  });

  testWidgets('should submit when form valid and one store selected', (
    tester,
  ) async {
    final auth = AuthController(
      loginUseCase: LoginUseCase(_RegisterSuccessAuthRepository()),
      logoutUseCase: LogoutUseCase(_RegisterSuccessAuthRepository()),
      registerUseCase: RegisterUseCase(_RegisterSuccessAuthRepository()),
      restoreSessionUseCase: RestoreSessionUseCase(
        _RegisterSuccessAuthRepository(),
      ),
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
          path: AppRoute.login.path,
          name: AppRoute.login.name,
          builder: (context, state) {
            return const Scaffold(body: Text('login_route_marker'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Maria Silva');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'maria2@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'AB-99');
    await tester.enterText(find.byType(TextFormField).at(3), '123456');
    await tester.enterText(find.byType(TextFormField).at(4), '123456');

    await tester.ensureVisible(find.text('Unidade Morumbi'));
    await tester.tap(find.text('Unidade Morumbi'));
    await tester.pumpAndSettle();

    final submit = find.text('Solicitar acesso');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.textContaining('Solicitação enviada'), findsOneWidget);
    expect(find.text('login_route_marker'), findsOneWidget);
    auth.dispose();
  });
}

final class _RegisterTestAuthRepository implements AuthRepository {
  @override
  Future<AppResult<Unit>> register({
    required String fullName,
    required String email,
    required String password,
    required String employeeId,
    required String accessProfileLabel,
    required List<String> requestedStoreIds,
  }) async {
    return const Success<Unit, AppFailure>(unit);
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
  Future<AppResult<AuthSession>> restoreSession() async {
    return const Failure<AuthSession, AppFailure>(
      SessionFailure(message: 'n', userMessage: 'n'),
    );
  }
}

final class _RegisterSuccessAuthRepository implements AuthRepository {
  @override
  Future<AppResult<Unit>> register({
    required String fullName,
    required String email,
    required String password,
    required String employeeId,
    required String accessProfileLabel,
    required List<String> requestedStoreIds,
  }) async {
    return const Success<Unit, AppFailure>(unit);
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
  Future<AppResult<AuthSession>> restoreSession() async {
    return const Failure<AuthSession, AppFailure>(
      SessionFailure(message: 'n', userMessage: 'n'),
    );
  }
}
