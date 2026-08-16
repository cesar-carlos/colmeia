import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_bairro_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_municipio_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_vendedor_options_use_case.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_query_list_report_across_agents_coordinator.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_filter_options_merger.dart';
import 'package:colmeia/features/agent_queries/data/resumo_vendas_diarias_suggestion_sql_params.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_filter_options_batch.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_text_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_vendedor_option.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_filter_options_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_filter_options_repository.dart';
import 'package:result_dart/result_dart.dart';

class ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepositoryImpl
    implements
        ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository {
  ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepositoryImpl({
    required this._targetResolver,
    required this._planBuilder,
    required this._vendedorExecutor,
    required this._textExecutor,
    required this._allOptionsBatchExecutor,
    required this._filterOptionsRepository,
    required this._loadVendedorOptions,
    required this._loadBairroOptions,
    required this._loadMunicipioOptions,
  });

  final AgentQueryTargetResolver _targetResolver;
  final AgentQueryPlanBuilder _planBuilder;
  final AgentQueryExecutor<ResumoVendasDiariasPorVendedorVendedorOption>
  _vendedorExecutor;
  final AgentQueryExecutor<ResumoVendasDiariasPorVendedorTextOption>
  _textExecutor;
  final AgentQueryExecutor<
    ResumoVendasDiariasPorVendedorFilterOptionsPerAgentBatch
  >
  _allOptionsBatchExecutor;
  final ResumoVendasDiariasPorVendedorFilterOptionsRepository
  _filterOptionsRepository;
  final LoadResumoVendasDiariasPorVendedorVendedorOptionsUseCase
  _loadVendedorOptions;
  final LoadResumoVendasDiariasPorVendedorBairroOptionsUseCase
  _loadBairroOptions;
  final LoadResumoVendasDiariasPorVendedorMunicipioOptionsUseCase
  _loadMunicipioOptions;

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

  @override
  Future<AppResult<ResumoVendasDiariasPorVendedorAllFilterOptionsAcrossAgents>>
  loadAllOptions({
    required String userId,
    required DateTime dataVendaInicio,
    required DateTime dataVendaFim,
    Set<String>? selectedAgentIds,
    String? searchTerm,
    int limit = ResumoVendasDiariasSuggestionSqlParams.defaultLimit,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  }) async {
    final effectiveLimit = ResumoVendasDiariasSuggestionSqlParams.clampLimit(
      limit,
    );
    final rangeError = ResumoVendasDiariasSuggestionSqlParams.validateDateRange(
      dataVendaInicio: dataVendaInicio,
      dataVendaFim: dataVendaFim,
    );
    if (rangeError != null) {
      return Failure<
        ResumoVendasDiariasPorVendedorAllFilterOptionsAcrossAgents,
        AppFailure
      >(
        ValidationFailure(
          message: rangeError,
          userMessage: 'Os filtros da consulta sao invalidos.',
          context: <String, Object?>{
            'operation': _operation,
            'userId': userId,
            'queryKey': AgentQueryKey.resumoVendasDiariasOptsBatch.name,
          },
        ),
      );
    }

    return AgentQueryListReportAcrossAgentsCoordinator.executeMapped<
      ResumoVendasDiariasPorVendedorAllFilterOptionsAcrossAgents,
      ResumoVendasDiariasPorVendedorFilterOptionsPerAgentBatch
    >(
      operation:
          'loadResumoVendasDiariasPorVendedorAllFilterOptionsAcrossAgents',
      queryKey: AgentQueryKey.resumoVendasDiariasOptsBatch,
      userId: userId,
      targetResolver: _targetResolver,
      planBuilder: _planBuilder,
      executor: _allOptionsBatchExecutor,
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
            final perAgentFetchLimit =
                ResumoVendasDiariasSuggestionSqlParams.perAgentSuggestionFetchLimit(
                  mergeResultLimit: effectiveLimit,
                  plannedTargetCount: plan.plannedTargets.length,
                );
            final batchResult = await _filterOptionsRepository
                .loadAllFilterOptions(
                  userId: userId,
                  agentId: target.agentId,
                  dataVendaInicio: dataVendaInicio,
                  dataVendaFim: dataVendaFim,
                  searchTerm: searchTerm,
                  limit: perAgentFetchLimit,
                  clientToken: target.clientToken,
                  bridgeTimeoutMs: plan.bridgeTimeoutMs,
                  hubPresenceOnlineAgentIdsSnapshot:
                      resolution.hubPresenceOnlineAgentIdsSnapshot,
                  hubConnectedFromApprovedCatalogRow:
                      target.hubConnectedFromApprovedCatalogRow,
                );
            return batchResult.map(
              (bundle) =>
                  <ResumoVendasDiariasPorVendedorFilterOptionsPerAgentBatch>[
                    bundle,
                  ],
            );
          },
      mapReport: (report) {
        final merged = report.mergedRows;
        final allVendedor = merged
            .expand((b) => b.vendedorOptions)
            .toList(growable: false);
        final allBairro = merged
            .expand((b) => b.bairroOptions)
            .toList(growable: false);
        final allMunicipio = merged
            .expand((b) => b.municipioOptions)
            .toList(growable: false);
        return ResumoVendasDiariasPorVendedorAllFilterOptionsAcrossAgents(
          vendedorOptions: _postDedupeVendedorOptions(
            allVendedor,
            effectiveLimit,
          ),
          bairroOptions: _postDedupeTextOptions(allBairro, effectiveLimit),
          municipioOptions: _postDedupeTextOptions(
            allMunicipio,
            effectiveLimit,
          ),
        );
      },
      successLogMessage:
          'Agent query filter options batch executed across agents',
      successContext: (report, mapped) => <String, Object?>{
        'mergedVendedorOptionCount': mapped.vendedorOptions.length,
        'mergedBairroOptionCount': mapped.bairroOptions.length,
        'mergedMunicipioOptionCount': mapped.municipioOptions.length,
        'failedAgentCount': report.failedAgentIds.length,
      },
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

    return AgentQueryListReportAcrossAgentsCoordinator.executeMapped<
      List<T>,
      T
    >(
      operation: _operation,
      queryKey: queryKey,
      userId: userId,
      targetResolver: _targetResolver,
      planBuilder: _planBuilder,
      executor: executor,
      selectedAgentIds: selectedAgentIds,
      strategy: strategy,
      bridgeTimeoutMs: bridgeTimeoutMs,
      raceMaxSources: raceMaxSources,
      loadRowsForTarget: ({required target, required plan, required resolution}) {
        final perAgentFetchLimit =
            ResumoVendasDiariasSuggestionSqlParams.perAgentSuggestionFetchLimit(
              mergeResultLimit: limit,
              plannedTargetCount: plan.plannedTargets.length,
            );
        return loadForTarget(
          target,
          plan.bridgeTimeoutMs,
          perAgentFetchLimit,
          resolution,
        );
      },
      mapReport: (report) => postProcess(report.mergedRows),
      successLogMessage: 'Agent query options executed across agents',
      successContext: (report, processed) => <String, Object?>{
        'mergedOptionCount': processed.length,
      },
    );
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
