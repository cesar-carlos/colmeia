import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/cache/indexed_db_app_cache_store.dart';
import 'package:idb_shim/idb_browser.dart' show idbFactoryWeb;

Future<AppCacheStore> createAppCacheStore() async =>
    IndexedDbAppCacheStore.lazy(() => idbFactoryWeb);

Future<void> closeAppCacheStore(AppCacheStore store) async {
  if (store is IndexedDbAppCacheStore) await store.close();
}

Future<void> clearAppCacheForRecovery() async {
  final store = IndexedDbAppCacheStore.lazy(() => idbFactoryWeb);
  try {
    await store.clearAll();
  } finally {
    await store.close();
  }
}
