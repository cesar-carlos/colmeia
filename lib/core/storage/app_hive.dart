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
}
