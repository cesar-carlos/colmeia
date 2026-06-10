import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/auth/application/auth_registration_preferences_service.dart';
import 'package:colmeia/features/auth/application/usecases/read_registration_status_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/retry_client_registration_use_case.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';
import 'package:colmeia/features/auth/domain/repositories/client_registration_repository.dart';
import 'package:colmeia/features/auth/presentation/controllers/registration_status_page_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const emptyTokenMessage = 'Enter the token to check registration status.';
  const invalidTokenMessage = 'The tracking token format is invalid.';
  const validToken =
      'abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqr';

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('RegistrationStatusPageController', () {
    test('should show validation message when token is empty', () async {
      final controller = await _buildController(
        repository: _SuccessStatusRepository(),
      );

      await controller.loadStatus(
        emptyTokenMessage: emptyTokenMessage,
        invalidTokenMessage: invalidTokenMessage,
        mapFailure: (failure) => failure.displayMessage,
      );

      check(controller.errorMessage).equals(emptyTokenMessage);
      check(controller.status).isNull();
    });

    test('should resolve status when use case succeeds', () async {
      final controller = await _buildController(
        repository: _SuccessStatusRepository(),
        initialToken: validToken,
      );

      await controller.loadStatus(
        emptyTokenMessage: emptyTokenMessage,
        invalidTokenMessage: invalidTokenMessage,
        mapFailure: (failure) => failure.displayMessage,
      );

      check(controller.status).equals(ClientRegistrationStatus.approved);
      check(controller.errorMessage).isNull();
    });

    test('should keep previous status on retry success', () async {
      final controller = await _buildController(
        repository: _RetryStatusRepository(),
        initialToken: validToken,
      );

      await controller.loadStatus(
        emptyTokenMessage: emptyTokenMessage,
        invalidTokenMessage: invalidTokenMessage,
        mapFailure: (failure) => failure.displayMessage,
      );
      check(controller.status).equals(ClientRegistrationStatus.rejected);

      await controller.retryRegistration(
        ownerEmail: 'owner@example.com',
        email: 'client@example.com',
        password: 'Password1',
        genericSuccessMessage: 'Retry accepted',
        emptyTokenMessage: emptyTokenMessage,
        invalidTokenMessage: invalidTokenMessage,
        mapFailure: (failure) => failure.displayMessage,
      );

      check(controller.successMessage)
          .equals('If eligible, a new approval request will be sent.');
      check(controller.status).equals(ClientRegistrationStatus.rejected);
    });
  });
}

Future<RegistrationStatusPageController> _buildController({
  required ClientRegistrationRepository repository,
  String? initialToken,
}) async {
  final prefs = await SharedPreferences.getInstance();
  return RegistrationStatusPageController(
    readRegistrationStatusUseCase: ReadRegistrationStatusUseCase(repository),
    retryClientRegistrationUseCase:
        RetryClientRegistrationUseCase(repository),
    preferencesService: AuthRegistrationPreferencesService(prefs),
    initialToken: initialToken,
  );
}

final class _SuccessStatusRepository implements ClientRegistrationRepository {
  @override
  Future<AppResult<ClientRegistrationStatus>> readRegistrationStatus({
    required String token,
  }) async {
    return const Success<ClientRegistrationStatus, AppFailure>(
      ClientRegistrationStatus.approved,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _RetryStatusRepository implements ClientRegistrationRepository {
  @override
  Future<AppResult<ClientRegistrationStatus>> readRegistrationStatus({
    required String token,
  }) async {
    return const Success<ClientRegistrationStatus, AppFailure>(
      ClientRegistrationStatus.rejected,
    );
  }

  @override
  Future<AppResult<String>> retryClientRegistration({
    required String ownerEmail,
    required String email,
    required String password,
  }) async {
    return const Success<String, AppFailure>(
      'If eligible, a new approval request will be sent.',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
