import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/auth/domain/repositories/auth_repository.dart';
import 'package:colmeia/features/user_context/domain/entities/user_profile.dart';

class UpdateCurrentUserProfileUseCase {
  UpdateCurrentUserProfileUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<AppResult<UserProfile>> call({
    String? firstName,
    String? lastName,
    String? mobile,
    bool removeThumbnail = false,
  }) {
    return _authRepository.updateCurrentUserProfile(
      firstName: firstName,
      lastName: lastName,
      mobile: mobile,
      removeThumbnail: removeThumbnail,
    );
  }
}
