import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/sales/application/sales_live_map_catalog_scope.dart';

/// In-memory short-lived cache for branch catalog pages, scoped by user and
/// query scope. Used by `LoadSalesLiveMapUseCase` to avoid re-fetching from
/// disk or network within a single session burst.
///
/// Entries expire after [ttl] elapsed since insertion. When the cache exceeds
/// [maxEntries], the oldest entries are evicted in insertion order.
class SalesLiveMapInMemoryCatalogCache {
  SalesLiveMapInMemoryCatalogCache({
    required this.maxEntries,
    required this.ttl,
  });

  final int maxEntries;
  final Duration ttl;
  final Map<String, _CachedEntry> _entries = <String, _CachedEntry>{};

  /// Returns the cached page when one exists for [userId] / [scope] and is
  /// still within [ttl] relative to [now]. Expired entries are evicted on
  /// access and `null` is returned.
  CadastroFilialAcrossAgentsPageResult? read({
    required String userId,
    required SalesLiveMapCatalogScope scope,
    required DateTime now,
  }) {
    final key = _keyFor(userId: userId, scope: scope);
    final cached = _entries[key];
    if (cached == null) {
      return null;
    }
    if (now.difference(cached.cachedAt) > ttl) {
      _entries.remove(key);
      return null;
    }
    return cached.result;
  }

  /// Writes [result] as the latest snapshot for [userId] / [scope]. Existing
  /// entries for the same key are replaced (preserving recency).
  void write({
    required String userId,
    required SalesLiveMapCatalogScope scope,
    required DateTime now,
    required CadastroFilialAcrossAgentsPageResult result,
  }) {
    final key = _keyFor(userId: userId, scope: scope);
    _entries.remove(key);
    _entries[key] = _CachedEntry(result: result, cachedAt: now);
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  static String _keyFor({
    required String userId,
    required SalesLiveMapCatalogScope scope,
  }) {
    return '${userId.trim()}|${scope.storageKey}';
  }
}

class _CachedEntry {
  const _CachedEntry({required this.result, required this.cachedAt});

  final CadastroFilialAcrossAgentsPageResult result;
  final DateTime cachedAt;
}
