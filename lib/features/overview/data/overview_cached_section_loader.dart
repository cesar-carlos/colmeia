import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_lucratividade_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';

final class OverviewCachedSections {
  const OverviewCachedSections({
    this.dailyRows = const <ResumoTotalDiarioVendasRow>[],
    this.monthlyRows = const <ResumoParcelasMensalRow>[],
    this.weekdayRows = const <ResumoParcelasDiaSemanaRow>[],
    this.lucratividadeRows = const <ResumoProdutoVendaLucratividadeRow>[],
    this.dailyFailure,
    this.monthlyFailure,
    this.weekdayFailure,
    this.lucratividadeFailure,
  });

  final List<ResumoTotalDiarioVendasRow> dailyRows;
  final List<ResumoParcelasMensalRow> monthlyRows;
  final List<ResumoParcelasDiaSemanaRow> weekdayRows;
  final List<ResumoProdutoVendaLucratividadeRow> lucratividadeRows;
  final AppFailure? dailyFailure;
  final AppFailure? monthlyFailure;
  final AppFailure? weekdayFailure;
  final AppFailure? lucratividadeFailure;
}

/// Loads overview section rows from cached agent-query use cases.
///
/// Use cases run **serially** so they never overlap `executeSqlBatch` for the
/// same agent (reduces per-agent inflight on the bridge).
final class OverviewCachedSectionLoader {
  OverviewCachedSectionLoader({
    LoadResumoTotalDiarioVendasUseCase? loadDaily,
    LoadResumoParcelasMensalUseCase? loadMonthly,
    LoadResumoParcelasDiaSemanaUseCase? loadWeekday,
    LoadResumoProdutoVendaLucratividadeUseCase? loadLucratividade,
  }) : _loadDaily = loadDaily,
       _loadMonthly = loadMonthly,
       _loadWeekday = loadWeekday,
       _loadLucratividade = loadLucratividade;

  final LoadResumoTotalDiarioVendasUseCase? _loadDaily;
  final LoadResumoParcelasMensalUseCase? _loadMonthly;
  final LoadResumoParcelasDiaSemanaUseCase? _loadWeekday;
  final LoadResumoProdutoVendaLucratividadeUseCase? _loadLucratividade;

  bool get usesDailyMonthly => _loadDaily != null && _loadMonthly != null;

  bool get usesWeekday => _loadWeekday != null;

  bool get usesLucratividade => _loadLucratividade != null;

  bool isConfiguredFor(AgentQueryLoadPolicy cachePolicy) {
    if (cachePolicy != AgentQueryLoadPolicy.defaultLoad) {
      return false;
    }
    return usesDailyMonthly || usesWeekday || usesLucratividade;
  }

  Future<OverviewCachedSections?> load({
    required AgentQueryLoadPolicy cachePolicy,
    required String userId,
    required AgentQueryTarget target,
    required ResumoParcelasMensalFilter mensalFilter,
    required ResumoParcelasDiaSemanaFilter weekdayFilter,
    required ResumoTotalDiarioVendasFilter dailyTotalFilter,
    required int planBridgeTimeoutMs,
    required Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    if (!isConfiguredFor(cachePolicy)) {
      return null;
    }
    if (cancelScope?.isCancelled ?? false) {
      return null;
    }

    final loadDaily = _loadDaily;
    final loadMonthly = _loadMonthly;
    final loadWeekday = _loadWeekday;
    final loadLucratividade = _loadLucratividade;
    if (loadDaily == null &&
        loadMonthly == null &&
        loadWeekday == null &&
        loadLucratividade == null) {
      return null;
    }

    final lucratividadeFilter = ResumoProdutoVendaLucratividadeFilter(
      dataVendaInicio: dailyTotalFilter.dataVendaInicio,
      dataVendaFim: dailyTotalFilter.dataVendaFim,
    );

    AppResult<List<ResumoTotalDiarioVendasRow>>? dailyResult;
    AppResult<List<ResumoParcelasMensalRow>>? monthlyResult;
    AppResult<List<ResumoParcelasDiaSemanaRow>>? weekdayResult;
    AppResult<List<ResumoProdutoVendaLucratividadeRow>>? lucratividadeResult;

    if (loadDaily != null) {
      if (cancelScope?.isCancelled ?? false) {
        return null;
      }
      dailyResult = await loadDaily.call(
        userId: userId,
        agentId: target.agentId,
        filter: dailyTotalFilter,
        clientToken: target.clientToken,
        bridgeTimeoutMs: planBridgeTimeoutMs,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow:
            target.hubConnectedFromApprovedCatalogRow,
        cancelScope: cancelScope,
        cachePolicy: cachePolicy,
      );
    }
    if (loadMonthly != null) {
      if (cancelScope?.isCancelled ?? false) {
        return null;
      }
      monthlyResult = await loadMonthly.call(
        userId: userId,
        agentId: target.agentId,
        filter: mensalFilter,
        clientToken: target.clientToken,
        bridgeTimeoutMs: planBridgeTimeoutMs,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow:
            target.hubConnectedFromApprovedCatalogRow,
        cancelScope: cancelScope,
        cachePolicy: cachePolicy,
      );
    }
    if (loadWeekday != null) {
      if (cancelScope?.isCancelled ?? false) {
        return null;
      }
      weekdayResult = await loadWeekday.call(
        userId: userId,
        agentId: target.agentId,
        filter: weekdayFilter,
        clientToken: target.clientToken,
        bridgeTimeoutMs: planBridgeTimeoutMs,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow:
            target.hubConnectedFromApprovedCatalogRow,
        cancelScope: cancelScope,
        cachePolicy: cachePolicy,
      );
    }
    if (loadLucratividade != null) {
      if (cancelScope?.isCancelled ?? false) {
        return null;
      }
      lucratividadeResult = await loadLucratividade.call(
        userId: userId,
        agentId: target.agentId,
        filter: lucratividadeFilter,
        clientToken: target.clientToken,
        bridgeTimeoutMs: planBridgeTimeoutMs,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow:
            target.hubConnectedFromApprovedCatalogRow,
        cancelScope: cancelScope,
        cachePolicy: cachePolicy,
      );
    }

    return OverviewCachedSections(
      dailyRows:
          dailyResult?.getOrNull() ?? const <ResumoTotalDiarioVendasRow>[],
      monthlyRows:
          monthlyResult?.getOrNull() ?? const <ResumoParcelasMensalRow>[],
      weekdayRows:
          weekdayResult?.getOrNull() ?? const <ResumoParcelasDiaSemanaRow>[],
      lucratividadeRows:
          lucratividadeResult?.getOrNull() ??
          const <ResumoProdutoVendaLucratividadeRow>[],
      dailyFailure: dailyResult?.exceptionOrNull(),
      monthlyFailure: monthlyResult?.exceptionOrNull(),
      weekdayFailure: weekdayResult?.exceptionOrNull(),
      lucratividadeFailure: lucratividadeResult?.exceptionOrNull(),
    );
  }
}
