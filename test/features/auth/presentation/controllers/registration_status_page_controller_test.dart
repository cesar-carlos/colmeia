import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/auth/application/usecases/read_registration_status_use_case.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_submission.dart';
import 'package:colmeia/features/auth/domain/repositories/auth_repository.dart';
import 'package:colmeia/features/auth/presentation/controllers/registration_status_page_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  group('RegistrationStatusPageController', () {
    test('should show validation message when token is empty', () async {
      final controller = RegistrationStatusPageController(
        readRegistrationStatusUseCase: ReadRegistrationStatusUseCase(
          _SuccessStatusRepository(),
        ),
      );

      await controller.loadStatus();

      check(
        controller.errorMessage,
      ).equals('Informe o token para consultar o cadastro.');
      check(controller.status).isNull();
    });

    test('should resolve status when use case succeeds', () async {
      final controller = RegistrationStatusPageController(
        readRegistrationStatusUseCase: ReadRegistrationStatusUseCase(
          _SuccessStatusRepository(),
        ),
        initialToken: 'token-123',
      );

      await controller.loadStatus();

      check(controller.status).equals(ClientRegistrationStatus.approved);
      check(controller.errorMessage).isNull();
    });
  });
}

final class _SuccessStatusRepository implements AuthRepository {
  @override
  Future<AppResult<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    return const Failure<AuthSession, AppFailure>(
      SessionFailure(message: 'unused', userMessage: 'unused'),
    );
  }

  @override
  Future<AppResult<ClientRegistrationStatus>> readRegistrationStatus({
    required String token,
  }) async {
    return const Success<ClientRegistrationStatus, AppFailure>(
      ClientRegistrationStatus.approved,
    );
  }

  @override
  Future<AppResult<ClientRegistrationSubmission>> register({
    required String ownerEmail,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? mobile,
  }) async {
    return const Failure<ClientRegistrationSubmission, AppFailure>(
      UnknownFailure(message: 'unused', userMessage: 'unused'),
    );
  }

  @override
  Future<AppResult<Unit>> logout() async =>
      const Success<Unit, AppFailure>(unit);

  @override
  Future<AppResult<AuthSession>> restoreSession() async {
    return const Failure<AuthSession, AppFailure>(
      SessionFailure(message: 'unused', userMessage: 'unused'),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
