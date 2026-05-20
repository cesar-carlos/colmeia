import 'dart:convert';

import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/cache/app_kv_cache_key_prefixes.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/overview/data/models/overview_model.dart';

class OverviewLocalDataSource {
  OverviewLocalDataSource(
    this._cacheStore, {
    required Duration maxCacheAge,
  }) : _maxCacheAge = maxCacheAge;

  final AppCacheStore _cacheStore;
  final Duration _maxCacheAge;

  Future<OverviewModel?> readOverview({
    required String userId,
  }) async {
    final raw = await _cacheStore.getString(_cacheKey(userId));
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic> && decoded['v'] == 2) {
        final savedAt = DateTime.tryParse(
          decoded['savedAt'] as String? ?? '',
        );
        if (savedAt != null &&
            DateTime.now().difference(savedAt) > _maxCacheAge) {
          return null;
        }
        final payload = decoded['payload'];
        if (payload is! String || payload.isEmpty) {
          return null;
        }
        return OverviewModel.decode(payload);
      }
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
    final envelope = <String, Object?>{
      'v': 2,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'payload': overview.encode(),
    };
    return _cacheStore.putString(
      key: _cacheKey(userId),
      value: jsonEncode(envelope),
    );
  }

  String _cacheKey(String userId) {
    return '${AppKvCacheKeyPrefixes.dashboardOverview}${userId}_payments';
  }
}
