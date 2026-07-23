import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';

/// Process-scoped cache of [AgentQueryTargetResolution] keyed by user id and
/// agent selection scope.
///
/// Populated by the agent query target resolver after each resolution so
/// surfaces such as sales agent pickers and overview can reuse the same
/// snapshot without re-paginating approved agents.
abstract interface class AgentQueryTargetResolutionCache {
  void publish({
    required String userId,
    required AgentQueryTargetResolution resolution,
    Set<String>? selectedAgentIds,
  });

  AgentQueryTargetResolution? read({
    required String userId,
    Set<String>? selectedAgentIds,
  });

  void invalidate({required String userId});

  /// Clears every cached resolution (call on logout / session invalidate).
  void clearAll();
}
