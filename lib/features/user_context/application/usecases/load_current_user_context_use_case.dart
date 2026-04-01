import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/user_context/domain/entities/current_user_context.dart';
import 'package:colmeia/features/user_context/domain/repositories/user_context_repository.dart';

class LoadCurrentUserContextUseCase {
  LoadCurrentUserContextUseCase(this._repository);

  final UserContextRepository _repository;

  Future<AppResult<CurrentUserContext>> call({
    required String userId,
  }) {
    return _repository.loadUserContext(userId: userId);
  }
}
