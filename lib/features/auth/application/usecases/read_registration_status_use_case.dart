import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';
import 'package:colmeia/features/auth/domain/repositories/auth_repository.dart';

class ReadRegistrationStatusUseCase {
  ReadRegistrationStatusUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<AppResult<ClientRegistrationStatus>> call({
    required String token,
  }) {
    return _authRepository.readRegistrationStatus(token: token);
  }
}
