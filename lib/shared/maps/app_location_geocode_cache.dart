import 'dart:convert';

import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';

class AppLocationGeocodeCache {
  const AppLocationGeocodeCache(this._store);

  final AppCacheStore _store;

  Future<AppResolvedLocation?> read(String cacheKey) async {
    final value = await _store.getString(cacheKey);
    if (value == null || value.isEmpty) {
      return null;
    }

    final json = jsonDecode(value);
    if (json is! Map<String, Object?>) {
      throw const FormatException('Cached location must be a JSON object.');
    }

    return AppResolvedLocation.fromJson(json);
  }

  Future<void> write(AppResolvedLocation location) {
    return _store.putString(
      key: location.cacheKey,
      value: jsonEncode(location.toJson()),
    );
  }

  Future<void> remove(String cacheKey) {
    return _store.removeString(cacheKey);
  }
}
