import 'dart:math' as math;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_transport_policy.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_sql_batch_target_wave_runner.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_plan.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/sales/application/ports/sales_live_map_batch_loader.dart';
import 'package:colmeia/features/sales/data/sales_live_map_batch_load_config.dart';
import 'package:colmeia/features/sales/data/sales_live_map_batch_target_result.dart';
import 'package:colmeia/features/sales/data/sales_live_map_batch_target_runner.dart';
import 'package:result_dart/result_dart.dart';

export 'package:colmeia/features/sales/application/sales_live_map_batch_load_result.dart';
export 'package:colmeia/features/sales/data/sales_live_map_batch_load_config.dart';

class SalesLiveMapBatchLoaderImpl implements SalesLiveMapBatchLoader {
  SalesLiveMapBatchLoaderImpl({
    required AgentQueryPlanBuilder planBuilder,
    required AgentQueriesRepository agentQueriesRepository,
    int? maxParallelReadOnlyBatchItems,
    int? targetWaveConcurrency,
    AgentQueryTransportPolicy? transportPolicy,
    SalesLiveMapBatchTargetRunner? targetRunner,
  }) : _planBuilder = planBuilder,
       _targetWaveConcurrency =
           targetWaveConcurrency ?? AppEnvironment.salesLiveMapMergeWaveSize,
       _targetRunner =
           targetRunner ??
           SalesLiveMapBatchTargetRunner(
             agentQueriesRepository: agentQueriesRepository,
             maxParallelReadOnlyBatchItems: maxParallelReadOnlyBatchItems,
             transportPolicy: transportPolicy,
           );

  static int get batchBridgeTimeoutMs =>
      SalesLiveMapBatchLoadConfig.bridgeTimeoutMs;

  static int get batchSqlTimeoutMs => SalesLiveMapBatchLoadConfig.sqlTimeoutMs;

  static int get batchMaxRows => SalesLiveMapBatchLoadConfig.batchMaxRows;

  final AgentQueryPlanBuilder _planBuilder;
  final int _targetWaveConcurrency;
  final SalesLiveMapBatchTargetRunner _targetRunner;

  static const _targetWaveRunner = AgentSqlBatchTargetWaveRunner();

  @override
  Future<AppResult<SalesLiveMapBatchLoadResult>> load({
    required String userId,
    required CadastroFilialFilter catalogFilter,
    required ResumoTotalVendasMunicipioFilialPeriodoFilter salesFilter,
    required AgentQueryTargetResolution preResolvedResolution,
    AgentQueriesCancelScope? cancelScope,
    int? bridgeTimeoutMs,
    int? targetWaveConcurrency,
  }) async {
    AppResult<SalesLiveMapBatchLoadResult>? finalResult;
    await for (final result in loadProgressively(
      userId: userId,
      catalogFilter: catalogFilter,
      salesFilter: salesFilter,
      preResolvedResolution: preResolvedResolution,
      cancelScope: cancelScope,
      bridgeTimeoutMs: bridgeTimeoutMs,
      targetWaveConcurrency: targetWaveConcurrency,
    )) {
      finalResult = result;
      if (result.isError()) {
        return result;
      }
    }
    return finalResult ??
        const Failure<SalesLiveMapBatchLoadResult, AppFailure>(
          UnknownFailure(
            message: 'Sales live map batch load produced no data',
            userMessage: 'Unable to load the sales live map.',
          ),
        );
  }

  @override
  Stream<AppResult<SalesLiveMapBatchLoadResult>> loadProgressively({
    required String userId,
    required CadastroFilialFilter catalogFilter,
    required ResumoTotalVendasMunicipioFilialPeriodoFilter salesFilter,
    required AgentQueryTargetResolution preResolvedResolution,
    AgentQueriesCancelScope? cancelScope,
    int? bridgeTimeoutMs,
    int? targetWaveConcurrency,
  }) async* {
    final catalogValidation = catalogFilter.validationError();
    if (catalogValidation != null) {
      yield Failure<SalesLiveMapBatchLoadResult, AppFailure>(
        ValidationFailure(
          message: catalogValidation,
          context: const <String, Object?>{
            'operation': 'loadSalesLiveMapBatch',
          },
        ),
      );
      return;
    }
    final salesValidation = salesFilter.validationError();
    if (salesValidation != null) {
      yield Failure<SalesLiveMapBatchLoadResult, AppFailure>(
        ValidationFailure(
          message: salesValidation,
          context: const <String, Object?>{
            'operation': 'loadSalesLiveMapBatch',
          },
        ),
      );
      return;
    }

    final planResult = _planBuilder.build(
      queryKey: AgentQueryKey.cadastroFilial,
      strategy: AgentQueryExecutionStrategy.mergeAll,
      resolution: preResolvedResolution,
      bridgeTimeoutMs: bridgeTimeoutMs ?? batchBridgeTimeoutMs,
      orderPlannedTargetsOnlineFirst: true,
      dedupePlannedTargetsByAgentId: true,
    );
    final plan = planResult.getOrNull();
    if (plan == null) {
      yield Failure<SalesLiveMapBatchLoadResult, AppFailure>(
        planResult.exceptionOrNull()!,
      );
      return;
    }

    final started = DateTime.now();
    final targets = plan.plannedTargets.toList();
    final waveCap = targetWaveConcurrency ?? _targetWaveConcurrency;
    final waveSize = waveCap >= targets.length
        ? targets.length
        : math.max(1, waveCap);
    final firstBatchResults = <SalesLiveMapBatchTargetResult>[];

    for (var start = 0; start < targets.length; start += waveSize) {
      final end = math.min(start + waveSize, targets.length);
      final waveResults = await Future.wait(
        List<Future<SalesLiveMapBatchTargetResult>>.generate(
          end - start,
          (offset) => _targetRunner.loadFirstBatchForTarget(
            userId: userId,
            target: targets[start + offset],
            plan: plan,
            catalogFilter: catalogFilter,
            salesFilter: salesFilter,
            resolution: preResolvedResolution,
            cancelScope: cancelScope,
          ),
        ),
      );
      firstBatchResults.addAll(waveResults);
      final elapsedMs = DateTime.now().difference(started).inMilliseconds;
      yield Success<SalesLiveMapBatchLoadResult, AppFailure>(
        _buildBatchLoadResult(
          plan: plan,
          targetResults: firstBatchResults,
          totalElapsedMs: elapsedMs,
          isFinal: false,
          salesLoadingComplete: end >= targets.length,
        ),
      );
    }

    final paginationTargets = firstBatchResults
        .where(SalesLiveMapBatchTargetResult.needsCatalogPagination)
        .toList(growable: false);
    var targetResults = firstBatchResults;
    if (paginationTargets.isNotEmpty) {
      final paginatedResults = await _targetWaveRunner.run(
        targets: paginationTargets.map((result) => result.target).toList(),
        waveConcurrencyCap: waveCap,
        task: (target) {
          final firstBatch = paginationTargets.firstWhere(
            (result) => result.target.agentId == target.agentId,
          );
          return _targetRunner.paginateCatalogForTarget(
            firstBatch: firstBatch,
            userId: userId,
            target: target,
            plan: plan,
            catalogFilter: catalogFilter,
            resolution: preResolvedResolution,
            cancelScope: cancelScope,
          );
        },
      );
      targetResults = _mergePaginatedResults(
        firstBatchResults: firstBatchResults,
        paginatedResults: paginatedResults,
      );
    }

    final totalElapsedMs = DateTime.now().difference(started).inMilliseconds;
    yield Success<SalesLiveMapBatchLoadResult, AppFailure>(
      _buildBatchLoadResult(
        plan: plan,
        targetResults: targetResults,
        totalElapsedMs: totalElapsedMs,
        isFinal: true,
        salesLoadingComplete: true,
      ),
    );
  }

  SalesLiveMapBatchLoadResult _buildBatchLoadResult({
    required AgentQueryPlan plan,
    required List<SalesLiveMapBatchTargetResult> targetResults,
    required int totalElapsedMs,
    required bool isFinal,
    required bool salesLoadingComplete,
  }) {
    final paginationStalledAgentIds = targetResults
        .where((result) => result.paginationStalled)
        .map((result) => result.target.agentId)
        .toSet();
    return SalesLiveMapBatchLoadResult(
      catalogPage: CadastroFilialAcrossAgentsPageResult.fromReport(
        _buildCatalogReport(plan: plan, targetResults: targetResults),
        paginationStalledAgentIds: paginationStalledAgentIds,
      ),
      salesReport: _buildSalesReport(
        plan: plan,
        targetResults: targetResults,
        totalElapsedMs: totalElapsedMs,
      ),
      totalElapsedMs: totalElapsedMs,
      isFinal: isFinal,
      salesLoadingComplete: salesLoadingComplete,
    );
  }

  List<SalesLiveMapBatchTargetResult> _mergePaginatedResults({
    required List<SalesLiveMapBatchTargetResult> firstBatchResults,
    required List<SalesLiveMapBatchTargetResult> paginatedResults,
  }) {
    final paginatedByAgentId = <String, SalesLiveMapBatchTargetResult>{
      for (final result in paginatedResults) result.target.agentId: result,
    };
    return firstBatchResults
        .map(
          (result) => paginatedByAgentId[result.target.agentId] ?? result,
        )
        .toList(growable: false);
  }

  AgentQueryExecutionReport<CadastroFilialRow> _buildCatalogReport({
    required AgentQueryPlan plan,
    required List<SalesLiveMapBatchTargetResult> targetResults,
  }) {
    return AgentQueryExecutionReport<CadastroFilialRow>(
      queryKey: AgentQueryKey.cadastroFilial,
      strategy: AgentQueryExecutionStrategy.mergeAll,
      consideredApprovedAgentCount: plan.consideredApprovedAgentCount,
      plannedTargets: plan.plannedTargets,
      missingClientTokenTargets: plan.missingClientTokenTargets,
      skippedDueToHubPresenceTargets: plan.skippedDueToHubPresenceTargets,
      totalElapsedMs: targetResults.fold<int>(
        0,
        (max, result) => math.max(max, result.elapsedMs),
      ),
      participants: targetResults
          .map(
            (result) => AgentQueryExecutionParticipant<CadastroFilialRow>(
              agentId: result.target.agentId,
              displayName: result.target.displayName,
              rows: result.catalogRows,
              elapsedMs: result.elapsedMs,
              sourceRowCount: result.catalogFailure == null
                  ? result.catalogSourceRowCount
                  : result.catalogRows.length,
              failure: result.catalogFailure,
            ),
          )
          .toList(growable: false),
    );
  }

  AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>
  _buildSalesReport({
    required AgentQueryPlan plan,
    required List<SalesLiveMapBatchTargetResult> targetResults,
    required int totalElapsedMs,
  }) {
    return AgentQueryExecutionReport<
      ResumoTotalVendasMunicipioFilialPeriodoRow
    >(
      queryKey: AgentQueryKey.resumoTotalVendasMunicipioFilialPeriodo,
      strategy: AgentQueryExecutionStrategy.mergeAll,
      consideredApprovedAgentCount: plan.consideredApprovedAgentCount,
      plannedTargets: plan.plannedTargets,
      missingClientTokenTargets: plan.missingClientTokenTargets,
      skippedDueToHubPresenceTargets: plan.skippedDueToHubPresenceTargets,
      totalElapsedMs: totalElapsedMs,
      participants: targetResults
          .map(
            (result) =>
                AgentQueryExecutionParticipant<
                  ResumoTotalVendasMunicipioFilialPeriodoRow
                >(
                  agentId: result.target.agentId,
                  displayName: result.target.displayName,
                  rows: result.salesRows,
                  elapsedMs: result.elapsedMs,
                  sourceRowCount: result.salesRows.length,
                  failure: result.salesFailure,
                ),
          )
          .toList(growable: false),
    );
  }
}
