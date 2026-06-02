import 'package:colmeia/features/agent_queries/domain/cache/agent_query_cache_control.dart' show AgentQueryCacheControl;
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_fact_kind.dart';

/// Target for [AgentQueryCacheControl.invalidateCache].
sealed class AgentQueryCacheInvalidateScope {
  const AgentQueryCacheInvalidateScope();
}

final class AgentQueryCacheInvalidateUser extends AgentQueryCacheInvalidateScope {
  const AgentQueryCacheInvalidateUser({required this.userId});

  final String userId;
}

final class AgentQueryCacheInvalidateAgent extends AgentQueryCacheInvalidateScope {
  const AgentQueryCacheInvalidateAgent({
    required this.userId,
    required this.agentId,
  });

  final String userId;
  final String agentId;
}

final class AgentQueryCacheInvalidateFactKind
    extends AgentQueryCacheInvalidateScope {
  const AgentQueryCacheInvalidateFactKind({
    required this.userId,
    required this.factKind,
  });

  final String userId;
  final AgentQueryFactKind factKind;
}

final class AgentQueryCacheInvalidateBucket
    extends AgentQueryCacheInvalidateScope {
  const AgentQueryCacheInvalidateBucket({
    required this.userId,
    required this.agentId,
    required this.factKind,
    required this.cacheScopeId,
    required this.bucketId,
  });

  final String userId;
  final String agentId;
  final AgentQueryFactKind factKind;

  /// Must match the scope used when the bucket was persisted.
  final String cacheScopeId;
  final String bucketId;
}
