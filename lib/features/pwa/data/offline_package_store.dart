import 'dart:convert';

import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/features/pwa/domain/offline_package.dart';
import 'package:colmeia/features/pwa/domain/offline_package_exception.dart';
import 'package:colmeia/features/pwa/domain/offline_package_repository.dart';

/// One transactional key write publishes a complete generation; failed writes retain the previous value.
class OfflinePackageStore implements OfflinePackageRepository {
  OfflinePackageStore(this._cache);
  final AppCacheStore _cache;
  String _key(String user, String agent) =>
      'pwa/package/${Uri.encodeComponent(user)}/${Uri.encodeComponent(agent)}';
  @override
  Future<void> publish(OfflinePackage package) async {
    final key = _key(package.authorization.userId, package.agentId);
    final value = jsonEncode(package.toJson());
    await _cache.putString(key: key, value: value);
    // Ordinary caches may treat quota failures as misses. Explicitly selected
    // offline data must never report a successful download without persistence.
    if (await _cache.getString(key) != value) {
      throw const OfflinePackageException(
        OfflinePackageIssue.storageUnavailable,
      );
    }
  }

  @override
  Future<OfflinePackage?> read(String user, String agent, DateTime now) async {
    final value = await _cache.getString(_key(user, agent));
    if (value == null) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) return null;
      final package = OfflinePackage.fromJson(decoded);
      return package.agentId == agent &&
              package.authorization.permits(user, agent, now)
          ? package
          : null;
    } on FormatException {
      // Preserve unsupported generations for recovery; never expose them.
      return null;
    }
  }

  @override
  Future<void> remove(String user, String agent) =>
      _cache.removeString(_key(user, agent));
  @override
  Future<void> clearUser(String user) =>
      _cache.removeKeysWithPrefix('pwa/package/${Uri.encodeComponent(user)}/');
}
