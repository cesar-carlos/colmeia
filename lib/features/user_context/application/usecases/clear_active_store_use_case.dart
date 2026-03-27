import 'package:colmeia/features/user_context/domain/repositories/user_context_repository.dart';

class ClearActiveStoreUseCase {
  ClearActiveStoreUseCase(this._repository);

  final UserContextRepository _repository;

  Future<void> call({
    required String userId,
  }) {
    return _repository.clearPersistedActiveStoreId(userId: userId);
  }
}
