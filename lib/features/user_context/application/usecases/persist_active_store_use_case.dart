import 'package:colmeia/features/user_context/domain/repositories/user_context_repository.dart';

class PersistActiveStoreUseCase {
  PersistActiveStoreUseCase(this._repository);

  final UserContextRepository _repository;

  Future<void> call({
    required String userId,
    required String storeId,
  }) {
    return _repository.persistActiveStoreId(userId: userId, storeId: storeId);
  }
}
