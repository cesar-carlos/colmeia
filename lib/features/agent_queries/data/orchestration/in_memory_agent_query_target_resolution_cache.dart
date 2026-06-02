import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/shared/ports/agent_query_target_resolution_cache.dart';

final class _AgentQueryTargetResolutionCacheEntry {
  const _AgentQueryTargetResolutionCacheEntry({
    required this.userId,
    required this.resolution,
    required this.resolvedAt,
  });

  final String userId;
  final AgentQueryTargetResolution resolution;
  final DateTime resolvedAt;

  bool isValid({required String userId, required DateTime now, required Duration ttl}) {
    return this.userId == userId && now.difference(resolvedAt) <= ttl;
  }
}

final class InMemoryAgentQueryTargetResolutionCache
    implements AgentQueryTargetResolutionCache {
  InMemoryAgentQueryTargetResolutionCache({
    Duration Function()? ttl,
    DateTime Function()? now,
  }) : _ttl = ttl ?? (() => AppEnvironment.agentQueryTargetResolutionCacheTtl),
       _now = now ?? DateTime.now;

  final Duration Function() _ttl;
  final DateTime Function() _now;

  _AgentQueryTargetResolutionCacheEntry? _entry;

  @override
  void publish({
    required String userId,
    required AgentQueryTargetResolution resolution,
  }) {
    _entry = _AgentQueryTargetResolutionCacheEntry(
      userId: userId,
      resolution: resolution,
      resolvedAt: _now(),
    );
  }

  @override
  AgentQueryTargetResolution? read({required String userId}) {
    final cached = _entry;
    if (cached == null) {
      return null;
    }
    if (!cached.isValid(userId: userId, now: _now(), ttl: _ttl())) {
      return null;
    }
    return cached.resolution;
  }

  @override
  void invalidate({required String userId}) {
    final cached = _entry;
    if (cached == null || cached.userId != userId) {
      return;
    }
    _entry = null;
  }
}
