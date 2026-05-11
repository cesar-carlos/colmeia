import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_vendas_municipio_filial_diario_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_diario_row.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_point_resolver.dart';

class SalesLiveMapLoadResult {
  const SalesLiveMapLoadResult({
    required this.points,
    required this.branchOptions,
    required this.totalRevenue,
    required this.totalSalesCount,
    required this.totalBranchCount,
    required this.mappedBranchCount,
    required this.mappedMunicipalityCount,
    required this.queriedAgentCount,
    required this.plannedAgentCount,
    required this.failedAgentCount,
    required this.missingClientTokenAgentCount,
    required this.skippedOfflineAgentCount,
    required this.refreshedAt,
    this.loadFailed = false,
    this.loadFailureMessage,
  });

  final List<AppBrazilStoreSalesPoint> points;
  final List<SalesLiveMapBranchOption> branchOptions;
  final double totalRevenue;
  final int totalSalesCount;
  final int totalBranchCount;
  final int mappedBranchCount;
  final int mappedMunicipalityCount;
  final int queriedAgentCount;
  final int plannedAgentCount;
  final int failedAgentCount;
  final int missingClientTokenAgentCount;
  final int skippedOfflineAgentCount;
  final bool loadFailed;
  final String? loadFailureMessage;
  final DateTime? refreshedAt;

  bool get hasPartialIssue =>
      failedAgentCount > 0 ||
      missingClientTokenAgentCount > 0 ||
      skippedOfflineAgentCount > 0 ||
      mappedBranchCount < totalBranchCount;
}

class LoadSalesLiveMapUseCase {
  LoadSalesLiveMapUseCase(
    this._loadResumoTotalVendasMunicipioFilialDiarioAcrossAgents,
    this._pointResolver, {
    DateTime Function()? now,
  }) : _now = now;

  static const int bridgeTimeoutMs = 120000;

  final LoadResumoTotalVendasMunicipioFilialDiarioAcrossAgentsUseCase
  _loadResumoTotalVendasMunicipioFilialDiarioAcrossAgents;
  final AppBrazilStoreSalesPointResolver _pointResolver;
  final DateTime Function()? _now;

  Future<SalesLiveMapLoadResult> call({
    required String userId,
    required SalesLiveMapFilter filter,
  }) async {
    final now = _resolveNow();
    final queryFilter = filter.toAgentQueryFilter(now: now);
    final result =
        await _loadResumoTotalVendasMunicipioFilialDiarioAcrossAgents(
          userId: userId,
          filter: queryFilter,
          selectedAgentIds: filter.selectedAgentIds,
          bridgeTimeoutMs: bridgeTimeoutMs,
        );

    return result.fold(
      (report) => _mapReport(report, filter: filter, refreshedAt: now),
      (failure) {
        AppLogger.warning(
          'Sales live map query failed',
          context: <String, Object?>{
            'operation': 'LoadSalesLiveMapUseCase',
            'failureType': failure.runtimeType.toString(),
          },
          error: failure,
        );
        return Future<SalesLiveMapLoadResult>.value(
          _failedResult(failure, refreshedAt: now),
        );
      },
    );
  }

  Future<SalesLiveMapLoadResult> _mapReport(
    AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialDiarioRow>
    report, {
    required SalesLiveMapFilter filter,
    required DateTime refreshedAt,
  }) async {
    final aggregates = _aggregateRows(report.participants);
    final branchOptions = aggregates
        .map((aggregate) => aggregate.toBranchOption())
        .toList(growable: false);
    final visibleAggregates = _filterAggregatesByBranch(aggregates, filter);
    final sources = visibleAggregates
        .map((aggregate) => aggregate.toPointSource())
        .toList(growable: false);
    final resolved = await Future.wait(sources.map(_pointResolver.resolve));
    final points = resolved.whereType<AppBrazilStoreSalesPoint>().toList(
      growable: false,
    );
    final mappedMunicipalityCount = _mappedMunicipalityCount(points);

    final loadFailed = report.requiresClientTokenSetup;
    return SalesLiveMapLoadResult(
      points: points,
      branchOptions: branchOptions,
      totalRevenue: visibleAggregates.fold<double>(
        0,
        (total, aggregate) => total + aggregate.totalVenda,
      ),
      totalSalesCount: visibleAggregates.fold<int>(
        0,
        (total, aggregate) => total + aggregate.qtdVendas,
      ),
      totalBranchCount: visibleAggregates.length,
      mappedBranchCount: points.length,
      mappedMunicipalityCount: mappedMunicipalityCount,
      queriedAgentCount: report.participants.length,
      plannedAgentCount: report.plannedTargets.length,
      failedAgentCount: report.failedAgentIds.length,
      missingClientTokenAgentCount: report.missingClientTokenTargets.length,
      skippedOfflineAgentCount: report.skippedDueToHubPresenceTargets.length,
      loadFailed: loadFailed,
      loadFailureMessage: loadFailed
          ? 'Nenhum agente selecionado possui token local para executar a consulta.'
          : null,
      refreshedAt: refreshedAt,
    );
  }

  SalesLiveMapLoadResult _failedResult(
    AppFailure failure, {
    required DateTime refreshedAt,
  }) {
    return SalesLiveMapLoadResult(
      points: const <AppBrazilStoreSalesPoint>[],
      branchOptions: const <SalesLiveMapBranchOption>[],
      totalRevenue: 0,
      totalSalesCount: 0,
      totalBranchCount: 0,
      mappedBranchCount: 0,
      mappedMunicipalityCount: 0,
      queriedAgentCount: 0,
      plannedAgentCount: 0,
      failedAgentCount: 0,
      missingClientTokenAgentCount: 0,
      skippedOfflineAgentCount: 0,
      loadFailed: true,
      loadFailureMessage: failure.userMessage,
      refreshedAt: refreshedAt,
    );
  }

  List<_SalesLiveMapBranchAggregate> _aggregateRows(
    Iterable<
      AgentQueryExecutionParticipant<ResumoTotalVendasMunicipioFilialDiarioRow>
    >
    participants,
  ) {
    final byKey = <String, _SalesLiveMapBranchAggregate>{};
    for (final participant in participants) {
      if (!participant.isSuccess) {
        continue;
      }
      for (final row in participant.rows) {
        final key = [
          participant.agentId,
          row.codEmpresa,
          row.codFilial,
        ].join(':');
        byKey
            .putIfAbsent(
              key,
              () => _SalesLiveMapBranchAggregate.fromRow(
                participant: participant,
                row: row,
              ),
            )
            .add(row);
      }
    }

    final aggregates = byKey.values.toList(growable: false)
      ..sort(
        (left, right) {
          final amount = right.totalVenda.compareTo(left.totalVenda);
          if (amount != 0) {
            return amount;
          }
          return left.name.compareTo(right.name);
        },
      );
    return aggregates;
  }

  List<_SalesLiveMapBranchAggregate> _filterAggregatesByBranch(
    List<_SalesLiveMapBranchAggregate> aggregates,
    SalesLiveMapFilter filter,
  ) {
    final selectedBranchIds = filter.selectedBranchIds;
    if (selectedBranchIds == null || selectedBranchIds.isEmpty) {
      return aggregates;
    }

    return aggregates
        .where((aggregate) => selectedBranchIds.contains(aggregate.id))
        .toList(growable: false);
  }

  DateTime _resolveNow() => (_now ?? DateTime.now)();

  int _mappedMunicipalityCount(Iterable<AppBrazilStoreSalesPoint> points) {
    return points.map(_municipalityKeyFor).toSet().length;
  }

  String _municipalityKeyFor(AppBrazilStoreSalesPoint point) {
    final municipalityCode = point.municipalityCode?.trim();
    if (municipalityCode != null && municipalityCode.isNotEmpty) {
      return 'ibge:${municipalityCode.toUpperCase()}';
    }

    final city = point.city?.trim();
    if (city != null && city.isNotEmpty) {
      return 'city:${city.toUpperCase()}:${point.uf.trim().toUpperCase()}';
    }

    return 'coordinate:${point.latitude}:${point.longitude}:${point.uf.trim().toUpperCase()}';
  }
}

class _SalesLiveMapBranchAggregate {
  _SalesLiveMapBranchAggregate({
    required this.agentId,
    required this.agentName,
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeFilial,
    required this.nomeMunicipioFilial,
    required this.ufMunicipioFilial,
    this.nomeFantasiaFilial,
    this.cepFilial,
    this.codigoIbgeMunicipioFilial,
  });

  factory _SalesLiveMapBranchAggregate.fromRow({
    required AgentQueryExecutionParticipant<
      ResumoTotalVendasMunicipioFilialDiarioRow
    >
    participant,
    required ResumoTotalVendasMunicipioFilialDiarioRow row,
  }) {
    return _SalesLiveMapBranchAggregate(
      agentId: participant.agentId,
      agentName: participant.displayName,
      codEmpresa: row.codEmpresa,
      codFilial: row.codFilial,
      nomeFilial: row.nomeFilial,
      nomeFantasiaFilial: row.nomeFantasiaFilial,
      cepFilial: row.cepFilial,
      nomeMunicipioFilial: row.nomeMunicipioFilial,
      ufMunicipioFilial: row.ufMunicipioFilial,
      codigoIbgeMunicipioFilial: row.codigoIbgeMunicipioFilial,
    );
  }

  final String agentId;
  final String agentName;
  final int codEmpresa;
  final int codFilial;
  final String nomeFilial;
  final String? nomeFantasiaFilial;
  final String? cepFilial;
  final String nomeMunicipioFilial;
  final String ufMunicipioFilial;
  final String? codigoIbgeMunicipioFilial;
  double totalVenda = 0;
  int qtdVendas = 0;

  String get id => '$agentId-$codEmpresa-$codFilial';

  String get name {
    final fantasy = nomeFantasiaFilial?.trim();
    if (fantasy != null && fantasy.isNotEmpty) {
      return fantasy;
    }
    return nomeFilial;
  }

  void add(ResumoTotalVendasMunicipioFilialDiarioRow row) {
    totalVenda += row.totalVenda;
    qtdVendas += row.qtdVendas;
  }

  AppBrazilStoreSalesPointSource toPointSource() {
    return AppBrazilStoreSalesPointSource(
      id: id,
      name: name,
      salesAmount: totalVenda,
      salesCount: qtdVendas,
      uf: ufMunicipioFilial,
      city: nomeMunicipioFilial,
      cep: cepFilial,
      ibgeMunicipalityCode: codigoIbgeMunicipioFilial,
      subtitle: 'Agente $agentName - Empresa $codEmpresa - Filial $codFilial',
      payload: this,
    );
  }

  SalesLiveMapBranchOption toBranchOption() {
    return SalesLiveMapBranchOption(
      id: id,
      agentId: agentId,
      agentName: agentName,
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      name: name,
      city: nomeMunicipioFilial,
      uf: ufMunicipioFilial,
    );
  }
}
