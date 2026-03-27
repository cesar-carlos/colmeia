import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:hive_ce/hive_ce.dart';

class HiveAppCacheStore implements AppCacheStore {
  HiveAppCacheStore(this._box);

  final Box<String> _box;

  @override
  Future<String?> getString(String key) async {
    try {
      return _box.get(key);
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Hive cache read failed',
        context: <String, Object?>{'operation': 'getString', 'key': key},
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<void> putString({
    required String key,
    required String value,
  }) async {
    try {
      await _box.put(key, value);
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Hive cache write failed',
        context: <String, Object?>{'operation': 'putString', 'key': key},
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await _box.clear();
      AppLogger.debug(
        'Hive app cache cleared',
        context: const <String, Object?>{'operation': 'clearAll'},
      );
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Hive cache clear failed',
        context: const <String, Object?>{'operation': 'clearAll'},
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
