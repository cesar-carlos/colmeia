import 'package:colmeia/core/logging/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';

/// Hive initialization and shared box names for app storage.
abstract final class AppHive {
  static const String kvCacheBoxName = 'app_kv_cache';

  static bool _initialized = false;

  /// Call once before opening any Hive box.
  /// On web the filesystem path is unused.
  static Future<void> ensureInitialized() async {
    if (_initialized) {
      return;
    }
    if (kIsWeb) {
      Hive.init(null);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      Hive.init(directory.path);
    }
    _initialized = true;
  }

  /// Opens the shared KV cache box, deleting corrupted on-disk data once on
  /// failure before a single retry.
  static Future<Box<String>> openHiveKvCacheBox() async {
    try {
      return await Hive.openBox<String>(kvCacheBoxName);
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to open Hive KV cache box; deleting from disk and retrying once',
        context: const <String, Object?>{
          'component': 'AppHive',
          'boxName': kvCacheBoxName,
        },
        error: error,
        stackTrace: stackTrace,
      );
      try {
        await Hive.deleteBoxFromDisk(kvCacheBoxName);
      } on Object catch (deleteError, deleteStack) {
        AppLogger.warning(
          'Failed to delete corrupted Hive KV cache box from disk',
          context: const <String, Object?>{
            'component': 'AppHive',
            'boxName': kvCacheBoxName,
          },
          error: deleteError,
          stackTrace: deleteStack,
        );
      }
      return Hive.openBox<String>(kvCacheBoxName);
    }
  }

  /// Deletes the shared KV cache box so bootstrap can recreate it after a
  /// corruption or open failure. Safe during cold-start recovery.
  static Future<void> clearLocalKvCacheForRecovery() async {
    try {
      if (!_initialized) {
        await ensureInitialized();
      }
      if (Hive.isBoxOpen(kvCacheBoxName)) {
        await Hive.box<String>(kvCacheBoxName).close();
      }
      await Hive.deleteBoxFromDisk(kvCacheBoxName);
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to clear Hive KV cache box during bootstrap recovery',
        context: const <String, Object?>{
          'component': 'AppHive',
          'boxName': kvCacheBoxName,
        },
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
