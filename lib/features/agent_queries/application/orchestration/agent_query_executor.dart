import 'dart:async';

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_query_app_failure_enrichment.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_loaded_rows.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_plan.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:result_dart/result_dart.dart';

typedef AgentQueryTargetLoader<Row> = Future<AppResult<List<Row>>> Function(
  AgentQueryTarget target,
);

typedef AgentQueryLoadedRowsTargetLoader<Row> =
    Future<AppResult<AgentQueryLoadedRows<Row>>> Function(
      AgentQueryTarget target,
    );

/// Runs agent-query plans. Merge-all issues parallel bridge calls in waves
/// (`Future.wait`). Race fires all loads but keeps only the first success for
/// the report — use that only when a single agent answer is enough, not for
/// consolidated multi-branch KPIs.
class AgentQueryExecutor<Row> {
  /// Default concurrency tuned to reduce bridge/agent overload on wide merges.
  ///
  /// [raceTotalTimeout] is a defensive safety net for the race strategy: if
  /// at least one participant never resolves AND not all of them have failed
  /// yet, the underlying `Completer` would deadlock and the caller would
  /// wait forever. The timeout caps that wait and surfaces a typed
  /// [NetworkFailure] so the UI can show "took too long" instead of
  /// freezing the screen. The dispatchers (Socket, REST) already enforce
  /// per-request timeouts that are typically much smaller than this cap; in
  /// production this guard should never fire — it exists exclusively to
  /// keep the executor from trusting upstream timeouts blindly.
  AgentQueryExecutor({
    this.mergeAllConcurrency =
        AppEnvironment.defaultAgentQueryMergeAllConcurrency,
    this.raceTotalTimeout = const Duration(minutes: 2),
  }) : assert(
         mergeAllConcurrency > 0,
         'mergeAllConcurrency must be greater than zero',
       );

  /// Max concurrent `loadTarget` calls per wave in merge-all mode.
  final int mergeAllConcurrency;

  /// Hard cap on how long the race strategy is willing to wait before it
  /// gives up and surfaces a [NetworkFailure]. See the constructor docs for
  /// the rationale.
  final Duration raceTotalTimeout;

  Future<AppResult<AgentQueryExecutionReport<Row>>> execute({
    required AgentQueryPlan plan,
    required AgentQueryTargetLoader<Row> loadTarget,
  }) {
    return executeLoadedRows(
      plan: plan,
      loadTarget: (target) async {
        final result = await loadTarget(target);
        return result.fold(
          (rows) => Success<AgentQueryLoadedRows<Row>, AppFailure>(
            AgentQueryLoadedRows<Row>(rows: rows),
          ),
          Failure<AgentQueryLoadedRows<Row>, AppFailure>.new,
        );
      },
    );
  }

  Future<AppResult<AgentQueryExecutionReport<Row>>> executeLoadedRows({
    required AgentQueryPlan plan,
    required AgentQueryLoadedRowsTargetLoader<Row> loadTarget,
    int? mergeAllConcurrencyOverride,
  }) {
    return switch (plan.strategy) {
      AgentQueryExecutionStrategy.singleSource => _executeSingleSource(
        plan: plan,
        loadTarget: loadTarget,
      ),
      AgentQueryExecutionStrategy.mergeAll => _executeMergeAll(
        plan: plan,
        loadTarget: loadTarget,
        mergeAllConcurrencyOverride: mergeAllConcurrencyOverride,
      ),
      AgentQueryExecutionStrategy.race => _executeRace(
        plan: plan,
        loadTarget: loadTarget,
      ),
    };
  }

  Future<AppResult<AgentQueryExecutionReport<Row>>> _executeSingleSource({
    required AgentQueryPlan plan,
    required AgentQueryLoadedRowsTargetLoader<Row> loadTarget,
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
      skippedDueToHubPresenceTargets: plan.skippedDueToHubPresenceTargets,
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
    required AgentQueryLoadedRowsTargetLoader<Row> loadTarget,
    int? mergeAllConcurrencyOverride,
  }) async {
    if (plan.plannedTargets.isEmpty) {
      return Success<AgentQueryExecutionReport<Row>, AppFailure>(
        _emptyReport(plan: plan, totalElapsedMs: 0),
      );
    }

    final waveSize = mergeAllConcurrencyOverride ?? mergeAllConcurrency;
    final totalStopwatch = Stopwatch()..start();
    final participants = List<AgentQueryExecutionParticipant<Row>?>.filled(
      plan.plannedTargets.length,
      null,
    );

    for (var start = 0; start < plan.plannedTargets.length; start += waveSize) {
      final end = start + waveSize > plan.plannedTargets.length
          ? plan.plannedTargets.length
          : start + waveSize;
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
      skippedDueToHubPresenceTargets: plan.skippedDueToHubPresenceTargets,
      participants: resolvedParticipants,
      totalElapsedMs: totalStopwatch.elapsedMilliseconds,
    );

    final failureTypes = <String, int>{};
    for (final p in resolvedParticipants) {
      final f = p.failure;
      if (f != null) {
        final name = f.runtimeType.toString();
        failureTypes[name] = (failureTypes[name] ?? 0) + 1;
      }
    }
    AppLogger.info(
      'Agent query mergeAll wave completed',
      context: <String, Object?>{
        'queryKey': plan.queryKey.name,
        'mergeAllConcurrency': mergeAllConcurrency,
        'consideredApprovedAgentCount': plan.consideredApprovedAgentCount,
        'targetCount': plan.plannedTargets.length,
        'failureCount': failureTypes.values.fold<int>(0, (a, b) => a + b),
        'failureTypes': failureTypes,
        'totalElapsedMs': totalStopwatch.elapsedMilliseconds,
      },
    );

    AppFailure? firstFailure;
    for (final participant in resolvedParticipants) {
      firstFailure ??= participant.failure;
    }
    final everyParticipantFailed = resolvedParticipants.every(
      (participant) => participant.failure != null,
    );
    if (!report.hasRows && firstFailure != null && everyParticipantFailed) {
      return Failure<AgentQueryExecutionReport<Row>, AppFailure>(firstFailure);
    }
    return Success<AgentQueryExecutionReport<Row>, AppFailure>(report);
  }

  Future<AppResult<AgentQueryExecutionReport<Row>>> _executeRace({
    required AgentQueryPlan plan,
    required AgentQueryLoadedRowsTargetLoader<Row> loadTarget,
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

    final decision = await completer.future.timeout(
      raceTotalTimeout,
      onTimeout: () {
        AppLogger.warning(
          'Agent query race timed out before any target settled',
          context: <String, Object?>{
            'queryKey': plan.queryKey.name,
            'strategy': plan.strategy.name,
            'plannedTargetCount': plan.plannedTargets.length,
            'settledTargetCount': participantsByIndex.length,
            'failedCount': failedCount,
            'raceTotalTimeoutMs': raceTotalTimeout.inMilliseconds,
            'unresolvedAgentIds': <String>[
              for (var i = 0; i < plan.plannedTargets.length; i++)
                if (!participantsByIndex.containsKey(i))
                  plan.plannedTargets[i].agentId,
            ],
          },
        );
        return _RaceTimedOut<Row>();
      },
    );
    totalStopwatch.stop();

    if (decision is _RaceTimedOut<Row>) {
      // Pending participants are intentionally NOT awaited here: their
      // futures may complete later but we no longer need their result.
      // We synthesize a NetworkFailure so the caller sees a typed,
      // actionable error instead of a hung Future.
      return Failure<AgentQueryExecutionReport<Row>, AppFailure>(
        NetworkFailure(
          message:
              'Agent query race did not settle within '
              '${raceTotalTimeout.inSeconds}s '
              '(query=${plan.queryKey.name})',
          userMessage:
              'A consulta multiagente demorou mais que o tempo permitido. '
              'Tente novamente.',
          context: <String, Object?>{
            'operation': 'agentQueryExecuteRace',
            'queryKey': plan.queryKey.name,
            'strategy': plan.strategy.name,
            'reason': 'race_total_timeout',
            'raceTotalTimeoutMs': raceTotalTimeout.inMilliseconds,
            'plannedTargetCount': plan.plannedTargets.length,
            'settledTargetCount': participantsByIndex.length,
            'failedCount': failedCount,
          },
        ),
      );
    }

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
          skippedDueToHubPresenceTargets: plan.skippedDueToHubPresenceTargets,
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
    } else if (plan.skippedOnlyDueToHubPresenceRules) {
      AppLogger.info(
        'Agent query produced no SQL targets after hub presence filtering',
        context: <String, Object?>{
          'queryKey': plan.queryKey.name,
          'strategy': plan.strategy.name,
          'consideredApprovedAgentCount': plan.consideredApprovedAgentCount,
        },
      );
    }
    return AgentQueryExecutionReport<Row>(
      queryKey: plan.queryKey,
      strategy: plan.strategy,
      consideredApprovedAgentCount: plan.consideredApprovedAgentCount,
      plannedTargets: plan.plannedTargets,
      missingClientTokenTargets: plan.missingClientTokenTargets,
      skippedDueToHubPresenceTargets: plan.skippedDueToHubPresenceTargets,
      participants: <AgentQueryExecutionParticipant<Row>>[],
      totalElapsedMs: totalElapsedMs,
    );
  }

  Future<
    ({AgentQueryExecutionParticipant<Row> participant, AppFailure? failure})
  >
  _loadParticipant({
    required AgentQueryTarget target,
    required AgentQueryLoadedRowsTargetLoader<Row> loadTarget,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await loadTarget(target);
      stopwatch.stop();

      return await result.fold(
        (loadedRows) => (
          participant: AgentQueryExecutionParticipant<Row>(
            agentId: target.agentId,
            displayName: target.displayName,
            rows: loadedRows.rows,
            sourceRowCount: loadedRows.sourceRowCount,
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
      final failure = mapAgentQueryToAppFailure(
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

class _RaceTimedOut<Row> extends _RaceDecision<Row> {}
