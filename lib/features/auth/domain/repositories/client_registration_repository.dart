import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_submission.dart';

abstract interface class ClientRegistrationRepository {
  Future<AppResult<ClientRegistrationSubmission>> register({
    required String ownerEmail,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? mobile,
  });

  Future<AppResult<ClientRegistrationStatus>> readRegistrationStatus({
    required String token,
  });

  Future<AppResult<String>> retryClientRegistration({
    required String ownerEmail,
    required String email,
    required String password,
  });
}
