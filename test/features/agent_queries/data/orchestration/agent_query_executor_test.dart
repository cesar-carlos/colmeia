import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_plan.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  late AgentQueryExecutor<int> executor;

  setUp(() {
    executor = AgentQueryExecutor<int>(mergeAllConcurrency: 2);
  });

  test(
    'should succeed with empty merged rows when at least one target succeeds '
    'without rows while another fails',
    () async {
      final result = await executor.execute(
        plan: _plan(
          strategy: AgentQueryExecutionStrategy.mergeAll,
          plannedTargets: <AgentQueryTarget>[
            _target('agent-a'),
            _target('agent-b'),
          ],
        ),
        loadTarget: (target) async {
          if (target.agentId == 'agent-a') {
            return const Success<List<int>, AppFailure>(<int>[]);
          }
          return const Failure<List<int>, AppFailure>(
            NetworkFailure(message: 'failed', userMessage: 'failed'),
          );
        },
      );

      check(result.isSuccess()).isTrue();
      final report = result.getOrThrow();
      check(report.hasRows).isFalse();
      check(report.failedAgentIds).deepEquals(const <String>['agent-b']);
    },
  );

  test(
    'should aggregate successes and preserve failures in merge all',
    () async {
      final result = await executor.execute(
        plan: _plan(
          strategy: AgentQueryExecutionStrategy.mergeAll,
          plannedTargets: <AgentQueryTarget>[
            _target('agent-a'),
            _target('agent-b'),
          ],
        ),
        loadTarget: (target) async {
          if (target.agentId == 'agent-a') {
            await Future<void>.delayed(const Duration(milliseconds: 20));
            return const Success<List<int>, AppFailure>(<int>[1, 2]);
          }
          await Future<void>.delayed(const Duration(milliseconds: 5));
          return const Failure<List<int>, AppFailure>(
            NetworkFailure(message: 'failed', userMessage: 'failed'),
          );
        },
      );

      check(result.isSuccess()).isTrue();
      final report = result.getOrThrow();
      check(report.mergedRows).deepEquals(const <int>[1, 2]);
      check(report.failedAgentIds).deepEquals(const <String>['agent-b']);
      check(report.rowsByAgentId['agent-a']!).deepEquals(const <int>[1, 2]);
      check(report.rowsByAgentId['agent-b']!).deepEquals(const <int>[]);
    },
  );

  test('should fail when all targets fail in merge all', () async {
    final result = await executor.execute(
      plan: _plan(
        strategy: AgentQueryExecutionStrategy.mergeAll,
        plannedTargets: <AgentQueryTarget>[_target('agent-a')],
      ),
      loadTarget: (_) async => const Failure<List<int>, AppFailure>(
        NetworkFailure(message: 'failed', userMessage: 'failed'),
      ),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<NetworkFailure>();
  });

  test(
    'should return empty success when there are no planned targets',
    () async {
      final result = await executor.execute(
        plan: _plan(
          strategy: AgentQueryExecutionStrategy.mergeAll,
          plannedTargets: const <AgentQueryTarget>[],
          missingClientTokenTargets: <AgentQueryTarget>[_target('agent-a')],
        ),
        loadTarget: (_) async => const Success<List<int>, AppFailure>(<int>[]),
      );

      check(result.isSuccess()).isTrue();
      final report = result.getOrThrow();
      check(report.hasRows).isFalse();
      check(report.requiresClientTokenSetup).isTrue();
    },
  );

  test(
    'single source short-circuits with empty success when planned targets '
    'are empty after hub presence filtering',
    () async {
      final result = await executor.execute(
        plan: const AgentQueryPlan(
          queryKey: AgentQueryKey.resumoParcelasDiaSemana,
          strategy: AgentQueryExecutionStrategy.singleSource,
          consideredApprovedAgentCount: 1,
          plannedTargets: <AgentQueryTarget>[],
          missingClientTokenTargets: <AgentQueryTarget>[],
          bridgeTimeoutMs: 1000,
        ),
        loadTarget: (_) async =>
            throw StateError('loadTarget must not be invoked'),
      );

      check(result.isSuccess()).isTrue();
      final report = result.getOrThrow();
      check(report.hasRows).isFalse();
      check(report.plannedTargets).isEmpty();
    },
  );

  test('should choose the first successful target in race', () async {
    final result = await executor.execute(
      plan: _plan(
        strategy: AgentQueryExecutionStrategy.race,
        plannedTargets: <AgentQueryTarget>[
          _target('agent-a'),
          _target('agent-b'),
          _target('agent-c'),
        ],
      ),
      loadTarget: (target) async {
        if (target.agentId == 'agent-a') {
          await Future<void>.delayed(const Duration(milliseconds: 60));
          return const Success<List<int>, AppFailure>(<int>[10]);
        }
        if (target.agentId == 'agent-b') {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return const Failure<List<int>, AppFailure>(
            NetworkFailure(message: 'failed', userMessage: 'failed'),
          );
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return const Success<List<int>, AppFailure>(<int>[30]);
      },
    );

    check(result.isSuccess()).isTrue();
    final report = result.getOrThrow();
    check(report.winnerAgentId).equals('agent-c');
    check(report.failedAgentIds).deepEquals(const <String>['agent-b']);
    check(
      report.participants
          .firstWhere((participant) => participant.agentId == 'agent-a')
          .wasDiscardedByRace,
    ).isTrue();
    await Future<void>.delayed(const Duration(milliseconds: 80));
  });

  test('should map thrown exceptions to failure in merge all', () async {
    final result = await executor.execute(
      plan: _plan(
        strategy: AgentQueryExecutionStrategy.mergeAll,
        plannedTargets: <AgentQueryTarget>[_target('agent-a')],
      ),
      loadTarget: (_) async {
        throw StateError('boom');
      },
    );

    check(result.isError()).isTrue();
    final failure = result.exceptionOrNull()!;
    check(failure).isA<UnknownFailure>();
    check(failure.context['agentId']).equals('agent-a');
  });

  test('should map thrown exceptions to failure in race', () async {
    final result = await executor.execute(
      plan: _plan(
        strategy: AgentQueryExecutionStrategy.race,
        plannedTargets: <AgentQueryTarget>[
          _target('agent-a'),
          _target('agent-b'),
        ],
      ),
      loadTarget: (target) async {
        if (target.agentId == 'agent-a') {
          throw StateError('boom');
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return const Success<List<int>, AppFailure>(<int>[2]);
      },
    );

    check(result.isSuccess()).isTrue();
    final report = result.getOrThrow();
    check(report.winnerAgentId).equals('agent-b');
    check(report.failedAgentIds).deepEquals(const <String>['agent-a']);
  });

  group('race total timeout (BUG #3: avoid frozen UI)', () {
    test(
      'should fail with NetworkFailure when no participant settles within '
      'raceTotalTimeout (defensive deadlock guard)',
      () async {
        final executor = AgentQueryExecutor<int>(
          mergeAllConcurrency: 2,
          raceTotalTimeout: const Duration(milliseconds: 100),
        );
        final result = await executor.execute(
          plan: _plan(
            strategy: AgentQueryExecutionStrategy.race,
            plannedTargets: <AgentQueryTarget>[
              _target('agent-a'),
              _target('agent-b'),
            ],
          ),
          loadTarget: (_) {
            // Future that never completes -> simulates a buggy upstream
            // that swallows the dispatcher timeout.
            return Completer<AppResult<List<int>>>().future;
          },
        );

        check(result.isError()).isTrue();
        final failure = result.exceptionOrNull()!;
        check(failure).isA<NetworkFailure>();
        check(
          failure.userMessage,
        ).isNotNull().contains('demorou mais que o tempo permitido');
        check(failure.context['reason']).equals('race_total_timeout');
        check(failure.context['raceTotalTimeoutMs']).equals(100);
        check(failure.context['plannedTargetCount']).equals(2);
        check(failure.context['settledTargetCount']).equals(0);
      },
    );

    test(
      'race total timeout does NOT fire when at least one participant '
      'succeeds within the window',
      () async {
        final executor = AgentQueryExecutor<int>(
          mergeAllConcurrency: 2,
          raceTotalTimeout: const Duration(seconds: 5),
        );
        final result = await executor.execute(
          plan: _plan(
            strategy: AgentQueryExecutionStrategy.race,
            plannedTargets: <AgentQueryTarget>[_target('agent-a')],
          ),
          loadTarget: (_) async {
            await Future<void>.delayed(const Duration(milliseconds: 5));
            return const Success<List<int>, AppFailure>(<int>[1]);
          },
        );

        check(result.isSuccess()).isTrue();
        check(result.getOrThrow().winnerAgentId).equals('agent-a');
      },
    );

    test(
      'race total timeout still fires when only some participants settle '
      '(others never resolve and not all have failed)',
      () async {
        final executor = AgentQueryExecutor<int>(
          mergeAllConcurrency: 2,
          raceTotalTimeout: const Duration(milliseconds: 100),
        );
        final result = await executor.execute(
          plan: _plan(
            strategy: AgentQueryExecutionStrategy.race,
            plannedTargets: <AgentQueryTarget>[
              _target('agent-a'),
              _target('agent-b'),
              _target('agent-c'),
            ],
          ),
          loadTarget: (target) {
            if (target.agentId == 'agent-a') {
              // Settles with failure quickly.
              return Future.value(
                const Failure<List<int>, AppFailure>(
                  NetworkFailure(message: 'down', userMessage: 'down'),
                ),
              );
            }
            // The other two never settle.
            return Completer<AppResult<List<int>>>().future;
          },
        );

        check(result.isError()).isTrue();
        final failure = result.exceptionOrNull()!;
        check(failure).isA<NetworkFailure>();
        check(failure.context['reason']).equals('race_total_timeout');
        check(failure.context['settledTargetCount']).equals(1);
        check(failure.context['failedCount']).equals(1);
      },
    );
  });
}

AgentQueryPlan _plan({
  required AgentQueryExecutionStrategy strategy,
  required List<AgentQueryTarget> plannedTargets,
  List<AgentQueryTarget> missingClientTokenTargets = const <AgentQueryTarget>[],
}) {
  return AgentQueryPlan(
    queryKey: AgentQueryKey.resumoParcelaFormaPagamento,
    strategy: strategy,
    consideredApprovedAgentCount:
        plannedTargets.length + missingClientTokenTargets.length,
    plannedTargets: plannedTargets,
    missingClientTokenTargets: missingClientTokenTargets,
    bridgeTimeoutMs: 1000,
    raceMaxSources: strategy == AgentQueryExecutionStrategy.race ? 4 : null,
  );
}

AgentQueryTarget _target(String agentId) {
  return AgentQueryTarget(
    agentId: agentId,
    displayName: agentId,
    connectionStatus: AgentConnectionStatus.online,
    clientToken: 'token',
  );
}
