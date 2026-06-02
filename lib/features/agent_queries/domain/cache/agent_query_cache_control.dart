import 'package:colmeia/features/agent_queries/domain/cache/agent_query_fact_kind.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_cache_invalidate_scope.dart';

/// Optional capability for repositories that persist consolidated facts.
abstract interface class AgentQueryCacheControl {
  /// Fact family owned by this repository's cache strategy.
  AgentQueryFactKind get factKind;

  Future<void> invalidateCache(AgentQueryCacheInvalidateScope scope);
}
