import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/network/auth_session_events.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/application/auth_registration_preferences_service.dart';
import 'package:colmeia/features/auth/application/usecases/login_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/logout_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/restore_session_use_case.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/domain/repositories/auth_repository.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthController', () {
    late _MockAuthRepository repository;
    late AuthSessionEvents sessionEvents;
    late AuthController controller;
    var disposed = false;

    final session = AuthSession(
      userId: 'client-1',
      email: EmailAddress('client@corp.com'),
      accessToken: 'access-token-1',
      refreshToken: 'refresh-token-1',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );

    setUp(() async {
      disposed = false;
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = _MockAuthRepository();
      sessionEvents = AuthSessionEvents();
      final prefs = await SharedPreferences.getInstance();
      controller = AuthController(
        loginUseCase: LoginUseCase(repository),
        logoutUseCase: LogoutUseCase(repository),
        restoreSessionUseCase: RestoreSessionUseCase(repository),
        authSessionEvents: sessionEvents,
        registrationPreferencesService: AuthRegistrationPreferencesService(
          prefs,
        ),
      );
    });

    tearDown(() async {
      if (!disposed) controller.dispose();
      await sessionEvents.dispose();
    });

    test('should ignore restoration completed after disposal', () async {
      final pending = Completer<AppResult<AuthSession>>();
      when(repository.restoreSession).thenAnswer((_) => pending.future);
      final operation = controller.initialize();
      controller.dispose();
      disposed = true;
      pending.complete(Success(session));
      await operation;
      expect(controller.session, isNull);
    });

    test('should invalidate a pending restoration', () async {
      final pending = Completer<AppResult<AuthSession>>();
      when(repository.restoreSession).thenAnswer((_) => pending.future);
      final operation = controller.initialize();
      sessionEvents.notifyInvalidated();
      await Future<void>.delayed(Duration.zero);
      pending.complete(Success(session));
      await operation;
      expect(controller.session, isNull);
      expect(controller.isRestoringSession, isFalse);
    });

    test(
      'should wait for pending login before logout without publishing it',
      () async {
        final pending = Completer<AppResult<AuthSession>>();
        when(
          () => repository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) => pending.future);
        when(repository.logout).thenAnswer((_) async => const Success(unit));
        final login = controller.signIn(
          email: 'client@corp.com',
          password: 'password',
        );
        await Future<void>.delayed(Duration.zero);
        final logout = controller.signOut();
        verifyNever(repository.logout);
        pending.complete(Success(session));
        await Future.wait([login, logout]);
        verify(repository.logout).called(1);
        expect(controller.isAuthenticated, isFalse);
        expect(controller.isLoading, isFalse);
      },
    );

    test(
      'should block access immediately and coalesce pending logout',
      () async {
        when(repository.restoreSession)
            .thenAnswer((_) async => Success(session));
        final pending = Completer<AppResult<Unit>>();
        when(repository.logout).thenAnswer((_) => pending.future);
        await controller.initialize();
        final first = controller.signOut();
        final second = controller.signOut();
        expect(controller.session, isNull);
        expect(first, same(second));
        await controller.signIn(email: 'client@corp.com', password: 'password');
        verifyNever(
          () => repository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
        pending.complete(const Success(unit));
        await first;
        verify(repository.logout).called(1);
      },
    );

    test('should coalesce concurrent login attempts', () async {
      final pending = Completer<AppResult<AuthSession>>();
      when(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) => pending.future);
      final first = controller.signIn(
        email: 'client@corp.com',
        password: 'password',
      );
      final second = controller.signIn(
        email: 'client@corp.com',
        password: 'password',
      );
      expect(first, same(second));
      pending.complete(Success(session));
      await first;
      verify(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).called(1);
    });

    test('should allow login after restoration unexpectedly throws', () async {
      when(repository.restoreSession).thenThrow(StateError('storage failed'));
      when(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Success(session));
      await controller.initialize();
      expect(controller.isRestoringSession, isFalse);
      await controller.signIn(email: 'client@corp.com', password: 'password');
      expect(controller.isAuthenticated, isTrue);
    });

    test(
      'should clear in-memory session when invalidation event is emitted',
      () async {
        when(
          () => repository.restoreSession(),
        ).thenAnswer((_) async => Success<AuthSession, AppFailure>(session));

        await controller.initialize();
        expect(controller.session?.userId, equals(session.userId));

        sessionEvents.notifyInvalidated();
        await Future<void>.delayed(Duration.zero);

        expect(controller.session, isNull);
        expect(controller.isAuthenticated, isFalse);
        expect(
          controller.errorMessage,
          equals('Sua sessao expirou. Entre novamente.'),
        );
      },
    );

    test(
      'signOut clears session without keeping invalidation error message',
      () async {
        when(
          () => repository.restoreSession(),
        ).thenAnswer((_) async => Success<AuthSession, AppFailure>(session));
        when(() => repository.logout()).thenAnswer((_) async {
          sessionEvents.notifyInvalidated();
          return const Success<Unit, AppFailure>(unit);
        });

        await controller.initialize();
        expect(controller.isAuthenticated, isTrue);

        await controller.signOut();

        expect(controller.session, isNull);
        expect(controller.isAuthenticated, isFalse);
        expect(controller.errorMessage, isNull);
      },
    );
  });
}
