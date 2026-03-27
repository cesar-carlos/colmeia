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
import 'package:colmeia/features/auth/presentation/pages/login_page.dart';
import 'package:colmeia/shared/widgets/feedback/inline_alert_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:result_dart/result_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  AuthController buildAuthController() {
    final repo = _FakeAuthRepository();
    return AuthController(
      loginUseCase: LoginUseCase(repo),
      logoutUseCase: LogoutUseCase(repo),
      registerUseCase: RegisterUseCase(repo),
      restoreSessionUseCase: RestoreSessionUseCase(repo),
    );
  }

  testWidgets('should show e-mail validation when submitting empty e-mail', (
    tester,
  ) async {
    final auth = buildAuthController();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: ChangeNotifierProvider<AuthController>.value(
          value: auth,
          child: const LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret');

    final submitButton = find.text('Entrar no Dashboard');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Informe o e-mail'), findsOneWidget);
    auth.dispose();
  });

  testWidgets('should toggle password visibility', (tester) async {
    final auth = buildAuthController();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: ChangeNotifierProvider<AuthController>.value(
          value: auth,
          child: const LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Mostrar senha'), findsOneWidget);

    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pump();

    expect(find.byTooltip('Ocultar senha'), findsOneWidget);
    auth.dispose();
  });

  testWidgets('should show inline alert when sign-in fails', (tester) async {
    final auth = AuthController(
      loginUseCase: LoginUseCase(_FakeAuthLoginFailureRepository()),
      logoutUseCase: LogoutUseCase(_FakeAuthRepository()),
      registerUseCase: RegisterUseCase(_FakeAuthRepository()),
      restoreSessionUseCase: RestoreSessionUseCase(_FakeAuthRepository()),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: ChangeNotifierProvider<AuthController>.value(
          value: auth,
          child: const LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'user@corp.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret');

    final submitButton = find.text('Entrar no Dashboard');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.byType(InlineAlertBanner), findsOneWidget);
    expect(find.text('Falha de login'), findsOneWidget);
    auth.dispose();
  });
}

final class _FakeAuthLoginFailureRepository implements AuthRepository {
  @override
  Future<AppResult<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    return const Failure<AuthSession, AppFailure>(
      UnknownFailure(
        message: 'login_failed',
        userMessage: 'Falha de login',
      ),
    );
  }

  @override
  Future<AppResult<Unit>> logout() async => const Success(unit);

  @override
  Future<AppResult<Unit>> register({
    required String fullName,
    required String email,
    required String storeName,
    required String password,
  }) async {
    return const Failure<Unit, AppFailure>(
      UnknownFailure(message: 'test', userMessage: 'test'),
    );
  }

  @override
  Future<AppResult<AuthSession>> restoreSession() async {
    return const Failure<AuthSession, AppFailure>(
      SessionFailure(message: 'none', userMessage: 'none'),
    );
  }
}

final class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AppResult<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    return const Failure<AuthSession, AppFailure>(
      UnknownFailure(message: 'test', userMessage: 'test'),
    );
  }

  @override
  Future<AppResult<Unit>> logout() async => const Success(unit);

  @override
  Future<AppResult<Unit>> register({
    required String fullName,
    required String email,
    required String storeName,
    required String password,
  }) async {
    return const Failure<Unit, AppFailure>(
      UnknownFailure(message: 'test', userMessage: 'test'),
    );
  }

  @override
  Future<AppResult<AuthSession>> restoreSession() async {
    return const Failure<AuthSession, AppFailure>(
      SessionFailure(message: 'none', userMessage: 'none'),
    );
  }
}
