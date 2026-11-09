import 'dart:async';

import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:idb_shim/idb.dart';

/// Reads committed values directly so separate browser tabs share invalidation.
class IndexedDbAppCacheStore implements AppCacheStore {
  IndexedDbAppCacheStore(IdbFactory factory)
    : _factoryProvider = (() => factory);

  IndexedDbAppCacheStore.lazy(this._factoryProvider);

  // Keep the existing Hive Web string-box layout; no data copy is needed.
  static const databaseName = 'app_kv_cache';
  static const objectStoreName = 'box';
  static const _openTimeout = Duration(seconds: 5);

  final IdbFactory Function() _factoryProvider;
  Database? _database;
  Future<Database>? _opening;
  StreamSubscription<VersionChangeEvent>? _versionChanges;
  bool _closed = false;

  Future<Database> _open() async {
    if (_closed) throw StateError('Cache connection is closed');
    final database = _database;
    if (database != null) return database;
    return _opening ??= _openDatabase();
  }

  Future<Database> _openDatabase() async {
    var abandoned = false;
    try {
      final pending = _factoryProvider()
          .open(
            databaseName,
            onUpgradeNeeded: (event) {
              event.database.createObjectStore(objectStoreName);
            },
          )
          .then((database) {
            if (abandoned || _closed) {
              database.close();
              throw StateError('Cache open completed after cancellation');
            }
            return database;
          });
      final database = await pending.timeout(_openTimeout);
      if (!database.objectStoreNames.contains(objectStoreName)) {
        database.close();
        throw StateError('Unsupported cache database schema');
      }
      _database = database;
      _versionChanges = database.onVersionChange.listen((_) {
        database.close();
        _database = null;
        unawaited(_versionChanges?.cancel());
        _versionChanges = null;
      });
      return database;
    } finally {
      abandoned = true;
      _opening = null;
    }
  }

  Future<T?> _run<T>(
    String operation,
    String mode,
    Future<T> Function(ObjectStore store) action,
  ) async {
    try {
      final database = await _open();
      final transaction = database.transaction(objectStoreName, mode);
      final results = await Future.wait<Object?>([
        Future<T>.sync(() => action(transaction.objectStore(objectStoreName))),
        transaction.completed,
      ]);
      return results.first as T?;
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Browser cache operation failed; remote data remains authoritative',
        context: {'operation': operation},
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<String?> getString(String key) => _run<String?>(
    'getString',
    idbModeReadOnly,
    (store) async {
      final value = await store.getObject(key);
      return value is String ? value : null;
    },
  );

  @override
  Future<void> putString({required String key, required String value}) async {
    await _run<Object>(
      'putString',
      idbModeReadWrite,
      (store) => store.put(value, key),
    );
  }

  @override
  Future<void> removeString(String key) async {
    await _run<void>(
      'removeString',
      idbModeReadWrite,
      (store) => store.delete(key),
    );
  }

  @override
  Future<void> removeKeysWithPrefix(String prefix) => removeKeysWhere(
    prefix: prefix,
    predicate: (_) => true,
  );

  KeyRange _prefixRange(String prefix) {
    final units = prefix.codeUnits.toList();
    while (units.isNotEmpty && units.last == 0xffff) {
      units.removeLast();
    }
    if (units.isEmpty) return KeyRange.lowerBound(prefix);
    units[units.length - 1]++;
    return KeyRange.bound(prefix, String.fromCharCodes(units), false, true);
  }

  @override
  Future<void> removeKeysWhere({
    required String prefix,
    required bool Function(String key) predicate,
  }) async {
    if (prefix.isEmpty) return;
    await _run<void>('removeKeysWhere', idbModeReadWrite, (store) async {
      final keys = (await store.getAllKeys(_prefixRange(prefix)))
          .whereType<String>()
          .where(
            (key) => key.startsWith(prefix) && predicate(key),
          )
          .toList(growable: false);
      await Future.wait(keys.map(store.delete));
    });
  }

  @override
  Future<void> clearAll() async {
    await _run<void>('clearAll', idbModeReadWrite, (store) => store.clear());
  }

  Future<void> close() async {
    _closed = true;
    _database?.close();
    _database = null;
    await _versionChanges?.cancel();
    _versionChanges = null;
  }
}
