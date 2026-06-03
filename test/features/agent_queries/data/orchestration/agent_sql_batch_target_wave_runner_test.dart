import 'package:colmeia/features/agent_queries/data/orchestration/agent_sql_batch_target_wave_runner.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const runner = AgentSqlBatchTargetWaveRunner();

  AgentQueryTarget targetFor(String agentId) {
    return AgentQueryTarget(
      agentId: agentId,
      displayName: agentId,
      connectionStatus: AgentConnectionStatus.online,
      clientToken: 'token-$agentId',
      hubConnectedFromApprovedCatalogRow: true,
    );
  }

  group('AgentSqlBatchTargetWaveRunner', () {
    test('returns empty list for empty targets', () async {
      final results = await runner.run<String>(
        targets: const <AgentQueryTarget>[],
        waveConcurrencyCap: 4,
        task: (_) async => 'x',
      );

      expect(results, isEmpty);
    });

    test('runs all targets in one wave when cap covers count', () async {
      final targets = List<AgentQueryTarget>.generate(
        4,
        (i) => targetFor('agent-${i + 1}'),
      );
      var active = 0;
      var maxActive = 0;

      final results = await runner.run<String>(
        targets: targets,
        waveConcurrencyCap: 4,
        task: (target) async {
          active++;
          if (active > maxActive) {
            maxActive = active;
          }
          await Future<void>.delayed(const Duration(milliseconds: 20));
          active--;
          return target.agentId;
        },
      );

      expect(results, ['agent-1', 'agent-2', 'agent-3', 'agent-4']);
      expect(maxActive, 4);
    });

    test('limits concurrent tasks per wave and preserves order', () async {
      final targets = List<AgentQueryTarget>.generate(
        5,
        (i) => targetFor('agent-${i + 1}'),
      );
      const waveConcurrencyCap = 2;
      var active = 0;
      var maxActive = 0;
      var waveStarts = 0;

      final results = await runner.run<String>(
        targets: targets,
        waveConcurrencyCap: waveConcurrencyCap,
        task: (target) async {
          if (active == 0) {
            waveStarts++;
          }
          active++;
          if (active > maxActive) {
            maxActive = active;
          }
          await Future<void>.delayed(const Duration(milliseconds: 30));
          active--;
          return target.agentId;
        },
      );

      expect(results, ['agent-1', 'agent-2', 'agent-3', 'agent-4', 'agent-5']);
      expect(maxActive, lessThanOrEqualTo(waveConcurrencyCap));
      expect(maxActive, greaterThan(1));
      expect(waveStarts, 3);
    });

    test('uses wave size of one when cap is zero', () async {
      final targets = [
        targetFor('agent-1'),
        targetFor('agent-2'),
      ];
      var maxActive = 0;
      var active = 0;

      await runner.run<void>(
        targets: targets,
        waveConcurrencyCap: 0,
        task: (_) async {
          active++;
          if (active > maxActive) {
            maxActive = active;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
          active--;
        },
      );

      expect(maxActive, 1);
    });
  });
}
