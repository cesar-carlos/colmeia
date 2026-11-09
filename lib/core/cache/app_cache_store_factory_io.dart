import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/cache/hive_app_cache_store.dart';
import 'package:colmeia/core/storage/app_hive.dart';

Future<AppCacheStore> createAppCacheStore() async {
  await AppHive.ensureInitialized();
  return HiveAppCacheStore(await AppHive.openHiveKvCacheBox());
}

Future<void> closeAppCacheStore(AppCacheStore store) async {
  if (store is HiveAppCacheStore) await store.close();
}

Future<void> clearAppCacheForRecovery() =>
    AppHive.clearLocalKvCacheForRecovery();
