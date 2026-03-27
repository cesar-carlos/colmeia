import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/user_context/domain/entities/user_context_snapshot.dart';

abstract interface class UserContextRepository {
  Future<AppResult<UserContextSnapshot>> loadUserContext({
    required String userId,
  });

  Future<void> persistActiveStoreId({
    required String userId,
    required String storeId,
  });

  Future<void> clearPersistedActiveStoreId({
    required String userId,
  });
}
