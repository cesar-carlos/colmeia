import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/auth/domain/repositories/auth_repository.dart';

class RequestPasswordRecoveryUseCase {
  RequestPasswordRecoveryUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<AppResult<String>> call({
    required String email,
  }) {
    return _authRepository.requestPasswordRecovery(email: email);
  }
}
