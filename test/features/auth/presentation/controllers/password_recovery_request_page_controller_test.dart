import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/auth/application/usecases/request_password_recovery_use_case.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/domain/repositories/auth_repository.dart';
import 'package:colmeia/features/auth/presentation/controllers/password_recovery_request_page_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  group('PasswordRecoveryRequestPageController', () {
    test('should expose success message when request succeeds', () async {
      final controller = PasswordRecoveryRequestPageController(
        requestPasswordRecoveryUseCase: RequestPasswordRecoveryUseCase(
          _PasswordRecoveryRequestSuccessRepository(),
        ),
      );

      await controller.submit(email: 'client@example.com');

      check(controller.successMessage).equals(
        'If the account exists, a password recovery email will be sent '
        'shortly.',
      );
      check(controller.errorMessage).isNull();
      check(controller.isLoading).isFalse();
    });
  });
}

final class _PasswordRecoveryRequestSuccessRepository
    implements AuthRepository {
  @override
  Future<AppResult<String>> requestPasswordRecovery({
    required String email,
  }) async {
    return const Success<String, AppFailure>(
      'If the account exists, a password recovery email will be sent shortly.',
    );
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
