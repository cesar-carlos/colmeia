import 'package:colmeia/core/storage/session_storage.dart';

class UserContextLocalDataSource {
  UserContextLocalDataSource(this._sessionStorage);

  final SessionStorage _sessionStorage;

  Future<String?> readActiveStoreId(String userId) {
    return _sessionStorage.read(_keyFor(userId));
  }

  Future<void> saveActiveStoreId({
    required String userId,
    required String storeId,
  }) {
    return _sessionStorage.write(key: _keyFor(userId), value: storeId);
  }

  Future<void> clearActiveStoreId(String userId) {
    return _sessionStorage.delete(_keyFor(userId));
  }

  String _keyFor(String userId) => 'user_context_active_store_$userId';
}
