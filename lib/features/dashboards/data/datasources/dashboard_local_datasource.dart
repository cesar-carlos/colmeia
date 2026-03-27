import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/dashboards/data/models/dashboard_overview_model.dart';

class DashboardLocalDataSource {
  DashboardLocalDataSource(this._cacheStore);

  final AppCacheStore _cacheStore;

  Future<DashboardOverviewModel?> readOverview({
    required String userId,
    required StoreId storeId,
  }) async {
    final raw = await _cacheStore.getString(_cacheKey(userId, storeId));
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return DashboardOverviewModel.decode(raw);
  }

  Future<void> saveOverview({
    required String userId,
    required StoreId storeId,
    required DashboardOverviewModel overview,
  }) {
    return _cacheStore.putString(
      key: _cacheKey(userId, storeId),
      value: overview.encode(),
    );
  }

  String _cacheKey(String userId, StoreId storeId) {
    return 'dashboard_overview_${userId}_${storeId.value}';
  }
}
