import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_branch_aggregate.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_branch_keys.dart';
import 'package:colmeia/features/sales/application/sales_live_map_policies.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';

/// Builds and filters branch-level aggregates from agent query reports.
///
/// Owns the rules around which rows count as the primary branch, how the
/// aggregates are sorted, and how branch filters narrow the visible set.
/// Keeps `LoadSalesLiveMapUseCase` focused on orchestration while the
/// aggregation rules live here.
class SalesLiveMapBranchAggregator {
  const SalesLiveMapBranchAggregator();

  /// Aggregates branch rows coming **only** from the sales query report. Used
  /// when there is no catalog page to merge with (e.g. cache-miss + sales-only
  /// path).
  ///
  /// Takes a concrete `List` (not `Iterable`) so internal iteration patterns
  /// cannot accidentally walk a lazy source twice and turn into O(N²).
  List<SalesLiveMapBranchAggregate> aggregateFromSalesReport(
    List<
      AgentQueryExecutionParticipant<ResumoTotalVendasMunicipioFilialPeriodoRow>
    >
    participants,
  ) {
    final byKey = <String, SalesLiveMapBranchAggregate>{};
    for (final participant in participants) {
      if (!participant.isSuccess) {
        continue;
      }
      for (final row in participant.rows) {
        if (!_isPrimaryBranch(row.codEmpresa, row.codFilial)) {
          continue;
        }
        final key = _branchKey(
          participant.agentId,
          row.codEmpresa,
          row.codFilial,
        );
        byKey
            .putIfAbsent(
              key,
              () => SalesLiveMapBranchAggregate.fromRow(
                participant: participant,
                row: row,
              ),
            )
            .add(row);
      }
    }
    return _sortedByRevenueThenName(byKey.values);
  }

  /// Aggregates branch rows starting from the catalog page (which lists every
  /// branch even when sales data is pending) and merges in any sales rows that
  /// have already arrived. Marks aggregates as `loading` or `unavailable` when
  /// the sales side is not yet usable.
  List<SalesLiveMapBranchAggregate> aggregateFromCatalog({
    required AgentQueryExecutionReport<CadastroFilialRow> catalogReport,
    required AgentQueryExecutionReport<
      ResumoTotalVendasMunicipioFilialPeriodoRow
    >?
    salesReport,
    required Map<String, String> salesUnavailableLabelsByAgentId,
    required bool salesDataPending,
  }) {
    final byKey = <String, SalesLiveMapBranchAggregate>{};
    for (final participant in catalogReport.participants) {
      if (!participant.isSuccess) {
        continue;
      }
      for (final row in participant.rows) {
        final key = _branchKey(
          participant.agentId,
          row.codEmpresa,
          row.codFilial,
        );
        byKey.putIfAbsent(key, () {
          final aggregate = SalesLiveMapBranchAggregate.fromCadastro(
            participant: participant,
            row: row,
          );
          final statusLabel =
              salesUnavailableLabelsByAgentId[participant.agentId];
          if (salesDataPending) {
            aggregate.markSalesDataLoading();
          } else if (statusLabel != null) {
            aggregate.markSalesDataUnavailable(statusLabel);
          }
          return aggregate;
        });
      }
    }

    if (salesReport != null) {
      for (final participant in salesReport.participants) {
        if (!participant.isSuccess) {
          continue;
        }
        for (final row in participant.rows) {
          if (!_isPrimaryBranch(row.codEmpresa, row.codFilial)) {
            continue;
          }
          final aggregate =
              byKey[_branchKey(
                participant.agentId,
                row.codEmpresa,
                row.codFilial,
              )];
          aggregate?.add(row);
        }
      }
    }

    return _sortedByRevenueThenName(byKey.values);
  }

  /// Narrows [aggregates] down to those matching the explicit branch
  /// selection. Returns the unchanged list when the filter has no selection.
  List<SalesLiveMapBranchAggregate> filterByBranchSelection(
    List<SalesLiveMapBranchAggregate> aggregates,
    SalesLiveMapFilter filter,
  ) {
    final selectedBranchIds = filter.selectedBranchIds;
    if (selectedBranchIds == null || selectedBranchIds.isEmpty) {
      return aggregates;
    }

    return aggregates
        .where((aggregate) => selectedBranchIds.contains(aggregate.branchRef))
        .toList(growable: false);
  }

  /// Maps each catalog-success agent to a user-facing label explaining why
  /// its sales data is unavailable. Empty when the catalog itself failed or
  /// sales data is fine.
  Map<String, String> salesUnavailableLabelsByAgentId({
    required AgentQueryExecutionReport<CadastroFilialRow>? catalogReport,
    required AgentQueryExecutionReport<
      ResumoTotalVendasMunicipioFilialPeriodoRow
    >?
    salesReport,
    required AppFailure? salesFailure,
  }) {
    if (catalogReport == null) {
      return const <String, String>{};
    }

    final catalogSuccessAgentIds = catalogReport.participants
        .where((participant) => participant.isSuccess)
        .map((participant) => participant.agentId)
        .toSet();
    if (catalogSuccessAgentIds.isEmpty) {
      return const <String, String>{};
    }

    if (salesReport == null) {
      if (salesFailure == null) {
        return const <String, String>{};
      }
      return <String, String>{
        for (final agentId in catalogSuccessAgentIds)
          agentId: _salesUnavailableLabel(salesFailure),
      };
    }

    final labelsByAgentId = <String, String>{};
    for (final participant in salesReport.participants) {
      if (participant.isSuccess ||
          !catalogSuccessAgentIds.contains(participant.agentId)) {
        continue;
      }
      labelsByAgentId[participant.agentId] = _salesUnavailableLabel(
        participant.failure,
      );
    }
    return Map<String, String>.unmodifiable(labelsByAgentId);
  }

  /// Number of agents that failed across catalog and sales reports. Returns
  /// [plannedTargets] when the whole side is missing (treat all as failed).
  int combinedFailedAgentCount({
    required AgentQueryExecutionReport<CadastroFilialRow>? catalogReport,
    required AgentQueryExecutionReport<
      ResumoTotalVendasMunicipioFilialPeriodoRow
    >?
    salesReport,
    required AppFailure? catalogFailure,
    required AppFailure? salesFailure,
    required int plannedTargets,
  }) {
    final failed = <String>{};
    if (catalogReport != null) {
      failed.addAll(catalogReport.failedAgentIds);
    } else if (catalogFailure != null && salesReport == null) {
      return plannedTargets;
    }
    if (salesReport != null) {
      failed.addAll(salesReport.failedAgentIds);
    } else if (salesFailure != null) {
      return plannedTargets;
    }
    return failed.length;
  }

  /// Number of participants in [report] that hit the bounded result row cap
  /// for the resumo-total-vendas query.
  int rowCapReachedAgentCount(
    AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>
    report,
  ) {
    return report.participants
        .where(
          (participant) => participant.reachedSourceRowLimit(
            AgentQueriesBoundedResultMaxRows
                .resumoTotalVendasMunicipioFilialPeriodo,
          ),
        )
        .length;
  }

  String _salesUnavailableLabel(AppFailure? failure) {
    final userMessage = failure?.userMessage?.trim();
    if (userMessage != null && userMessage.isNotEmpty) {
      return userMessage;
    }
    return 'Vendas indisponiveis';
  }

  String _branchKey(String agentId, int codEmpresa, int codFilial) {
    return SalesLiveMapBranchKeys.of(
      agentId: agentId,
      codEmpresa: codEmpresa,
      codFilial: codFilial,
    );
  }

  static bool _isPrimaryBranch(int codEmpresa, int codFilial) {
    return codEmpresa == SalesLiveMapPolicies.primaryCompanyCode &&
        codFilial == SalesLiveMapPolicies.primaryBranchCode;
  }

  List<SalesLiveMapBranchAggregate> _sortedByRevenueThenName(
    Iterable<SalesLiveMapBranchAggregate> aggregates,
  ) {
    return aggregates.toList(growable: false)
      ..sort((left, right) {
        final amount = right.totalVenda.compareTo(left.totalVenda);
        if (amount != 0) {
          return amount;
        }
        return left.name.compareTo(right.name);
      });
  }
}
