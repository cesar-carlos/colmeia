import 'package:colmeia/features/agent_queries/data/orchestration/in_memory_agent_query_target_resolution_cache.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryAgentQueryTargetResolutionCache', () {
    test('keys entries by user id and selection scope', () {
      final cache = InMemoryAgentQueryTargetResolutionCache();
      final allResolution = _resolution(
        agentIds: const <String>['agent-a', 'agent-b'],
      );
      final selectedResolution = _resolution(
        agentIds: const <String>['agent-a'],
        selectedAgentIds: const <String>{'agent-a'},
      );

      cache
        ..publish(userId: 'user-1', resolution: allResolution)
        ..publish(
          userId: 'user-1',
          resolution: selectedResolution,
          selectedAgentIds: const <String>{'agent-a'},
        );

      final allScope = cache.read(userId: 'user-1');
      final selectedScope = cache.read(
        userId: 'user-1',
        selectedAgentIds: const <String>{'agent-a'},
      );
      final otherSelectionScope = cache.read(
        userId: 'user-1',
        selectedAgentIds: const <String>{'agent-b'},
      );

      expect(allScope?.consideredApprovedAgentCount, 2);
      expect(selectedScope?.consideredApprovedAgentCount, 1);
      expect(otherSelectionScope, isNull);
    });

    test('expires entries after ttl', () {
      var now = DateTime.utc(2026, 6, 3, 12);
      final cache = InMemoryAgentQueryTargetResolutionCache(
        ttl: () => const Duration(seconds: 30),
        now: () => now,
      )..publish(
        userId: 'user-1',
        resolution: _resolution(agentIds: const <String>['agent-a']),
      );

      now = now.add(const Duration(seconds: 31));

      expect(cache.read(userId: 'user-1'), isNull);
    });

    test('invalidate clears all scopes for the user', () {
      final cache = InMemoryAgentQueryTargetResolutionCache()
        ..publish(
          userId: 'user-1',
          resolution: _resolution(agentIds: const <String>['agent-a']),
        )
        ..publish(
          userId: 'user-1',
          resolution: _resolution(
            agentIds: const <String>['agent-a'],
            selectedAgentIds: const <String>{'agent-a'},
          ),
          selectedAgentIds: const <String>{'agent-a'},
        )
        ..publish(
          userId: 'user-2',
          resolution: _resolution(agentIds: const <String>['agent-z']),
        )
        ..invalidate(userId: 'user-1');

      final userOneScope = cache.read(userId: 'user-1');
      final userOneSelectedScope = cache.read(
        userId: 'user-1',
        selectedAgentIds: const <String>{'agent-a'},
      );
      final userTwoScope = cache.read(userId: 'user-2');

      expect(userOneScope, isNull);
      expect(userOneSelectedScope, isNull);
      expect(userTwoScope?.consideredApprovedAgentCount, 1);
    });
  });
}

AgentQueryTargetResolution _resolution({
  required List<String> agentIds,
  Set<String>? selectedAgentIds,
}) {
  final targets = agentIds
      .map(
        (agentId) => AgentQueryTarget(
          agentId: agentId,
          displayName: agentId,
          connectionStatus: AgentConnectionStatus.online,
          clientToken: 'token-$agentId',
        ),
      )
      .toList(growable: false);
  return AgentQueryTargetResolution(
    consideredApprovedTargets: targets,
    missingClientTokenTargets: const <AgentQueryTarget>[],
    consideredApprovedAgentCount: targets.length,
    selectedAgentIds: selectedAgentIds,
    sqlEligibleConsideredTargetCount: targets.length,
  );
}
