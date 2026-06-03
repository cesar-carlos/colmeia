import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_selection_scope.dart';
import 'package:colmeia/shared/ports/agent_query_target_resolution_cache.dart';

final class _AgentQueryTargetResolutionCacheEntry {
  const _AgentQueryTargetResolutionCacheEntry({
    required this.userId,
    required this.selectionScopeKey,
    required this.resolution,
    required this.resolvedAt,
  });

  final String userId;
  final String selectionScopeKey;
  final AgentQueryTargetResolution resolution;
  final DateTime resolvedAt;

  bool isValid({
    required String userId,
    required String selectionScopeKey,
    required DateTime now,
    required Duration ttl,
  }) {
    return this.userId == userId &&
        this.selectionScopeKey == selectionScopeKey &&
        now.difference(resolvedAt) <= ttl;
  }
}

final class InMemoryAgentQueryTargetResolutionCache
    implements AgentQueryTargetResolutionCache {
  InMemoryAgentQueryTargetResolutionCache({
    Duration Function()? ttl,
    DateTime Function()? now,
  }) : _ttl = ttl ?? (() => AppEnvironment.agentQueryTargetResolutionCacheTtl),
       _now = now ?? DateTime.now;

  static const int _maxEntriesPerUser = 8;

  final Duration Function() _ttl;
  final DateTime Function() _now;
  final Map<String, _AgentQueryTargetResolutionCacheEntry> _entries =
      <String, _AgentQueryTargetResolutionCacheEntry>{};

  @override
  void publish({
    required String userId,
    required AgentQueryTargetResolution resolution,
    Set<String>? selectedAgentIds,
  }) {
    final selectionScopeKey = AgentQueryTargetSelectionScope.cacheScopeKey(
      selectedAgentIds,
    );
    _entries[_compositeKey(userId: userId, selectionScopeKey: selectionScopeKey)] =
        _AgentQueryTargetResolutionCacheEntry(
          userId: userId,
          selectionScopeKey: selectionScopeKey,
          resolution: resolution,
          resolvedAt: _now(),
        );
    _evictOverflowForUser(userId);
  }

  @override
  AgentQueryTargetResolution? read({
    required String userId,
    Set<String>? selectedAgentIds,
  }) {
    final selectionScopeKey = AgentQueryTargetSelectionScope.cacheScopeKey(
      selectedAgentIds,
    );
    final cached = _entries[_compositeKey(
      userId: userId,
      selectionScopeKey: selectionScopeKey,
    )];
    if (cached == null) {
      return null;
    }
    if (!cached.isValid(
      userId: userId,
      selectionScopeKey: selectionScopeKey,
      now: _now(),
      ttl: _ttl(),
    )) {
      _entries.remove(
        _compositeKey(userId: userId, selectionScopeKey: selectionScopeKey),
      );
      return null;
    }
    return cached.resolution;
  }

  @override
  void invalidate({required String userId}) {
    _entries.removeWhere((_, entry) => entry.userId == userId);
  }

  String _compositeKey({
    required String userId,
    required String selectionScopeKey,
  }) {
    return '$userId::$selectionScopeKey';
  }

  void _evictOverflowForUser(String userId) {
    final userEntries = _entries.entries
        .where((entry) => entry.value.userId == userId)
        .toList(growable: false);
    if (userEntries.length <= _maxEntriesPerUser) {
      return;
    }
    userEntries.sort(
      (left, right) => left.value.resolvedAt.compareTo(right.value.resolvedAt),
    );
    final overflow = userEntries.length - _maxEntriesPerUser;
    for (var index = 0; index < overflow; index++) {
      _entries.remove(userEntries[index].key);
    }
  }
}
