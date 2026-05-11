import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_loaded_rows.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_plan.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:result_dart/result_dart.dart';

/// Shared orchestration for list-row agent queries executed across agents.
abstract final class AgentQueryListReportAcrossAgentsCoordinator {
  static const String _sourceAgentIdsContextField = 'sourceAgentIds';

  static Future<AppResult<AgentQueryExecutionReport<Row>>>
  execute<Filter, Row>({
    required String operation,
    required AgentQueryKey queryKey,
    required String userId,
    required Filter filter,
    required AgentQueryTargetResolver targetResolver,
    required AgentQueryPlanBuilder planBuilder,
    required AgentQueryExecutor<Row> executor,
    required Future<AppResult<List<Row>>> Function({
      required String userId,
      required String agentId,
      required Filter filter,
      String? clientToken,
      int? bridgeTimeoutMs,
      Set<String>? hubPresenceOnlineAgentIdsSnapshot,
      bool? hubConnectedFromApprovedCatalogRow,
    })
    loadRowsForTarget,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  }) async {
    return executeMapped<AgentQueryExecutionReport<Row>, Row>(
      operation: operation,
      queryKey: queryKey,
      userId: userId,
      targetResolver: targetResolver,
      planBuilder: planBuilder,
      executor: executor,
      selectedAgentIds: selectedAgentIds,
      strategy: strategy,
      bridgeTimeoutMs: bridgeTimeoutMs,
      raceMaxSources: raceMaxSources,
      loadRowsForTarget:
          ({
            required target,
            required plan,
            required resolution,
          }) {
            return loadRowsForTarget(
              userId: userId,
              agentId: target.agentId,
              filter: filter,
              clientToken: target.clientToken,
              bridgeTimeoutMs: plan.bridgeTimeoutMs,
              hubPresenceOnlineAgentIdsSnapshot:
                  resolution.hubPresenceOnlineAgentIdsSnapshot,
              hubConnectedFromApprovedCatalogRow:
                  target.hubConnectedFromApprovedCatalogRow,
            );
          },
      mapReport: (report) => report,
    );
  }

  static Future<AppResult<AgentQueryExecutionReport<Row>>>
  executeLoadedRows<Filter, Row>({
    required String operation,
    required AgentQueryKey queryKey,
    required String userId,
    required Filter filter,
    required AgentQueryTargetResolver targetResolver,
    required AgentQueryPlanBuilder planBuilder,
    required AgentQueryExecutor<Row> executor,
    required Future<AppResult<AgentQueryLoadedRows<Row>>> Function({
      required String userId,
      required String agentId,
      required Filter filter,
      String? clientToken,
      int? bridgeTimeoutMs,
      Set<String>? hubPresenceOnlineAgentIdsSnapshot,
      bool? hubConnectedFromApprovedCatalogRow,
    })
    loadRowsForTarget,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  }) async {
    return executeLoadedMapped<AgentQueryExecutionReport<Row>, Row>(
      operation: operation,
      queryKey: queryKey,
      userId: userId,
      targetResolver: targetResolver,
      planBuilder: planBuilder,
      executor: executor,
      selectedAgentIds: selectedAgentIds,
      strategy: strategy,
      bridgeTimeoutMs: bridgeTimeoutMs,
      raceMaxSources: raceMaxSources,
      loadRowsForTarget:
          ({
            required target,
            required plan,
            required resolution,
          }) {
            return loadRowsForTarget(
              userId: userId,
              agentId: target.agentId,
              filter: filter,
              clientToken: target.clientToken,
              bridgeTimeoutMs: plan.bridgeTimeoutMs,
              hubPresenceOnlineAgentIdsSnapshot:
                  resolution.hubPresenceOnlineAgentIdsSnapshot,
              hubConnectedFromApprovedCatalogRow:
                  target.hubConnectedFromApprovedCatalogRow,
            );
          },
      mapReport: (report) => report,
    );
  }

  static Future<AppResult<Output>> executeMapped<Output extends Object, Row>({
    required String operation,
    required AgentQueryKey queryKey,
    required String userId,
    required AgentQueryTargetResolver targetResolver,
    required AgentQueryPlanBuilder planBuilder,
    required AgentQueryExecutor<Row> executor,
    required Future<AppResult<List<Row>>> Function({
      required AgentQueryTarget target,
      required AgentQueryPlan plan,
      required AgentQueryTargetResolution resolution,
    })
    loadRowsForTarget,
    required Output Function(AgentQueryExecutionReport<Row> report) mapReport,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
    String successLogMessage = 'Agent query executed across agents',
    Map<String, Object?> Function(
      AgentQueryExecutionReport<Row> report,
      Output mapped,
    )?
    successContext,
  }) async {
    return executeLoadedMapped<Output, Row>(
      operation: operation,
      queryKey: queryKey,
      userId: userId,
      targetResolver: targetResolver,
      planBuilder: planBuilder,
      executor: executor,
      selectedAgentIds: selectedAgentIds,
      strategy: strategy,
      bridgeTimeoutMs: bridgeTimeoutMs,
      raceMaxSources: raceMaxSources,
      loadRowsForTarget:
          ({
            required target,
            required plan,
            required resolution,
          }) async {
            final result = await loadRowsForTarget(
              target: target,
              plan: plan,
              resolution: resolution,
            );
            return result.fold(
              (rows) => Success<AgentQueryLoadedRows<Row>, AppFailure>(
                AgentQueryLoadedRows<Row>(rows: rows),
              ),
              Failure<AgentQueryLoadedRows<Row>, AppFailure>.new,
            );
          },
      mapReport: mapReport,
      successLogMessage: successLogMessage,
      successContext: successContext,
    );
  }

  static Future<AppResult<Output>>
  executeLoadedMapped<Output extends Object, Row>({
    required String operation,
    required AgentQueryKey queryKey,
    required String userId,
    required AgentQueryTargetResolver targetResolver,
    required AgentQueryPlanBuilder planBuilder,
    required AgentQueryExecutor<Row> executor,
    required Future<AppResult<AgentQueryLoadedRows<Row>>> Function({
      required AgentQueryTarget target,
      required AgentQueryPlan plan,
      required AgentQueryTargetResolution resolution,
    })
    loadRowsForTarget,
    required Output Function(AgentQueryExecutionReport<Row> report) mapReport,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
    String successLogMessage = 'Agent query executed across agents',
    Map<String, Object?> Function(
      AgentQueryExecutionReport<Row> report,
      Output mapped,
    )?
    successContext,
  }) async {
    final resolutionResult = await targetResolver.resolve(
      userId: userId,
      selectedAgentIds: selectedAgentIds,
    );
    final resolution = resolutionResult.getOrNull();
    if (resolution == null) {
      final failure = appFailureWithMergedContext(
        resolutionResult.exceptionOrNull()!,
        _resolutionContext(null),
      );
      AppLogger.warning(
        'Agent query target resolution failed',
        context: <String, Object?>{
          'operation': operation,
          'userId': userId,
          'queryKey': queryKey.name,
          'strategy': strategy.name,
          'selectedAgentCount': selectedAgentIds?.length ?? 0,
          'failureType': failure.runtimeType.toString(),
        },
        error: failure,
        stackTrace: failure.stackTrace,
      );
      return Failure<Output, AppFailure>(failure);
    }

    final planResult = planBuilder.build(
      queryKey: queryKey,
      strategy: strategy,
      resolution: resolution,
      bridgeTimeoutMs: bridgeTimeoutMs,
      raceMaxSources: raceMaxSources,
    );
    final plan = planResult.getOrNull();
    if (plan == null) {
      final failure = appFailureWithMergedContext(
        planResult.exceptionOrNull()!,
        _resolutionContext(resolution),
      );
      AppLogger.warning(
        'Agent query plan build failed',
        context: <String, Object?>{
          'operation': operation,
          'userId': userId,
          'queryKey': queryKey.name,
          'strategy': strategy.name,
          'consideredApprovedAgentCount':
              resolution.consideredApprovedAgentCount,
          'sqlEligibleConsideredTargetCount':
              resolution.sqlEligibleConsideredTargetCount,
          'skippedDueToHubPresenceCount':
              resolution.skippedDueToHubPresenceTargets.length,
          'missingClientTokenCount':
              resolution.missingClientTokenTargets.length,
          'failureType': failure.runtimeType.toString(),
        },
        error: failure,
        stackTrace: failure.stackTrace,
      );
      return Failure<Output, AppFailure>(failure);
    }

    final executionResult = await executor.executeLoadedRows(
      plan: plan,
      loadTarget: (target) => loadRowsForTarget(
        target: target,
        plan: plan,
        resolution: resolution,
      ),
    );
    final report = executionResult.getOrNull();
    if (report != null) {
      final mapped = mapReport(report);
      AppLogger.info(
        successLogMessage,
        context: <String, Object?>{
          ..._executionContext(
            operation: operation,
            userId: userId,
            strategy: strategy,
            report: report,
          ),
          'failedAgentCount': report.failedAgentIds.length,
          'missingClientTokenCount': report.missingClientTokenAgentIds.length,
          'hasPartialFailure': report.hasPartialFailure,
          'skippedDueToHubPresenceCount':
              resolution.skippedDueToHubPresenceTargets.length,
          'sqlEligibleConsideredTargetCount':
              resolution.sqlEligibleConsideredTargetCount,
          if (successContext != null) ...successContext(report, mapped),
        },
      );
      return Success<Output, AppFailure>(mapped);
    }

    final failure = appFailureWithMergedContext(
      executionResult.exceptionOrNull()!,
      _planContext(operation: operation, userId: userId, plan: plan),
    );
    AppLogger.warning(
      'Agent query execution failed',
      context: <String, Object?>{
        ..._planContext(operation: operation, userId: userId, plan: plan),
        'failureType': failure.runtimeType.toString(),
      },
      error: failure,
      stackTrace: failure.stackTrace,
    );
    return Failure<Output, AppFailure>(failure);
  }

  static Map<String, Object?> _executionContext<Row>({
    required String operation,
    required String userId,
    required AgentQueryExecutionStrategy strategy,
    required AgentQueryExecutionReport<Row> report,
  }) {
    return <String, Object?>{
      'operation': operation,
      'userId': userId,
      'queryKey': report.queryKey.name,
      'strategy': strategy.name,
      'consideredApprovedAgentCount': report.consideredApprovedAgentCount,
      'plannedTargetCount': report.plannedTargets.length,
      'failedAgentIds': report.failedAgentIds.join(', '),
      'missingClientTokenAgentIds': report.missingClientTokenAgentIds.join(
        ', ',
      ),
      'winnerAgentId': report.winnerAgentId,
      'totalElapsedMs': report.totalElapsedMs,
    };
  }

  static Map<String, Object?> _planContext({
    required String operation,
    required String userId,
    required AgentQueryPlan plan,
  }) {
    final sourceAgentIds = _sourceAgentIds(
      plannedTargets: plan.plannedTargets,
      missingClientTokenTargets: plan.missingClientTokenTargets,
    );
    return <String, Object?>{
      'operation': operation,
      'userId': userId,
      'queryKey': plan.queryKey.name,
      'strategy': plan.strategy.name,
      'consideredApprovedAgentCount': plan.consideredApprovedAgentCount,
      'plannedTargetCount': plan.plannedTargets.length,
      'missingClientTokenCount': plan.missingClientTokenTargets.length,
      _sourceAgentIdsContextField: sourceAgentIds,
    };
  }

  static Map<String, Object?> _resolutionContext(
    AgentQueryTargetResolution? resolution,
  ) {
    final sourceAgentIds = resolution == null
        ? const <String>[]
        : _sourceAgentIds(
            plannedTargets: resolution.consideredApprovedTargets,
            missingClientTokenTargets: resolution.missingClientTokenTargets,
          );
    return <String, Object?>{
      _sourceAgentIdsContextField: sourceAgentIds,
    };
  }

  static List<String> _sourceAgentIds({
    required List<AgentQueryTarget> plannedTargets,
    required List<AgentQueryTarget> missingClientTokenTargets,
  }) {
    return <String>{
      for (final target in plannedTargets) target.agentId,
      for (final target in missingClientTokenTargets) target.agentId,
    }.toList(growable: false)..sort();
  }
}
