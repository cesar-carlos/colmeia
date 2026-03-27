import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/user_context/domain/entities/user_context_snapshot.dart';
import 'package:colmeia/features/user_context/domain/repositories/user_context_repository.dart';

class LoadCurrentUserContextUseCase {
  LoadCurrentUserContextUseCase(this._repository);

  final UserContextRepository _repository;

  Future<AppResult<UserContextSnapshot>> call({
    required String userId,
  }) {
    return _repository.loadUserContext(userId: userId);
  }
}
