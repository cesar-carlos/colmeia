import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';

/// Process-scoped cache of [AgentQueryTargetResolution] keyed by user id.
///
/// Populated by the agent query target resolver after each full resolution so
/// surfaces such as sales agent pickers can reuse the same snapshot without
/// re-paginating approved agents.
abstract interface class AgentQueryTargetResolutionCache {
  void publish({
    required String userId,
    required AgentQueryTargetResolution resolution,
  });

  AgentQueryTargetResolution? read({required String userId});

  void invalidate({required String userId});
}
