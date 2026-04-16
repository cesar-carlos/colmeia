import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_bairro_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_municipio_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_vendedor_options_use_case.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_filter_options_merger.dart';
import 'package:colmeia/features/agent_queries/data/resumo_vendas_diarias_suggestion_sql_params.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_plan.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_text_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_vendedor_option.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_filter_options_across_agents_repository.dart';
import 'package:result_dart/result_dart.dart';

class ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepositoryImpl
    implements
        ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository {
  ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepositoryImpl({
    required AgentQueryTargetResolver targetResolver,
    required AgentQueryPlanBuilder planBuilder,
    required AgentQueryExecutor<ResumoVendasDiariasPorVendedorVendedorOption>
    vendedorExecutor,
    required AgentQueryExecutor<ResumoVendasDiariasPorVendedorTextOption>
    textExecutor,
    required LoadResumoVendasDiariasPorVendedorVendedorOptionsUseCase
    loadVendedorOptions,
    required LoadResumoVendasDiariasPorVendedorBairroOptionsUseCase
    loadBairroOptions,
    required LoadResumoVendasDiariasPorVendedorMunicipioOptionsUseCase
    loadMunicipioOptions,
  }) : _targetResolver = targetResolver,
       _planBuilder = planBuilder,
       _vendedorExecutor = vendedorExecutor,
       _textExecutor = textExecutor,
       _loadVendedorOptions = loadVendedorOptions,
       _loadBairroOptions = loadBairroOptions,
       _loadMunicipioOptions = loadMunicipioOptions;

  final AgentQueryTargetResolver _targetResolver;
  final AgentQueryPlanBuilder _planBuilder;
  final AgentQueryExecutor<ResumoVendasDiariasPorVendedorVendedorOption>
  _vendedorExecutor;
  final AgentQueryExecutor<ResumoVendasDiariasPorVendedorTextOption>
  _textExecutor;
  final LoadResumoVendasDiariasPorVendedorVendedorOptionsUseCase
  _loadVendedorOptions;
  final LoadResumoVendasDiariasPorVendedorBairroOptionsUseCase
  _loadBairroOptions;
  final LoadResumoVendasDiariasPorVendedorMunicipioOptionsUseCase
  _loadMunicipioOptions;

  static const String _sourceAgentIdsContextField = 'sourceAgentIds';
  static const String _operation =
      'loadResumoVendasDiariasPorVendedorOptionsAcrossAgents';

  @override
  Future<AppResult<List<ResumoVendasDiariasPorVendedorVendedorOption>>>
  loadVendedorOptions({
    required String userId,
    required DateTime dataVendaInicio,
    required DateTime dataVendaFim,
    Set<String>? selectedAgentIds,
    String? searchTerm,
    int limit = ResumoVendasDiariasSuggestionSqlParams.defaultLimit,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  }) {
    final effectiveLimit = ResumoVendasDiariasSuggestionSqlParams.clampLimit(
      limit,
    );
    return _runAcross(
      userId: userId,
      dataVendaInicio: dataVendaInicio,
      dataVendaFim: dataVendaFim,
      selectedAgentIds: selectedAgentIds,
      searchTerm: searchTerm,
      limit: effectiveLimit,
      strategy: strategy,
      bridgeTimeoutMs: bridgeTimeoutMs,
      raceMaxSources: raceMaxSources,
      queryKey: AgentQueryKey.resumoVendasDiariasOptsVendedor,
      executor: _vendedorExecutor,
      loadForTarget: (target, timeoutMs, sqlFetchLimit, resolution) =>
          _loadVendedorOptions(
            userId: userId,
            agentId: target.agentId,
            dataVendaInicio: dataVendaInicio,
            dataVendaFim: dataVendaFim,
            searchTerm: searchTerm,
            limit: sqlFetchLimit,
            clientToken: target.clientToken,
            bridgeTimeoutMs: timeoutMs,
            hubPresenceOnlineAgentIdsSnapshot:
                resolution.hubPresenceOnlineAgentIdsSnapshot,
            hubConnectedFromApprovedCatalogRow:
                target.hubConnectedFromApprovedCatalogRow,
          ),
      postProcess: (merged) =>
          _postDedupeVendedorOptions(merged, effectiveLimit),
    );
  }

  @override
  Future<AppResult<List<ResumoVendasDiariasPorVendedorTextOption>>>
  loadBairroOptions({
    required String userId,
    required DateTime dataVendaInicio,
    required DateTime dataVendaFim,
    Set<String>? selectedAgentIds,
    String? searchTerm,
    int limit = ResumoVendasDiariasSuggestionSqlParams.defaultLimit,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  }) {
    final effectiveLimit = ResumoVendasDiariasSuggestionSqlParams.clampLimit(
      limit,
    );
    return _runAcross(
      userId: userId,
      dataVendaInicio: dataVendaInicio,
      dataVendaFim: dataVendaFim,
      selectedAgentIds: selectedAgentIds,
      searchTerm: searchTerm,
      limit: effectiveLimit,
      strategy: strategy,
      bridgeTimeoutMs: bridgeTimeoutMs,
      raceMaxSources: raceMaxSources,
      queryKey: AgentQueryKey.resumoVendasDiariasOptsBairro,
      executor: _textExecutor,
      loadForTarget: (target, timeoutMs, sqlFetchLimit, resolution) =>
          _loadBairroOptions(
            userId: userId,
            agentId: target.agentId,
            dataVendaInicio: dataVendaInicio,
            dataVendaFim: dataVendaFim,
            searchTerm: searchTerm,
            limit: sqlFetchLimit,
            clientToken: target.clientToken,
            bridgeTimeoutMs: timeoutMs,
            hubPresenceOnlineAgentIdsSnapshot:
                resolution.hubPresenceOnlineAgentIdsSnapshot,
            hubConnectedFromApprovedCatalogRow:
                target.hubConnectedFromApprovedCatalogRow,
          ),
      postProcess: (merged) => _postDedupeTextOptions(merged, effectiveLimit),
    );
  }

  @override
  Future<AppResult<List<ResumoVendasDiariasPorVendedorTextOption>>>
  loadMunicipioOptions({
    required String userId,
    required DateTime dataVendaInicio,
    required DateTime dataVendaFim,
    Set<String>? selectedAgentIds,
    String? searchTerm,
    int limit = ResumoVendasDiariasSuggestionSqlParams.defaultLimit,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  }) {
    final effectiveLimit = ResumoVendasDiariasSuggestionSqlParams.clampLimit(
      limit,
    );
    return _runAcross(
      userId: userId,
      dataVendaInicio: dataVendaInicio,
      dataVendaFim: dataVendaFim,
      selectedAgentIds: selectedAgentIds,
      searchTerm: searchTerm,
      limit: effectiveLimit,
      strategy: strategy,
      bridgeTimeoutMs: bridgeTimeoutMs,
      raceMaxSources: raceMaxSources,
      queryKey: AgentQueryKey.resumoVendasDiariasOptsMunicipio,
      executor: _textExecutor,
      loadForTarget: (target, timeoutMs, sqlFetchLimit, resolution) =>
          _loadMunicipioOptions(
            userId: userId,
            agentId: target.agentId,
            dataVendaInicio: dataVendaInicio,
            dataVendaFim: dataVendaFim,
            searchTerm: searchTerm,
            limit: sqlFetchLimit,
            clientToken: target.clientToken,
            bridgeTimeoutMs: timeoutMs,
            hubPresenceOnlineAgentIdsSnapshot:
                resolution.hubPresenceOnlineAgentIdsSnapshot,
            hubConnectedFromApprovedCatalogRow:
                target.hubConnectedFromApprovedCatalogRow,
          ),
      postProcess: (merged) => _postDedupeTextOptions(merged, effectiveLimit),
    );
  }

  Future<AppResult<List<T>>> _runAcross<T>({
    required String userId,
    required DateTime dataVendaInicio,
    required DateTime dataVendaFim,
    required Set<String>? selectedAgentIds,
    required String? searchTerm,
    required int limit,
    required AgentQueryExecutionStrategy strategy,
    required int? bridgeTimeoutMs,
    required int? raceMaxSources,
    required AgentQueryKey queryKey,
    required AgentQueryExecutor<T> executor,
    required Future<AppResult<List<T>>> Function(
      AgentQueryTarget target,
      int bridgeTimeoutMs,
      int sqlFetchLimit,
      AgentQueryTargetResolution resolution,
    )
    loadForTarget,
    required List<T> Function(List<T> merged) postProcess,
  }) async {
    final rangeError = ResumoVendasDiariasSuggestionSqlParams.validateDateRange(
      dataVendaInicio: dataVendaInicio,
      dataVendaFim: dataVendaFim,
    );
    if (rangeError != null) {
      return Failure<List<T>, AppFailure>(
        ValidationFailure(
          message: rangeError,
          userMessage: 'Os filtros da consulta sao invalidos.',
          context: <String, Object?>{
            'operation': _operation,
            'userId': userId,
            'queryKey': queryKey.name,
          },
        ),
      );
    }

    final resolutionResult = await _targetResolver.resolve(
      userId: userId,
      selectedAgentIds: selectedAgentIds,
    );
    final resolution = resolutionResult.getOrNull();
    if (resolution == null) {
      final failure = appFailureWithMergedContext(
        resolutionResult.exceptionOrNull()!,
        _buildResolutionContext(null),
      );
      AppLogger.warning(
        'Agent query target resolution failed',
        context: <String, Object?>{
          'operation': _operation,
          'userId': userId,
          'queryKey': queryKey.name,
          'strategy': strategy.name,
          'selectedAgentCount': selectedAgentIds?.length ?? 0,
          'failureType': failure.runtimeType.toString(),
        },
        error: failure,
        stackTrace: failure.stackTrace,
      );
      return Failure<List<T>, AppFailure>(failure);
    }

    final planResult = _planBuilder.build(
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
        _buildResolutionContext(resolution),
      );
      AppLogger.warning(
        'Agent query plan build failed',
        context: <String, Object?>{
          'operation': _operation,
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
      return Failure<List<T>, AppFailure>(failure);
    }

    final perAgentFetchLimit =
        ResumoVendasDiariasSuggestionSqlParams.perAgentSuggestionFetchLimit(
          mergeResultLimit: limit,
          plannedTargetCount: plan.plannedTargets.length,
        );

    final executionResult = await executor.execute(
      plan: plan,
      loadTarget: (target) {
        return loadForTarget(
          target,
          plan.bridgeTimeoutMs,
          perAgentFetchLimit,
          resolution,
        );
      },
    );
    final report = executionResult.getOrNull();
    if (report != null) {
      final processed = postProcess(report.mergedRows);
      AppLogger.info(
        'Agent query options executed across agents',
        context: <String, Object?>{
          'operation': _operation,
          'userId': userId,
          'queryKey': report.queryKey.name,
          'strategy': strategy.name,
          'mergedOptionCount': processed.length,
          'failedAgentCount': report.failedAgentIds.length,
          'missingClientTokenCount': report.missingClientTokenAgentIds.length,
          'hasPartialFailure': report.hasPartialFailure,
        },
      );
      return Success<List<T>, AppFailure>(processed);
    }

    final failure = appFailureWithMergedContext(
      executionResult.exceptionOrNull()!,
      _buildPlanContext(userId: userId, plan: plan),
    );
    AppLogger.warning(
      'Agent query options execution failed',
      context: <String, Object?>{
        ..._buildPlanContext(userId: userId, plan: plan),
        'failureType': failure.runtimeType.toString(),
      },
      error: failure,
      stackTrace: failure.stackTrace,
    );
    return Failure<List<T>, AppFailure>(failure);
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
      'operation': _operation,
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
}

List<ResumoVendasDiariasPorVendedorVendedorOption> _postDedupeVendedorOptions(
  List<ResumoVendasDiariasPorVendedorVendedorOption> merged,
  int effectiveLimit,
) {
  final deduped =
      ResumoVendasDiariasPorVendedorFilterOptionsMerger.dedupeVendedorOptions(
        merged,
        effectiveLimit,
      );
  return deduped;
}

List<ResumoVendasDiariasPorVendedorTextOption> _postDedupeTextOptions(
  List<ResumoVendasDiariasPorVendedorTextOption> merged,
  int effectiveLimit,
) {
  return ResumoVendasDiariasPorVendedorFilterOptionsMerger.dedupeTextOptions(
    merged,
    effectiveLimit,
  );
}
