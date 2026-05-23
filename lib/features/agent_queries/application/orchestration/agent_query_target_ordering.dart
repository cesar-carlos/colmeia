import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';

/// Target ordering helpers for merge-all orchestration.
abstract final class AgentQueryTargetOrdering {
  /// Puts hub-online targets first so the first merge wave hits responsive agents.
  static List<AgentQueryTarget> onlineFirst(
    Iterable<AgentQueryTarget> targets,
  ) {
    final online = <AgentQueryTarget>[];
    final offline = <AgentQueryTarget>[];
    for (final target in targets) {
      if (target.hubConnectedFromApprovedCatalogRow == true) {
        online.add(target);
      } else {
        offline.add(target);
      }
    }
    return <AgentQueryTarget>[...online, ...offline];
  }

  /// Removes duplicate [AgentQueryTarget.agentId] entries (keeps first).
  static List<AgentQueryTarget> dedupeByAgentId(
    Iterable<AgentQueryTarget> targets,
  ) {
    final seen = <String>{};
    final out = <AgentQueryTarget>[];
    for (final target in targets) {
      if (seen.add(target.agentId)) {
        out.add(target);
      }
    }
    return out;
  }
}
