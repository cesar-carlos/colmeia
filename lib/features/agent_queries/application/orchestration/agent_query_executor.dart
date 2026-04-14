import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_plan.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:result_dart/result_dart.dart';

typedef AgentQueryTargetLoader<Row> =
    Future<AppResult<List<Row>>> Function(AgentQueryTarget target);

class AgentQueryExecutor<Row> {
  AgentQueryExecutor({this.mergeAllConcurrency = 4})
    : assert(
        mergeAllConcurrency > 0,
        'mergeAllConcurrency must be greater than zero',
      );

  final int mergeAllConcurrency;

  Future<AppResult<AgentQueryExecutionReport<Row>>> execute({
    required AgentQueryPlan plan,
    required AgentQueryTargetLoader<Row> loadTarget,
  }) {
    return switch (plan.strategy) {
      AgentQueryExecutionStrategy.singleSource => _executeSingleSource(
        plan: plan,
        loadTarget: loadTarget,
      ),
      AgentQueryExecutionStrategy.mergeAll => _executeMergeAll(
        plan: plan,
        loadTarget: loadTarget,
      ),
      AgentQueryExecutionStrategy.race => _executeRace(
        plan: plan,
        loadTarget: loadTarget,
      ),
    };
  }

  Future<AppResult<AgentQueryExecutionReport<Row>>> _executeSingleSource({
    required AgentQueryPlan plan,
    required AgentQueryTargetLoader<Row> loadTarget,
  }) async {
    if (plan.plannedTargets.isEmpty) {
      return Success<AgentQueryExecutionReport<Row>, AppFailure>(
        _emptyReport(plan: plan, totalElapsedMs: 0),
      );
    }

    final target = plan.plannedTargets.single;
    final participantResult = await _loadParticipant(
      target: target,
      loadTarget: loadTarget,
    );
    final report = AgentQueryExecutionReport<Row>(
      queryKey: plan.queryKey,
      strategy: plan.strategy,
      consideredApprovedAgentCount: plan.consideredApprovedAgentCount,
      plannedTargets: plan.plannedTargets,
      missingClientTokenTargets: plan.missingClientTokenTargets,
      participants: <AgentQueryExecutionParticipant<Row>>[
        participantResult.participant,
      ],
      totalElapsedMs: participantResult.participant.elapsedMs,
    );

    if (participantResult.failure != null) {
      return Failure<AgentQueryExecutionReport<Row>, AppFailure>(
        participantResult.failure!,
      );
    }
    return Success<AgentQueryExecutionReport<Row>, AppFailure>(report);
  }

  Future<AppResult<AgentQueryExecutionReport<Row>>> _executeMergeAll({
    required AgentQueryPlan plan,
    required AgentQueryTargetLoader<Row> loadTarget,
  }) async {
    if (plan.plannedTargets.isEmpty) {
      return Success<AgentQueryExecutionReport<Row>, AppFailure>(
        _emptyReport(plan: plan, totalElapsedMs: 0),
      );
    }

    final totalStopwatch = Stopwatch()..start();
    final participants = List<AgentQueryExecutionParticipant<Row>?>.filled(
      plan.plannedTargets.length,
      null,
    );

    for (
      var start = 0;
      start < plan.plannedTargets.length;
      start += mergeAllConcurrency
    ) {
      final end = start + mergeAllConcurrency > plan.plannedTargets.length
          ? plan.plannedTargets.length
          : start + mergeAllConcurrency;
      final indices = List<int>.generate(end - start, (index) => start + index);
      final chunk = await Future.wait(
        indices.map((index) async {
          final loaded = await _loadParticipant(
            target: plan.plannedTargets[index],
            loadTarget: loadTarget,
          );
          return (index: index, loaded: loaded);
        }),
      );

      for (final item in chunk) {
        participants[item.index] = item.loaded.participant;
      }
    }

    totalStopwatch.stop();
    final resolvedParticipants = participants
        .cast<AgentQueryExecutionParticipant<Row>>();
    final report = AgentQueryExecutionReport<Row>(
      queryKey: plan.queryKey,
      strategy: plan.strategy,
      consideredApprovedAgentCount: plan.consideredApprovedAgentCount,
      plannedTargets: plan.plannedTargets,
      missingClientTokenTargets: plan.missingClientTokenTargets,
      participants: resolvedParticipants,
      totalElapsedMs: totalStopwatch.elapsedMilliseconds,
    );

    AppFailure? firstFailure;
    for (final participant in resolvedParticipants) {
      firstFailure ??= participant.failure;
    }
    if (!report.hasRows && firstFailure != null) {
      return Failure<AgentQueryExecutionReport<Row>, AppFailure>(firstFailure);
    }
    return Success<AgentQueryExecutionReport<Row>, AppFailure>(report);
  }

  Future<AppResult<AgentQueryExecutionReport<Row>>> _executeRace({
    required AgentQueryPlan plan,
    required AgentQueryTargetLoader<Row> loadTarget,
  }) async {
    if (plan.plannedTargets.isEmpty) {
      return Success<AgentQueryExecutionReport<Row>, AppFailure>(
        _emptyReport(plan: plan, totalElapsedMs: 0),
      );
    }

    final totalStopwatch = Stopwatch()..start();
    final completer = Completer<_RaceDecision<Row>>();
    final participantsByIndex = <int, AgentQueryExecutionParticipant<Row>>{};
    var failedCount = 0;

    for (var i = 0; i < plan.plannedTargets.length; i++) {
      unawaited(() async {
        final loaded = await _loadParticipant(
          target: plan.plannedTargets[i],
          loadTarget: loadTarget,
        );
        participantsByIndex[i] = loaded.participant;
        if (loaded.failure == null) {
          if (!completer.isCompleted) {
            completer.complete(_RaceWinner<Row>(winnerIndex: i));
          }
          return;
        }

        failedCount++;
        if (failedCount == plan.plannedTargets.length &&
            !completer.isCompleted) {
          completer.complete(_RaceAllFailed<Row>());
        }
      }());
    }

    final decision = await completer.future;
    totalStopwatch.stop();

    if (decision is _RaceWinner<Row>) {
      final participants = <AgentQueryExecutionParticipant<Row>>[];
      for (var i = 0; i < plan.plannedTargets.length; i++) {
        final participant = participantsByIndex[i];
        if (participant != null) {
          participants.add(participant);
          continue;
        }
        final target = plan.plannedTargets[i];
        participants.add(
          AgentQueryExecutionParticipant<Row>(
            agentId: target.agentId,
            displayName: target.displayName,
            rows: <Row>[],
            elapsedMs: 0,
            wasDiscardedByRace: true,
          ),
        );
      }

      return Success<AgentQueryExecutionReport<Row>, AppFailure>(
        AgentQueryExecutionReport<Row>(
          queryKey: plan.queryKey,
          strategy: plan.strategy,
          consideredApprovedAgentCount: plan.consideredApprovedAgentCount,
          plannedTargets: plan.plannedTargets,
          missingClientTokenTargets: plan.missingClientTokenTargets,
          participants: participants,
          winnerAgentId: plan.plannedTargets[decision.winnerIndex].agentId,
          totalElapsedMs: totalStopwatch.elapsedMilliseconds,
        ),
      );
    }

    final participants = List<AgentQueryExecutionParticipant<Row>>.generate(
      plan.plannedTargets.length,
      (index) => participantsByIndex[index]!,
      growable: false,
    );
    final firstFailure = participants
        .map((participant) => participant.failure)
        .whereType<AppFailure>()
        .first;
    return Failure<AgentQueryExecutionReport<Row>, AppFailure>(firstFailure);
  }

  AgentQueryExecutionReport<Row> _emptyReport({
    required AgentQueryPlan plan,
    required int totalElapsedMs,
  }) {
    if (plan.skippedOnlyDueToMissingClientTokens) {
      AppLogger.warning(
        'Agent query skipped: no runnable targets (missing local client_token)',
        context: <String, Object?>{
          'queryKey': plan.queryKey.name,
          'strategy': plan.strategy.name,
          'consideredApprovedAgentCount': plan.consideredApprovedAgentCount,
          'missingClientTokenAgentIds': plan.missingClientTokenTargets
              .map((t) => t.agentId)
              .join(', '),
        },
      );
    }
    return AgentQueryExecutionReport<Row>(
      queryKey: plan.queryKey,
      strategy: plan.strategy,
      consideredApprovedAgentCount: plan.consideredApprovedAgentCount,
      plannedTargets: plan.plannedTargets,
      missingClientTokenTargets: plan.missingClientTokenTargets,
      participants: <AgentQueryExecutionParticipant<Row>>[],
      totalElapsedMs: totalElapsedMs,
    );
  }

  Future<
    ({AgentQueryExecutionParticipant<Row> participant, AppFailure? failure})
  >
  _loadParticipant({
    required AgentQueryTarget target,
    required AgentQueryTargetLoader<Row> loadTarget,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await loadTarget(target);
      stopwatch.stop();

      return result.fold(
        (rows) => (
          participant: AgentQueryExecutionParticipant<Row>(
            agentId: target.agentId,
            displayName: target.displayName,
            rows: rows,
            elapsedMs: stopwatch.elapsedMilliseconds,
          ),
          failure: null,
        ),
        (failure) => (
          participant: AgentQueryExecutionParticipant<Row>(
            agentId: target.agentId,
            displayName: target.displayName,
            rows: <Row>[],
            failure: failure,
            elapsedMs: stopwatch.elapsedMilliseconds,
          ),
          failure: failure,
        ),
      );
    } on Object catch (error, stackTrace) {
      stopwatch.stop();
      final failure = mapToAppFailure(
        error,
        stackTrace: stackTrace,
        fallbackMessage: 'Agent query target load failed',
        fallbackUserMessage: 'Unable to load data from the selected agent.',
        context: <String, Object?>{
          'operation': 'loadAgentQueryTarget',
          'agentId': target.agentId,
        },
      );
      return (
        participant: AgentQueryExecutionParticipant<Row>(
          agentId: target.agentId,
          displayName: target.displayName,
          rows: <Row>[],
          failure: failure,
          elapsedMs: stopwatch.elapsedMilliseconds,
        ),
        failure: failure,
      );
    }
  }
}

sealed class _RaceDecision<Row> {}

class _RaceWinner<Row> extends _RaceDecision<Row> {
  _RaceWinner({required this.winnerIndex});

  final int winnerIndex;
}

class _RaceAllFailed<Row> extends _RaceDecision<Row> {}
