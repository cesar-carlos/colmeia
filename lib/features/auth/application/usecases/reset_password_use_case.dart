import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/auth/domain/repositories/auth_repository.dart';
import 'package:result_dart/result_dart.dart';

class ResetPasswordUseCase {
  ResetPasswordUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<AppResult<Unit>> call({
    required String token,
    required String newPassword,
  }) {
    return _authRepository.resetPassword(
      token: token,
      newPassword: newPassword,
    );
  }
}
