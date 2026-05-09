import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/network/auth_session_events.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/application/usecases/login_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/logout_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/register_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/restore_session_use_case.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/domain/repositories/auth_repository.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthController', () {
    late _MockAuthRepository repository;
    late AuthSessionEvents sessionEvents;
    late AuthController controller;

    final session = AuthSession(
      userId: 'client-1',
      email: EmailAddress('client@corp.com'),
      accessToken: 'access-token-1',
      refreshToken: 'refresh-token-1',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );

    setUp(() {
      repository = _MockAuthRepository();
      sessionEvents = AuthSessionEvents();
      controller = AuthController(
        loginUseCase: LoginUseCase(repository),
        logoutUseCase: LogoutUseCase(repository),
        registerUseCase: RegisterUseCase(repository),
        restoreSessionUseCase: RestoreSessionUseCase(repository),
        authSessionEvents: sessionEvents,
      );
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
