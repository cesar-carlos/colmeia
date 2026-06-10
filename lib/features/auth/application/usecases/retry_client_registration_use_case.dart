import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/auth/domain/repositories/client_registration_repository.dart';

class RetryClientRegistrationUseCase {
  RetryClientRegistrationUseCase(this._clientRegistrationRepository);

  final ClientRegistrationRepository _clientRegistrationRepository;

  Future<AppResult<String>> call({
    required String ownerEmail,
    required String email,
    required String password,
  }) {
    return _clientRegistrationRepository.retryClientRegistration(
      ownerEmail: ownerEmail,
      email: email,
      password: password,
    );
  }
}
