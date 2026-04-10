import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_use_case.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_plan.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_across_agents_repository.dart';
import 'package:result_dart/result_dart.dart';

class ResumoParcelaFormaPagamentoAcrossAgentsRepositoryImpl
    implements ResumoParcelaFormaPagamentoAcrossAgentsRepository {
  ResumoParcelaFormaPagamentoAcrossAgentsRepositoryImpl({
    required AgentQueryTargetResolver targetResolver,
    required AgentQueryPlanBuilder planBuilder,
    required AgentQueryExecutor<ResumoParcelaFormaPagamentoRow> executor,
    required LoadResumoParcelaFormaPagamentoUseCase loadResumo,
  }) : _targetResolver = targetResolver,
       _planBuilder = planBuilder,
       _executor = executor,
       _loadResumo = loadResumo;

  final AgentQueryTargetResolver _targetResolver;
  final AgentQueryPlanBuilder _planBuilder;
  final AgentQueryExecutor<ResumoParcelaFormaPagamentoRow> _executor;
  final LoadResumoParcelaFormaPagamentoUseCase _loadResumo;

  static const String _sourceAgentIdsContextField = 'sourceAgentIds';

  @override
  Future<AppResult<AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>>>
  load({
    required String userId,
    required ResumoParcelaFormaPagamentoFilter filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  }) async {
    final resolutionResult = await _targetResolver.resolve(
      userId: userId,
      selectedAgentIds: selectedAgentIds,
    );
    final resolution = resolutionResult.getOrNull();
    if (resolution == null) {
      final failure = _withFailureContext(
        resolutionResult.exceptionOrNull()!,
        _buildResolutionContext(null),
      );
      AppLogger.warning(
        'Agent query target resolution failed',
        context: <String, Object?>{
          'operation': 'loadResumoAcrossAgents',
          'userId': userId,
          'queryKey': AgentQueryKey.resumoParcelaFormaPagamento.name,
          'strategy': strategy.name,
          'selectedAgentCount': selectedAgentIds?.length ?? 0,
          'failureType': failure.runtimeType.toString(),
        },
        error: failure,
        stackTrace: failure.stackTrace,
      );
      return Failure<
        AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
        AppFailure
      >(failure);
    }

    final planResult = _planBuilder.build(
      queryKey: AgentQueryKey.resumoParcelaFormaPagamento,
      strategy: strategy,
      resolution: resolution,
      bridgeTimeoutMs: bridgeTimeoutMs,
      raceMaxSources: raceMaxSources,
    );
    final plan = planResult.getOrNull();
    if (plan == null) {
      final failure = _withFailureContext(
        planResult.exceptionOrNull()!,
        _buildResolutionContext(resolution),
      );
      AppLogger.warning(
        'Agent query plan build failed',
        context: <String, Object?>{
          'operation': 'loadResumoAcrossAgents',
          'userId': userId,
          'queryKey': AgentQueryKey.resumoParcelaFormaPagamento.name,
          'strategy': strategy.name,
          'consideredApprovedAgentCount':
              resolution.consideredApprovedAgentCount,
          'missingClientTokenCount':
              resolution.missingClientTokenTargets.length,
          'failureType': failure.runtimeType.toString(),
        },
        error: failure,
        stackTrace: failure.stackTrace,
      );
      return Failure<
        AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
        AppFailure
      >(failure);
    }

    final executionResult = await _executor.execute(
      plan: plan,
      loadTarget: (target) {
        return _loadResumo(
          agentId: target.agentId,
          filter: filter,
          clientToken: target.clientToken,
          bridgeTimeoutMs: plan.bridgeTimeoutMs,
        );
      },
    );
    final report = executionResult.getOrNull();
    if (report != null) {
      AppLogger.info(
        'Agent query executed across agents',
        context: <String, Object?>{
          ..._buildExecutionContext(
            userId: userId,
            strategy: strategy,
            report: report,
          ),
          'failedAgentCount': report.failedAgentIds.length,
          'missingClientTokenCount': report.missingClientTokenAgentIds.length,
          'hasPartialFailure': report.hasPartialFailure,
        },
      );
      return Success<
        AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
        AppFailure
      >(report);
    }

    final failure = _withFailureContext(
      executionResult.exceptionOrNull()!,
      _buildPlanContext(userId: userId, plan: plan),
    );
    AppLogger.warning(
      'Agent query execution failed',
      context: <String, Object?>{
        ..._buildPlanContext(userId: userId, plan: plan),
        'failureType': failure.runtimeType.toString(),
      },
      error: failure,
      stackTrace: failure.stackTrace,
    );
    return Failure<
      AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
      AppFailure
    >(failure);
  }

  Map<String, Object?> _buildExecutionContext({
    required String userId,
    required AgentQueryExecutionStrategy strategy,
    required AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow> report,
  }) {
    return <String, Object?>{
      'operation': 'loadResumoAcrossAgents',
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

  Map<String, Object?> _buildPlanContext({
    required String userId,
    required AgentQueryPlan plan,
  }) {
    final sourceAgentIds = _resolveSourceAgentIds(
      plannedTargets: plan.plannedTargets,
      missingClientTokenTargets: plan.missingClientTokenTargets,
    );
    return <String, Object?>{
      'operation': 'loadResumoAcrossAgents',
      'userId': userId,
      'queryKey': plan.queryKey.name,
      'strategy': plan.strategy.name,
      'consideredApprovedAgentCount': plan.consideredApprovedAgentCount,
      'plannedTargetCount': plan.plannedTargets.length,
      'missingClientTokenCount': plan.missingClientTokenTargets.length,
      _sourceAgentIdsContextField: sourceAgentIds,
    };
  }

  Map<String, Object?> _buildResolutionContext(
    AgentQueryTargetResolution? resolution,
  ) {
    final sourceAgentIds = resolution == null
        ? const <String>[]
        : _resolveSourceAgentIds(
            plannedTargets: resolution.consideredApprovedTargets,
            missingClientTokenTargets: resolution.missingClientTokenTargets,
          );
    return <String, Object?>{
      _sourceAgentIdsContextField: sourceAgentIds,
    };
  }

  List<String> _resolveSourceAgentIds({
    required List<AgentQueryTarget> plannedTargets,
    required List<AgentQueryTarget> missingClientTokenTargets,
  }) {
    return <String>{
      for (final target in plannedTargets) target.agentId,
      for (final target in missingClientTokenTargets) target.agentId,
    }.toList(growable: false)..sort();
  }

  AppFailure _withFailureContext(
    AppFailure failure,
    Map<String, Object?> extraContext,
  ) {
    final mergedContext = <String, Object?>{
      ...failure.context,
      ...extraContext,
    };

    return switch (failure) {
      ValidationFailure() => ValidationFailure(
        message: failure.message,
        userMessage: failure.userMessage,
        cause: failure.cause,
        stackTrace: failure.stackTrace,
        context: mergedContext,
      ),
      SessionFailure() => SessionFailure(
        message: failure.message,
        userMessage: failure.userMessage,
        cause: failure.cause,
        stackTrace: failure.stackTrace,
        context: mergedContext,
      ),
      AuthorizationFailure() => AuthorizationFailure(
        message: failure.message,
        userMessage: failure.userMessage,
        cause: failure.cause,
        stackTrace: failure.stackTrace,
        context: mergedContext,
      ),
      StorageFailure() => StorageFailure(
        message: failure.message,
        userMessage: failure.userMessage,
        cause: failure.cause,
        stackTrace: failure.stackTrace,
        context: mergedContext,
      ),
      NetworkFailure() => NetworkFailure(
        message: failure.message,
        userMessage: failure.userMessage,
        cause: failure.cause,
        stackTrace: failure.stackTrace,
        context: mergedContext,
        isTransient: failure.isTransient,
      ),
      RpcFailure() => RpcFailure(
        message: failure.message,
        userMessage: failure.userMessage ?? failure.message,
        rpcCode: failure.rpcCode,
        retryable: failure.retryable,
        reason: failure.reason,
        category: failure.category,
        technicalMessage: failure.technicalMessage,
        correlationId: failure.correlationId,
        timestamp: failure.timestamp,
        cause: failure.cause,
        stackTrace: failure.stackTrace,
        context: mergedContext,
      ),
      UnknownFailure() => UnknownFailure(
        message: failure.message,
        userMessage: failure.userMessage,
        cause: failure.cause,
        stackTrace: failure.stackTrace,
        context: mergedContext,
      ),
    };
  }
}
