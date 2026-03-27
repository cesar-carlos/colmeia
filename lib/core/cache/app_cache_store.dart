import 'package:colmeia/core/storage/app_database.dart';

class AppCacheStore {
  AppCacheStore(this._database);

  final AppDatabase _database;

  Future<String?> getString(String key) => _database.getCacheValue(key);

  Future<void> putString({
    required String key,
    required String value,
  }) {
    return _database.putCacheValue(key: key, value: value);
  }
}
