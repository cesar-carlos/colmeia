import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/auth/application/usecases/read_password_recovery_status_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/reset_password_use_case.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/domain/entities/client_password_recovery_status.dart';
import 'package:colmeia/features/auth/domain/repositories/auth_repository.dart';
import 'package:colmeia/features/auth/presentation/controllers/password_recovery_reset_page_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  group('PasswordRecoveryResetPageController', () {
    test('should resolve pending status for valid token', () async {
      final repo = _PasswordRecoveryResetRepository();
      final controller = PasswordRecoveryResetPageController(
        readPasswordRecoveryStatusUseCase: ReadPasswordRecoveryStatusUseCase(
          repo,
        ),
        resetPasswordUseCase: ResetPasswordUseCase(repo),
        initialToken: 'valid-token',
      );

      await controller.loadStatus();

      check(controller.status).equals(ClientPasswordRecoveryStatus.pending);
      check(controller.errorMessage).isNull();
    });

    test('should expose success message when reset succeeds', () async {
      final repo = _PasswordRecoveryResetRepository();
      final controller = PasswordRecoveryResetPageController(
        readPasswordRecoveryStatusUseCase: ReadPasswordRecoveryStatusUseCase(
          repo,
        ),
        resetPasswordUseCase: ResetPasswordUseCase(repo),
        initialToken: 'valid-token',
      );

      await controller.loadStatus();
      await controller.resetPassword(newPassword: '12345678');

      check(controller.successMessage).equals(
        'Senha redefinida com sucesso. Voce ja pode entrar na conta.',
      );
      check(controller.errorMessage).isNull();
      check(controller.status).isNull();
    });
  });
}

final class _PasswordRecoveryResetRepository implements AuthRepository {
  @override
  Future<AppResult<ClientPasswordRecoveryStatus>> readPasswordRecoveryStatus({
    required String token,
  }) async {
    return const Success<ClientPasswordRecoveryStatus, AppFailure>(
      ClientPasswordRecoveryStatus.pending,
    );
  }

  @override
  Future<AppResult<Unit>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return const Success<Unit, AppFailure>(unit);
  }

  @override
  Future<AppResult<AuthSession>> restoreSession() async {
    return const Failure<AuthSession, AppFailure>(
      SessionFailure(message: 'unused', userMessage: 'unused'),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
