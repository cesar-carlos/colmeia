import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';
import 'package:colmeia/features/auth/domain/repositories/client_registration_repository.dart';

class ReadRegistrationStatusUseCase {
  ReadRegistrationStatusUseCase(this._clientRegistrationRepository);

  final ClientRegistrationRepository _clientRegistrationRepository;

  Future<AppResult<ClientRegistrationStatus>> call({
    required String token,
  }) {
    return _clientRegistrationRepository.readRegistrationStatus(token: token);
  }
}
