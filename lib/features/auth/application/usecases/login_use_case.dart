import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  LoginUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<AppResult<AuthSession>> call({
    required String email,
    required String password,
  }) {
    return _authRepository.login(
      email: email,
      password: password,
    );
  }
}
