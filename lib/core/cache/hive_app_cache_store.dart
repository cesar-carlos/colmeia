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
  Future<void> removeString(String key) async {
    try {
      await _box.delete(key);
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Hive cache delete failed',
        context: <String, Object?>{
          'operation': 'removeString',
          'cacheKeyLength': key.length,
          'cacheKeyHash': key.hashCode,
        },
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> removeKeysWithPrefix(String prefix) async {
    if (prefix.isEmpty) {
      return;
    }
    try {
      final keys = _box.keys
          .whereType<String>()
          .where((key) => key.startsWith(prefix))
          .toList(growable: false);
      for (final key in keys) {
        await _box.delete(key);
      }
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Hive cache prefix delete failed',
        context: <String, Object?>{
          'operation': 'removeKeysWithPrefix',
          'prefixLength': prefix.length,
        },
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> removeKeysWhere({
    required String prefix,
    required bool Function(String key) predicate,
  }) async {
    if (prefix.isEmpty) {
      return;
    }
    try {
      final keys = _box.keys
          .whereType<String>()
          .where((key) => key.startsWith(prefix) && predicate(key))
          .toList(growable: false);
      for (final key in keys) {
        await _box.delete(key);
      }
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Hive cache predicate delete failed',
        context: <String, Object?>{
          'operation': 'removeKeysWhere',
          'prefixLength': prefix.length,
        },
        error: error,
        stackTrace: stackTrace,
      );
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
        context: <String, Object?>{
          'operation': 'putString',
          'severity': 'writeFailed',
          'cacheKeyLength': key.length,
          'cacheKeyHash': key.hashCode,
        },
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
