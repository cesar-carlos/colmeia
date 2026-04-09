import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/cache/app_kv_cache_key_prefixes.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/overview/data/models/overview_model.dart';

class OverviewLocalDataSource {
  OverviewLocalDataSource(this._cacheStore);

  final AppCacheStore _cacheStore;

  Future<OverviewModel?> readOverview({
    required String userId,
  }) async {
    final raw = await _cacheStore.getString(_cacheKey(userId));
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return OverviewModel.decode(raw);
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Overview cache decode failed; treating as cache miss',
        context: <String, Object?>{
          'operation': 'readOverviewCache',
          'userId': userId,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> saveOverview({
    required String userId,
    required OverviewModel overview,
  }) {
    return _cacheStore.putString(
      key: _cacheKey(userId),
      value: overview.encode(),
    );
  }

  String _cacheKey(String userId) {
    return '${AppKvCacheKeyPrefixes.dashboardOverview}${userId}_payments';
  }
}
