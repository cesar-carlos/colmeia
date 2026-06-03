import 'dart:math' as math;

import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';

/// Runs per-[AgentQueryTarget] async work with capped parallelism in sequential
/// waves ([Future.wait] per wave), preserving target order in the result list.
///
/// When `waveConcurrencyCap` is greater than or equal to the target count, all
/// tasks run in a single parallel batch. Otherwise each wave runs at most
/// `max(1, waveConcurrencyCap)` tasks before awaiting the next wave.
class AgentSqlBatchTargetWaveRunner {
  const AgentSqlBatchTargetWaveRunner();

  Future<List<T>> run<T>({
    required List<AgentQueryTarget> targets,
    required int waveConcurrencyCap,
    required Future<T> Function(AgentQueryTarget target) task,
  }) async {
    if (targets.isEmpty) {
      return <T>[];
    }
    if (waveConcurrencyCap >= targets.length) {
      return Future.wait(
        List<Future<T>>.generate(
          targets.length,
          (index) => task(targets[index]),
        ),
      );
    }
    final waveSize = math.max(1, waveConcurrencyCap);
    final results = <T>[];
    for (var start = 0; start < targets.length; start += waveSize) {
      final end = math.min(start + waveSize, targets.length);
      final chunk = await Future.wait(
        List<Future<T>>.generate(
          end - start,
          (offset) => task(targets[start + offset]),
        ),
      );
      results.addAll(chunk);
    }
    return results;
  }
}
