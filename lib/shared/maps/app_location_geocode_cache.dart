import 'dart:convert';

import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/cache/app_kv_cache_key_prefixes.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';
import 'package:crypto/crypto.dart';

class AppLocationGeocodeCache {
  const AppLocationGeocodeCache(this._store);

  static const int schemaVersion = 2;
  static const Duration defaultStreetAddressResolvedTtl = Duration(days: 90);
  static const Duration defaultCepResolvedTtl = Duration(days: 365);
  static const Duration defaultNotFoundTtl = Duration(days: 7);

  final AppCacheStore _store;

  Future<AppLocationCacheEntry?> readEntry(
    String cacheKey, {
    DateTime? now,
  }) async {
    final value = await _readStoredValue(cacheKey);
    if (value == null || value.isEmpty) {
      return null;
    }

    final json = jsonDecode(value);
    if (json is! Map<String, Object?>) {
      throw const FormatException('Cached location must be a JSON object.');
    }

    if (_isLegacyResolvedLocationPayload(json)) {
      final location = AppResolvedLocation.fromJson(json);
      return AppLocationCacheEntry(
        schemaVersion: 0,
        status: AppLocationCacheEntryStatus.resolved,
        cacheKey: location.cacheKey,
        providerId: 'legacy',
        createdAt:
            location.resolvedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        expiresAt: DateTime.utc(9999),
        location: location,
      );
    }

    final entry = AppLocationCacheEntry.fromJson(json);
    final currentTime = now;
    if (currentTime != null && entry.isExpired(currentTime)) {
      await remove(cacheKey);
      return null;
    }
    return entry;
  }

  Future<AppResolvedLocation?> read(
    String cacheKey, {
    DateTime? now,
  }) async {
    final entry = await readEntry(cacheKey, now: now);
    if (entry == null || !entry.isResolved) {
      return null;
    }
    return entry.location;
  }

  Future<void> write(AppResolvedLocation location) {
    final lookupType = _lookupTypeForCacheKey(location.cacheKey);
    if (lookupType == null) {
      throw ArgumentError.value(
        location.cacheKey,
        'location.cacheKey',
        'Cannot infer cache TTL policy from cache key.',
      );
    }

    return writeResolved(
      location,
      lookupType: lookupType,
      providerId: 'legacy',
      createdAt: location.resolvedAt ?? DateTime.now().toUtc(),
    );
  }

  Future<void> writeResolved(
    AppResolvedLocation location, {
    required AppLocationLookupType lookupType,
    required String providerId,
    required DateTime createdAt,
    Duration? ttl,
  }) {
    final createdAtUtc = createdAt.toUtc();
    return _writeEntry(
      AppLocationCacheEntry(
        schemaVersion: schemaVersion,
        status: AppLocationCacheEntryStatus.resolved,
        cacheKey: location.cacheKey,
        providerId: providerId,
        createdAt: createdAtUtc,
        expiresAt: createdAtUtc.add(
          ttl ?? _resolvedTtlForLookupType(lookupType),
        ),
        location: location,
      ),
    );
  }

  Future<void> writeNotFound({
    required String cacheKey,
    required AppLocationLookupType lookupType,
    required String providerId,
    required DateTime createdAt,
    Duration ttl = defaultNotFoundTtl,
  }) {
    final createdAtUtc = createdAt.toUtc();
    return _writeEntry(
      AppLocationCacheEntry(
        schemaVersion: schemaVersion,
        status: AppLocationCacheEntryStatus.notFound,
        cacheKey: cacheKey,
        providerId: providerId,
        createdAt: createdAtUtc,
        expiresAt: createdAtUtc.add(ttl),
      ),
    );
  }

  Future<void> remove(String cacheKey) async {
    final storageKey = _storageKeyFor(cacheKey);
    await _store.removeString(storageKey);
    if (storageKey != cacheKey) {
      await _store.removeString(cacheKey);
    }
    await _forgetIndexedStorageKey(storageKey);
  }

  Future<AppLocationCachePurgeSummary> purgeExpiredEntries({
    DateTime? now,
    int? maxEntries,
  }) async {
    final index = await _readIndex();
    if (index.isEmpty) {
      return const AppLocationCachePurgeSummary(
        scannedEntries: 0,
        removedExpiredEntries: 0,
        removedOrphanedIndexEntries: 0,
        remainingIndexedEntries: 0,
      );
    }

    final currentTime = (now ?? DateTime.now()).toUtc();
    final storageKeys = index.toList(growable: false)..sort();
    final limit = maxEntries != null && maxEntries >= 0
        ? maxEntries < storageKeys.length
              ? maxEntries
              : storageKeys.length
        : storageKeys.length;
    var scannedEntries = 0;
    var removedExpiredEntries = 0;
    var removedOrphanedIndexEntries = 0;
    final remainingKeys = Set<String>.from(index);

    for (final storageKey in storageKeys.take(limit)) {
      scannedEntries += 1;
      final value = await _store.getString(storageKey);
      if (value == null || value.isEmpty) {
        remainingKeys.remove(storageKey);
        removedOrphanedIndexEntries += 1;
        continue;
      }

      final decoded = jsonDecode(value);
      if (decoded is! Map<String, Object?>) {
        await _store.removeString(storageKey);
        remainingKeys.remove(storageKey);
        removedOrphanedIndexEntries += 1;
        continue;
      }

      if (_isLegacyResolvedLocationPayload(decoded)) {
        remainingKeys.remove(storageKey);
        removedOrphanedIndexEntries += 1;
        continue;
      }

      final entry = AppLocationCacheEntry.fromJson(decoded);
      if (entry.isExpired(currentTime)) {
        await _store.removeString(storageKey);
        remainingKeys.remove(storageKey);
        removedExpiredEntries += 1;
      }
    }

    await _writeIndex(remainingKeys);
    return AppLocationCachePurgeSummary(
      scannedEntries: scannedEntries,
      removedExpiredEntries: removedExpiredEntries,
      removedOrphanedIndexEntries: removedOrphanedIndexEntries,
      remainingIndexedEntries: remainingKeys.length,
    );
  }

  Future<void> _writeEntry(AppLocationCacheEntry entry) async {
    final storageKey = _storageKeyFor(entry.cacheKey);
    await _store.putString(
      key: storageKey,
      value: jsonEncode(entry.toJson()),
    );
    await _rememberIndexedStorageKey(storageKey);
  }

  Future<String?> _readStoredValue(String cacheKey) async {
    final storageKey = _storageKeyFor(cacheKey);
    final hashedValue = await _store.getString(storageKey);
    if (hashedValue != null && hashedValue.isNotEmpty) {
      return hashedValue;
    }

    if (storageKey == cacheKey) {
      return null;
    }
    return _store.getString(cacheKey);
  }

  Future<Set<String>> _readIndex() async {
    final value = await _store.getString(
      AppKvCacheKeyPrefixes.locationGeocodeIndex,
    );
    if (value == null || value.isEmpty) {
      return <String>{};
    }

    final decoded = jsonDecode(value);
    if (decoded is! List) {
      return <String>{};
    }

    return decoded
        .whereType<String>()
        .where((item) => item.trim().isNotEmpty)
        .toSet();
  }

  Future<void> _writeIndex(Set<String> keys) async {
    if (keys.isEmpty) {
      await _store.removeString(AppKvCacheKeyPrefixes.locationGeocodeIndex);
      return;
    }

    final orderedKeys = keys.toList(growable: false)..sort();
    await _store.putString(
      key: AppKvCacheKeyPrefixes.locationGeocodeIndex,
      value: jsonEncode(orderedKeys),
    );
  }

  Future<void> _rememberIndexedStorageKey(String storageKey) async {
    final keys = await _readIndex();
    if (keys.add(storageKey)) {
      await _writeIndex(keys);
    }
  }

  Future<void> _forgetIndexedStorageKey(String storageKey) async {
    final keys = await _readIndex();
    if (keys.remove(storageKey)) {
      await _writeIndex(keys);
    }
  }

  Duration _resolvedTtlForLookupType(AppLocationLookupType lookupType) {
    return switch (lookupType) {
      AppLocationLookupType.streetAddress => defaultStreetAddressResolvedTtl,
      AppLocationLookupType.cep => defaultCepResolvedTtl,
      AppLocationLookupType.geoPoint ||
      AppLocationLookupType.ibgeMunicipalityCode ||
      AppLocationLookupType.cityUf ||
      AppLocationLookupType.capitalUf ||
      AppLocationLookupType.uf => defaultStreetAddressResolvedTtl,
    };
  }

  AppLocationLookupType? _lookupTypeForCacheKey(String cacheKey) {
    if (cacheKey.startsWith('${AppKvCacheKeyPrefixes.locationGeocode}cep_')) {
      return AppLocationLookupType.cep;
    }
    if (cacheKey.startsWith(
      '${AppKvCacheKeyPrefixes.locationGeocode}street_address_',
    )) {
      return AppLocationLookupType.streetAddress;
    }
    return null;
  }

  String _storageKeyFor(String cacheKey) {
    final digest = sha256.convert(utf8.encode(cacheKey));
    return '${AppKvCacheKeyPrefixes.locationGeocodeEntry}$digest';
  }

  static bool _isLegacyResolvedLocationPayload(Map<String, Object?> json) {
    return json.containsKey('point') &&
        json.containsKey('precision') &&
        json.containsKey('source') &&
        json.containsKey('cacheKey') &&
        !json.containsKey('schemaVersion') &&
        !json.containsKey('status');
  }
}
