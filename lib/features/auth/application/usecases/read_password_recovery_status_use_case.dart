import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/auth/domain/entities/client_password_recovery_status.dart';
import 'package:colmeia/features/auth/domain/repositories/auth_repository.dart';

class ReadPasswordRecoveryStatusUseCase {
  ReadPasswordRecoveryStatusUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<AppResult<ClientPasswordRecoveryStatus>> call({
    required String token,
  }) {
    return _authRepository.readPasswordRecoveryStatus(token: token);
  }
}
