import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_vendas_municipio_filial_periodo_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
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
    required this.rowCapReachedAgentCount,
    required this.refreshedAt,
    this.locationDiagnostics = const SalesLiveMapLocationDiagnostics(),
    this.loadFailed = false,
    this.loadFailureReason,
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
  final int rowCapReachedAgentCount;
  final SalesLiveMapLocationDiagnostics locationDiagnostics;
  final bool loadFailed;
  final SalesLiveMapLoadFailureReason? loadFailureReason;
  final String? loadFailureMessage;
  final DateTime? refreshedAt;

  bool get hasPartialIssue =>
      failedAgentCount > 0 ||
      missingClientTokenAgentCount > 0 ||
      skippedOfflineAgentCount > 0 ||
      rowCapReachedAgentCount > 0 ||
      mappedBranchCount < totalBranchCount;
}

enum SalesLiveMapLoadFailureReason {
  missingClientTokenSetup,
}

class SalesLiveMapLocationDiagnostics {
  const SalesLiveMapLocationDiagnostics({
    this.resolvedByProvidedGeoPointCount = 0,
    this.resolvedByIbgeMunicipalityCodeCount = 0,
    this.resolvedByCepCount = 0,
    this.resolvedByCityUfCount = 0,
    this.resolvedByCapitalUfCount = 0,
    this.resolvedByStateUfCount = 0,
    this.unknownResolutionCount = 0,
    this.unresolvedBranchCount = 0,
  });

  factory SalesLiveMapLocationDiagnostics.fromPoints({
    required Iterable<AppBrazilStoreSalesPoint> points,
    required int totalBranchCount,
  }) {
    var resolvedByProvidedGeoPointCount = 0;
    var resolvedByIbgeMunicipalityCodeCount = 0;
    var resolvedByCepCount = 0;
    var resolvedByCityUfCount = 0;
    var resolvedByCapitalUfCount = 0;
    var resolvedByStateUfCount = 0;
    var unknownResolutionCount = 0;
    var resolvedPointCount = 0;

    for (final point in points) {
      resolvedPointCount += 1;
      switch (point.locationResolution) {
        case AppBrazilStoreSalesLocationResolution.providedGeoPoint:
          resolvedByProvidedGeoPointCount += 1;
        case AppBrazilStoreSalesLocationResolution.ibgeMunicipalityCode:
          resolvedByIbgeMunicipalityCodeCount += 1;
        case AppBrazilStoreSalesLocationResolution.cep:
          resolvedByCepCount += 1;
        case AppBrazilStoreSalesLocationResolution.cityUf:
          resolvedByCityUfCount += 1;
        case AppBrazilStoreSalesLocationResolution.capitalUf:
          resolvedByCapitalUfCount += 1;
        case AppBrazilStoreSalesLocationResolution.stateUf:
          resolvedByStateUfCount += 1;
        case null:
          unknownResolutionCount += 1;
      }
    }

    return SalesLiveMapLocationDiagnostics(
      resolvedByProvidedGeoPointCount: resolvedByProvidedGeoPointCount,
      resolvedByIbgeMunicipalityCodeCount: resolvedByIbgeMunicipalityCodeCount,
      resolvedByCepCount: resolvedByCepCount,
      resolvedByCityUfCount: resolvedByCityUfCount,
      resolvedByCapitalUfCount: resolvedByCapitalUfCount,
      resolvedByStateUfCount: resolvedByStateUfCount,
      unknownResolutionCount: unknownResolutionCount,
      unresolvedBranchCount: totalBranchCount - resolvedPointCount,
    );
  }

  final int resolvedByProvidedGeoPointCount;
  final int resolvedByIbgeMunicipalityCodeCount;
  final int resolvedByCepCount;
  final int resolvedByCityUfCount;
  final int resolvedByCapitalUfCount;
  final int resolvedByStateUfCount;
  final int unknownResolutionCount;
  final int unresolvedBranchCount;

  bool get hasAnySignal =>
      resolvedByProvidedGeoPointCount > 0 ||
      resolvedByIbgeMunicipalityCodeCount > 0 ||
      resolvedByCepCount > 0 ||
      resolvedByCityUfCount > 0 ||
      resolvedByCapitalUfCount > 0 ||
      resolvedByStateUfCount > 0 ||
      unknownResolutionCount > 0 ||
      unresolvedBranchCount > 0;
}

class LoadSalesLiveMapUseCase {
  LoadSalesLiveMapUseCase(
    this._loadResumoTotalVendasMunicipioFilialPeriodoAcrossAgents,
    this._pointResolver, {
    DateTime Function()? now,
  }) : _now = now;

  static const int bridgeTimeoutMs = 120000;

  final LoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase
  _loadResumoTotalVendasMunicipioFilialPeriodoAcrossAgents;
  final AppBrazilStoreSalesPointResolver _pointResolver;
  final DateTime Function()? _now;

  Future<SalesLiveMapLoadResult> call({
    required String userId,
    required SalesLiveMapFilter filter,
  }) async {
    final now = _resolveNow();
    final queryFilter = filter.toAgentQueryFilter(now: now);
    final result =
        await _loadResumoTotalVendasMunicipioFilialPeriodoAcrossAgents(
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
    AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>
    report, {
    required SalesLiveMapFilter filter,
    required DateTime refreshedAt,
  }) async {
    final aggregates = _aggregateRows(report.participants);
    final branchOptions = aggregates
        .map((aggregate) => aggregate.toBranchOption())
        .toList(growable: false);
    final visibleAggregates = _filterAggregatesByBranch(aggregates, filter);
    final points = await _resolveBranchPoints(visibleAggregates);
    final locationDiagnostics = SalesLiveMapLocationDiagnostics.fromPoints(
      points: points,
      totalBranchCount: visibleAggregates.length,
    );
    _logLocationSummary(locationDiagnostics);
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
      rowCapReachedAgentCount: _rowCapReachedAgentCount(report),
      locationDiagnostics: locationDiagnostics,
      loadFailed: loadFailed,
      loadFailureReason: loadFailed
          ? SalesLiveMapLoadFailureReason.missingClientTokenSetup
          : null,
      refreshedAt: refreshedAt,
    );
  }

  Future<List<AppBrazilStoreSalesPoint>> _resolveBranchPoints(
    List<_SalesLiveMapBranchAggregate> aggregates,
  ) async {
    final resolved = await _pointResolver.resolveAllWithDetails(
      aggregates.map((aggregate) => aggregate.toPointSource()),
    );
    final resolvedById = <String, AppBrazilStoreSalesResolvedPoint>{
      for (final item in resolved) item.point.id: item,
    };
    for (final aggregate in aggregates) {
      final item = resolvedById[aggregate.id];
      if (item == null) {
        _logBranchGeolocation(aggregate, null);
      }
    }

    return resolved.map((item) => item.point).toList(growable: false);
  }

  void _logBranchGeolocation(
    _SalesLiveMapBranchAggregate aggregate,
    AppBrazilStoreSalesResolvedPoint? resolved,
  ) {
    final point = resolved?.point;
    AppLogger.debug(
      'Sales live map branch geolocation resolved',
      context: <String, Object?>{
        'operation': 'LoadSalesLiveMapUseCase',
        'branchId': aggregate.id,
        'agentId': aggregate.agentId,
        'codEmpresa': aggregate.codEmpresa,
        'codFilial': aggregate.codFilial,
        'uf': aggregate.ufMunicipioFilial,
        'city': aggregate.nomeMunicipioFilial,
        'ibgeMunicipalityCode': aggregate.codigoIbgeMunicipioFilial,
        'hasCep': aggregate.cepFilial?.trim().isNotEmpty ?? false,
        'resolved': point != null,
        'resolution': point?.locationResolution?.name,
        'latitude': point?.latitude,
        'longitude': point?.longitude,
      },
    );
  }

  void _logLocationSummary(SalesLiveMapLocationDiagnostics diagnostics) {
    if (!diagnostics.hasAnySignal) {
      return;
    }

    AppLogger.debug(
      'Sales live map geolocation summary',
      context: <String, Object?>{
        'operation': 'LoadSalesLiveMapUseCase',
        'providedGeoPoint': diagnostics.resolvedByProvidedGeoPointCount,
        'ibgeMunicipalityCode': diagnostics.resolvedByIbgeMunicipalityCodeCount,
        'cep': diagnostics.resolvedByCepCount,
        'cityUf': diagnostics.resolvedByCityUfCount,
        'capitalUf': diagnostics.resolvedByCapitalUfCount,
        'stateUf': diagnostics.resolvedByStateUfCount,
        'unknownResolution': diagnostics.unknownResolutionCount,
        'unresolvedBranch': diagnostics.unresolvedBranchCount,
      },
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
      rowCapReachedAgentCount: 0,
      loadFailed: true,
      loadFailureMessage: failure.userMessage,
      refreshedAt: refreshedAt,
    );
  }

  List<_SalesLiveMapBranchAggregate> _aggregateRows(
    Iterable<
      AgentQueryExecutionParticipant<ResumoTotalVendasMunicipioFilialPeriodoRow>
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

  int _rowCapReachedAgentCount(
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
      ResumoTotalVendasMunicipioFilialPeriodoRow
    >
    participant,
    required ResumoTotalVendasMunicipioFilialPeriodoRow row,
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
  final String? nomeMunicipioFilial;
  final String? ufMunicipioFilial;
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

  void add(ResumoTotalVendasMunicipioFilialPeriodoRow row) {
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
      allowUfFallback: false,
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
      city: _branchCityLabel,
      uf: _branchUfLabel,
    );
  }

  String get _branchCityLabel {
    final city = nomeMunicipioFilial?.trim();
    if (city != null && city.isNotEmpty) {
      return city;
    }

    return 'Sem municipio';
  }

  String get _branchUfLabel {
    final uf = ufMunicipioFilial?.trim();
    if (uf != null && uf.isNotEmpty) {
      return uf;
    }

    return '--';
  }
}
