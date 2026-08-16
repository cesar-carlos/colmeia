import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_request_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';

/// Short-term cache for idempotent SQL queries to reduce redundant hub calls.
///
/// Caches successful results for a brief TTL (default 3 seconds) to handle:
/// - Rapid UI refreshes (pull-to-refresh spam)
/// - Multiple widgets requesting the same data during a single frame
/// - Back-and-forth navigation within a short window
///
/// The cache is keyed by (agentId + sql + params + clientToken) to prevent
/// stale or cross-user data leakage. Cache entries are invalidated when:
/// - TTL expires (default 3 seconds, tunable by AGENT_SQL_CACHE_TTL_MS)
/// - Maximum cache size is exceeded (LRU eviction, default 500 entries)
/// - Session changes (clientToken mismatch)
///
/// Only successful **non-empty** results are cached. Failures and empty
/// success payloads propagate without caching so retries and circuit breaker
/// logic can operate normally (empty streaming successes are often flaky on
/// some agents, not a durable "no data" answer).
///
/// [executeSqlBatch] uses [AgentQueriesRequestKey.buildBatch] for the same TTL
/// and combined LRU budget as single-query cache entries.
class CachingAgentQueriesRepository implements AgentQueriesRepository {
  CachingAgentQueriesRepository({
    required this._delegate,
    this._cacheTtl = defaultCacheTtl,
    this._catalogCacheTtl,
    this._maxCacheSize = 500,
  });

  static const Duration defaultCacheTtl = Duration(seconds: 3);

  final AgentQueriesRepository _delegate;
  final Duration _cacheTtl;
  final Duration? _catalogCacheTtl;
  final int _maxCacheSize;

  final Map<String, _SqlCacheEntry> _sqlCache = <String, _SqlCacheEntry>{};
  final Map<String, _BatchCacheEntry> _batchCache =
      <String, _BatchCacheEntry>{};

  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _batchCacheHits = 0;
  int _batchCacheMisses = 0;

  /// Visible for testing and observability.
  int get cacheHits => _cacheHits;

  /// Visible for testing and observability.
  int get cacheMisses => _cacheMisses;

  /// Visible for testing and observability.
  int get batchCacheHits => _batchCacheHits;

  /// Visible for testing and observability.
  int get batchCacheMisses => _batchCacheMisses;

  /// Visible for testing and observability.
  int get cacheSize => _sqlCache.length + _batchCache.length;

  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final key = AgentQueriesRequestKey.build(request);
    final now = DateTime.now();
    final ttl = _effectiveTtlForSql(request.trimmedSql);

    if (!request.skipTransportCache) {
      final entry = _sqlCache[key];
      if (entry != null && now.difference(entry.cachedAt) <= ttl) {
        _cacheHits++;
        AppLogger.debug(
          'Cache hit for SQL query',
          context: <String, Object?>{
            'operation': 'executeAgentSql',
            'agentId': request.trimmedAgentId,
            'cacheHits': _cacheHits,
            'cacheMisses': _cacheMisses,
            'age': now.difference(entry.cachedAt).inMilliseconds,
          },
        );
        return entry.result;
      }
    }

    _cacheMisses++;
    final result = await _delegate.executeSql(
      request,
      cancelScope: cancelScope,
    );

    if (result.isSuccess() && !request.skipTransportCache) {
      final execution = result.getOrThrow();
      // Empty success payloads are often transport/agent flakiness on SQL
      // Anywhere streaming (not a durable "no data" answer). Caching them
      // poisons refreshes and sibling screens that share the same request key.
      if (execution.rows.isNotEmpty) {
        _sqlCache[key] = _SqlCacheEntry(
          result: result,
          cachedAt: DateTime.now(),
        );

        _evictOldestIfOverBudget();
      }
    }

    return result;
  }

  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final key = AgentQueriesRequestKey.buildBatch(request);
    final now = DateTime.now();

    if (!request.skipTransportCache) {
      final entry = _batchCache[key];
      if (entry != null && now.difference(entry.cachedAt) <= _cacheTtl) {
        _batchCacheHits++;
        AppLogger.debug(
          'Cache hit for SQL batch',
          context: <String, Object?>{
            'operation': 'executeAgentSqlBatch',
            'agentId': request.trimmedAgentId,
            'batchCacheHits': _batchCacheHits,
            'batchCacheMisses': _batchCacheMisses,
            'age': now.difference(entry.cachedAt).inMilliseconds,
          },
        );
        return entry.result;
      }
    }

    _batchCacheMisses++;
    final result = await _delegate.executeSqlBatch(
      request,
      cancelScope: cancelScope,
    );

    if (result.isSuccess() && !request.skipTransportCache) {
      _batchCache[key] = _BatchCacheEntry(
        result: result,
        cachedAt: DateTime.now(),
      );

      _evictOldestIfOverBudget();
    }

    return result;
  }

  void _evictOldestIfOverBudget() {
    while (_sqlCache.length + _batchCache.length > _maxCacheSize) {
      if (_sqlCache.isEmpty && _batchCache.isEmpty) {
        break;
      }

      String? keyToRemove;
      var removeBatch = false;
      DateTime? oldestAt;

      for (final e in _sqlCache.entries) {
        if (oldestAt == null || e.value.cachedAt.isBefore(oldestAt)) {
          oldestAt = e.value.cachedAt;
          keyToRemove = e.key;
          removeBatch = false;
        }
      }
      for (final e in _batchCache.entries) {
        if (oldestAt == null || e.value.cachedAt.isBefore(oldestAt)) {
          oldestAt = e.value.cachedAt;
          keyToRemove = e.key;
          removeBatch = true;
        }
      }

      if (keyToRemove == null) {
        break;
      }
      if (removeBatch) {
        _batchCache.remove(keyToRemove);
      } else {
        _sqlCache.remove(keyToRemove);
      }

      AppLogger.debug(
        'Evicted oldest cache entry (LRU)',
        context: <String, Object?>{
          'operation': 'CachingAgentQueriesRepository',
          'cacheSize': cacheSize,
          'maxCacheSize': _maxCacheSize,
        },
      );
    }
  }

  Duration _effectiveTtlForSql(String sql) {
    final catalogTtl = _catalogCacheTtl;
    if (catalogTtl != null && _isCatalogReadOnlySql(sql)) {
      return catalogTtl;
    }
    return _cacheTtl;
  }

  static bool _isCatalogReadOnlySql(String sql) {
    final normalized = sql.toLowerCase();
    return normalized.contains(' from filial') ||
        normalized.contains('\nfrom filial');
  }

  /// Clears all cached entries. Useful for testing or explicit cache busting.
  void clear() {
    _sqlCache.clear();
    _batchCache.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
    _batchCacheHits = 0;
    _batchCacheMisses = 0;
  }
}

class _SqlCacheEntry {
  _SqlCacheEntry({
    required this.result,
    required this.cachedAt,
  });

  final AppResult<AgentSqlExecutionResult> result;
  final DateTime cachedAt;
}

class _BatchCacheEntry {
  _BatchCacheEntry({
    required this.result,
    required this.cachedAt,
  });

  final AppResult<AgentSqlBatchExecutionResult> result;
  final DateTime cachedAt;
}
