import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:hive_ce/hive_ce.dart';

class HiveAppCacheStore implements AppCacheStore {
  HiveAppCacheStore(this._box);

  final Box<String> _box;

  @override
  Future<String?> getString(String key) async {
    return _box.get(key);
  }

  @override
  Future<void> putString({
    required String key,
    required String value,
  }) async {
    await _box.put(key, value);
  }
}
