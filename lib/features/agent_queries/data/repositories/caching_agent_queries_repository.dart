import 'dart:convert';

import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:crypto/crypto.dart';

/// Short-term cache for idempotent SQL queries to reduce redundant hub calls.
///
/// Caches successful results for a brief TTL (default 5 seconds) to handle:
/// - Rapid UI refreshes (pull-to-refresh spam)
/// - Multiple widgets requesting the same data during a single frame
/// - Back-and-forth navigation within a short window
///
/// The cache is keyed by (agentId + sql + params + clientToken) to prevent
/// stale or cross-user data leakage. Cache entries are invalidated when:
/// - TTL expires (default 5 seconds)
/// - Maximum cache size is exceeded (LRU eviction, default 100 entries)
/// - Session changes (clientToken mismatch)
///
/// Only successful results are cached. Failures propagate immediately without
/// caching to allow retries and circuit breaker logic to operate normally.
class CachingAgentQueriesRepository implements AgentQueriesRepository {
  CachingAgentQueriesRepository({
    required AgentQueriesRepository delegate,
    Duration cacheTtl = const Duration(seconds: 5),
    int maxCacheSize = 100,
  })  : _delegate = delegate,
        _cacheTtl = cacheTtl,
        _maxCacheSize = maxCacheSize;

  final AgentQueriesRepository _delegate;
  final Duration _cacheTtl;
  final int _maxCacheSize;

  final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};

  int _cacheHits = 0;
  int _cacheMisses = 0;

  /// Visible for testing and observability.
  int get cacheHits => _cacheHits;

  /// Visible for testing and observability.
  int get cacheMisses => _cacheMisses;

  /// Visible for testing and observability.
  int get cacheSize => _cache.length;

  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request,
  ) async {
    final key = _buildKey(request);
    final now = DateTime.now();

    final entry = _cache[key];
    if (entry != null && now.difference(entry.cachedAt) <= _cacheTtl) {
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

    _cacheMisses++;
    final result = await _delegate.executeSql(request);

    if (result.isSuccess()) {
      _cache[key] = _CacheEntry(
        result: result,
        cachedAt: now,
      );

      if (_cache.length > _maxCacheSize) {
        _evictOldest();
      }
    }

    return result;
  }

  void _evictOldest() {
    if (_cache.isEmpty) {
      return;
    }

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _cache.entries) {
      if (oldestTime == null || entry.value.cachedAt.isBefore(oldestTime)) {
        oldestTime = entry.value.cachedAt;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _cache.remove(oldestKey);
      AppLogger.debug(
        'Evicted oldest cache entry (LRU)',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'cacheSize': _cache.length,
          'maxCacheSize': _maxCacheSize,
        },
      );
    }
  }

  String _buildKey(AgentSqlExecuteRequest request) {
    final components = <String>[
      request.agentId,
      request.sql,
      jsonEncode(request.namedParams),
      request.clientToken ?? '',
    ];
    final combined = components.join('|');
    return md5.convert(utf8.encode(combined)).toString();
  }

  /// Clears all cached entries. Useful for testing or explicit cache busting.
  void clear() {
    _cache.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
  }
}

class _CacheEntry {
  _CacheEntry({
    required this.result,
    required this.cachedAt,
  });

  final AppResult<AgentSqlExecutionResult> result;
  final DateTime cachedAt;
}
