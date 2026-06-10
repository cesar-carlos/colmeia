import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_submission.dart';
import 'package:colmeia/features/auth/domain/repositories/client_registration_repository.dart';

class RegisterUseCase {
  RegisterUseCase(this._clientRegistrationRepository);

  final ClientRegistrationRepository _clientRegistrationRepository;

  Future<AppResult<ClientRegistrationSubmission>> call({
    required String ownerEmail,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? mobile,
  }) {
    return _clientRegistrationRepository.register(
      ownerEmail: ownerEmail,
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      mobile: mobile,
    );
  }
}
