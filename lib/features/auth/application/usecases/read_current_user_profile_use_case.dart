import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/auth/domain/repositories/auth_repository.dart';
import 'package:colmeia/features/user_context/domain/entities/user_profile.dart';

class ReadCurrentUserProfileUseCase {
  ReadCurrentUserProfileUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<AppResult<UserProfile>> call() {
    return _authRepository.readCurrentUserProfile();
  }
}
