import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_plan.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_eligibility_policy.dart';
import 'package:result_dart/result_dart.dart';

class AgentQueryPlanBuilder {
  const AgentQueryPlanBuilder({
    AgentSqlExecutionEligibilityPolicy sqlPresencePolicy =
        const AgentSqlExecutionEligibilityPolicy(),
  }) : _sqlPresencePolicy = sqlPresencePolicy;

  static const int defaultBridgeTimeoutMs = 120000;
  static const int defaultRaceMaxSources = 4;

  final AgentSqlExecutionEligibilityPolicy _sqlPresencePolicy;

  AppResult<AgentQueryPlan> build({
    required AgentQueryKey queryKey,
    required AgentQueryExecutionStrategy strategy,
    required AgentQueryTargetResolution resolution,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  }) {
    final resolvedTimeoutMs = bridgeTimeoutMs ?? defaultBridgeTimeoutMs;
    if (resolvedTimeoutMs < 1) {
      return const Failure<AgentQueryPlan, AppFailure>(
        ValidationFailure(
          message: 'bridgeTimeoutMs must be >= 1',
          context: <String, Object?>{
            'operation': 'buildAgentQueryPlan',
            'field': 'bridgeTimeoutMs',
          },
        ),
      );
    }

    final consideredTargets = resolution.consideredApprovedTargets;
    final presenceSnapshot = resolution.hubPresenceOnlineAgentIdsSnapshot;
    final tokenReadyTargets = consideredTargets
        .where((target) => target.hasClientToken)
        .toList(growable: false);
    final plannedTargets = presenceSnapshot == null
        ? tokenReadyTargets
        : tokenReadyTargets
              .where(
                (target) => _sqlPresencePolicy.sqlAllowedForStatus(
                  target.connectionStatus,
                ),
              )
              .toList(growable: false);

    switch (strategy) {
      case AgentQueryExecutionStrategy.singleSource:
        if (consideredTargets.length != 1) {
          return Failure<AgentQueryPlan, AppFailure>(
            ValidationFailure(
              message: 'singleSource requires exactly one considered target',
              context: <String, Object?>{
                'operation': 'buildAgentQueryPlan',
                'strategy': strategy.name,
                'consideredTargetCount': consideredTargets.length,
              },
            ),
          );
        }
        return Success<AgentQueryPlan, AppFailure>(
          AgentQueryPlan(
            queryKey: queryKey,
            strategy: strategy,
            consideredApprovedAgentCount:
                resolution.consideredApprovedAgentCount,
            plannedTargets: plannedTargets,
            missingClientTokenTargets: resolution.missingClientTokenTargets,
            bridgeTimeoutMs: resolvedTimeoutMs,
          ),
        );
      case AgentQueryExecutionStrategy.mergeAll:
        return Success<AgentQueryPlan, AppFailure>(
          AgentQueryPlan(
            queryKey: queryKey,
            strategy: strategy,
            consideredApprovedAgentCount:
                resolution.consideredApprovedAgentCount,
            plannedTargets: plannedTargets,
            missingClientTokenTargets: resolution.missingClientTokenTargets,
            bridgeTimeoutMs: resolvedTimeoutMs,
          ),
        );
      case AgentQueryExecutionStrategy.race:
        final resolvedRaceMaxSources = raceMaxSources ?? defaultRaceMaxSources;
        if (resolvedRaceMaxSources < 1) {
          return const Failure<AgentQueryPlan, AppFailure>(
            ValidationFailure(
              message: 'raceMaxSources must be >= 1',
              context: <String, Object?>{
                'operation': 'buildAgentQueryPlan',
                'field': 'raceMaxSources',
              },
            ),
          );
        }
        return Success<AgentQueryPlan, AppFailure>(
          AgentQueryPlan(
            queryKey: queryKey,
            strategy: strategy,
            consideredApprovedAgentCount:
                resolution.consideredApprovedAgentCount,
            plannedTargets: plannedTargets
                .take(resolvedRaceMaxSources)
                .toList(growable: false),
            missingClientTokenTargets: resolution.missingClientTokenTargets,
            bridgeTimeoutMs: resolvedTimeoutMs,
            raceMaxSources: resolvedRaceMaxSources,
          ),
        );
    }
  }
}
