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
import 'package:flutter/foundation.dart';

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
    this.cancelled = false,
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
  final bool cancelled;

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

class SalesLiveMapLoadCancelToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
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
  static const int geolocationMaxConcurrency = 6;
  static const int _branchLocationCacheMaxEntries = 5000;
  static const Duration _branchLocationCacheTtl = Duration(minutes: 10);

  final LoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase
  _loadResumoTotalVendasMunicipioFilialPeriodoAcrossAgents;
  final AppBrazilStoreSalesPointResolver _pointResolver;
  final DateTime Function()? _now;
  final Map<String, _SalesLiveMapCachedBranchLocation> _branchLocationCache =
      <String, _SalesLiveMapCachedBranchLocation>{};

  Future<SalesLiveMapLoadResult> call({
    required String userId,
    required SalesLiveMapFilter filter,
    SalesLiveMapLoadCancelToken? cancelToken,
  }) async {
    final totalStopwatch = _startTraceStopwatch();
    final now = _resolveNow();
    if (cancelToken?.isCancelled ?? false) {
      return _cancelledResult(refreshedAt: now);
    }
    final queryFilter = filter.toAgentQueryFilter(now: now);
    final selectedAgentIds =
        filter.selectedAgentIds ?? queryFilter.selectedAgentIds;
    final queryStopwatch = _startTraceStopwatch();
    final result =
        await _loadResumoTotalVendasMunicipioFilialPeriodoAcrossAgents(
          userId: userId,
          filter: queryFilter,
          selectedAgentIds: selectedAgentIds,
          bridgeTimeoutMs: bridgeTimeoutMs,
        );
    _logTrace(
      'Sales live map SQL report loaded',
      <String, Object?>{
        'elapsedMs': queryStopwatch?.elapsedMilliseconds,
        'selectedAgentCount': selectedAgentIds?.length ?? 0,
        'selectedBranchCount': queryFilter.selectedBranches.length,
        'reportElapsedMs': result.fold(
          (report) => report.totalElapsedMs,
          (_) => null,
        ),
      },
    );
    if (cancelToken?.isCancelled ?? false) {
      return _cancelledResult(refreshedAt: now);
    }

    return result.fold(
      (report) async {
        _logParticipantMetrics(report);
        if (cancelToken?.isCancelled ?? false) {
          return _cancelledResult(refreshedAt: now);
        }
        final mapped = await _mapReport(
          report,
          filter: filter,
          refreshedAt: now,
          cancelToken: cancelToken,
        );
        _logTrace(
          'Sales live map load completed',
          <String, Object?>{
            'elapsedMs': totalStopwatch?.elapsedMilliseconds,
            'pointCount': mapped.points.length,
            'branchOptionCount': mapped.branchOptions.length,
            'totalBranchCount': mapped.totalBranchCount,
            'plannedAgentCount': mapped.plannedAgentCount,
            'queriedAgentCount': mapped.queriedAgentCount,
          },
        );
        return mapped;
      },
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
    SalesLiveMapLoadCancelToken? cancelToken,
  }) async {
    if (cancelToken?.isCancelled ?? false) {
      return _cancelledResult(refreshedAt: refreshedAt);
    }
    final aggregateStopwatch = _startTraceStopwatch();
    final successfulParticipants = report.participants
        .where((participant) => participant.isSuccess)
        .length;
    final returnedRowCount = _returnedRowCount(report);
    final sourceRowCount = _sourceRowCount(report);
    final aggregates = _aggregateRows(report.participants);
    final branchOptions = aggregates
        .map((aggregate) => aggregate.toBranchOption())
        .toList(growable: false);
    final visibleAggregates = _filterAggregatesByBranch(aggregates, filter);
    _logTrace(
      'Sales live map rows aggregated',
      <String, Object?>{
        'elapsedMs': aggregateStopwatch?.elapsedMilliseconds,
        'reportElapsedMs': report.totalElapsedMs,
        'plannedAgentCount': report.plannedTargets.length,
        'participantCount': report.participants.length,
        'successfulParticipantCount': successfulParticipants,
        'failedAgentCount': report.failedAgentIds.length,
        'missingClientTokenAgentCount': report.missingClientTokenTargets.length,
        'skippedOfflineAgentCount':
            report.skippedDueToHubPresenceTargets.length,
        'returnedRowCount': returnedRowCount,
        'sourceRowCount': sourceRowCount,
        'rowCapReachedAgentCount': _rowCapReachedAgentCount(report),
        'aggregateCount': aggregates.length,
        'visibleAggregateCount': visibleAggregates.length,
      },
    );
    if (cancelToken?.isCancelled ?? false) {
      return _cancelledResult(refreshedAt: refreshedAt);
    }
    final geolocationStopwatch = _startTraceStopwatch();
    final geolocation = await _resolveBranchPoints(
      visibleAggregates,
      refreshedAt: refreshedAt,
      cancelToken: cancelToken,
    );
    final points = geolocation.points;
    if (geolocation.cancelled) {
      return _cancelledResult(refreshedAt: refreshedAt);
    }
    _logTrace(
      'Sales live map branch geolocation completed',
      <String, Object?>{
        'elapsedMs': geolocationStopwatch?.elapsedMilliseconds,
        'inputBranchCount': visibleAggregates.length,
        'pointCount': points.length,
        'maxConcurrency': _geolocationConcurrencyFor(
          visibleAggregates.length,
        ),
        'cacheHitCount': geolocation.cacheHitCount,
        'cacheMissCount': geolocation.cacheMissCount,
        'cacheUnresolvedHitCount': geolocation.cacheUnresolvedHitCount,
        'resolvedAndCachedCount': geolocation.resolvedAndCachedCount,
        'unresolvedAndCachedCount': geolocation.unresolvedAndCachedCount,
      },
    );
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

  Future<_SalesLiveMapGeolocationResult> _resolveBranchPoints(
    List<_SalesLiveMapBranchAggregate> aggregates, {
    required DateTime refreshedAt,
    SalesLiveMapLoadCancelToken? cancelToken,
  }) async {
    if (aggregates.isEmpty) {
      return const _SalesLiveMapGeolocationResult();
    }

    final pointsByIndex = List<AppBrazilStoreSalesPoint?>.filled(
      aggregates.length,
      null,
    );
    final pending = <({int index, _SalesLiveMapBranchAggregate aggregate})>[];
    var cacheHitCount = 0;
    var cacheUnresolvedHitCount = 0;

    for (var i = 0; i < aggregates.length; i++) {
      if (cancelToken?.isCancelled ?? false) {
        return const _SalesLiveMapGeolocationResult(cancelled: true);
      }

      final aggregate = aggregates[i];
      final cached = _readCachedBranchLocation(
        aggregate,
        now: refreshedAt,
      );
      if (cached == null) {
        pending.add((index: i, aggregate: aggregate));
        continue;
      }

      if (cached.resolved) {
        cacheHitCount += 1;
        pointsByIndex[i] = cached.toPoint(aggregate);
      } else {
        cacheUnresolvedHitCount += 1;
      }
    }

    var resolvedAndCachedCount = 0;
    var unresolvedAndCachedCount = 0;
    if (pending.isNotEmpty) {
      final resolved = await _pointResolver.resolveAllWithDetails(
        pending.map((item) => item.aggregate.toPointSource()),
        maxConcurrent: _geolocationConcurrencyFor(pending.length),
      );
      if (cancelToken?.isCancelled ?? false) {
        return const _SalesLiveMapGeolocationResult(cancelled: true);
      }

      final resolvedById = <String, AppBrazilStoreSalesResolvedPoint>{
        for (final item in resolved) item.point.id: item,
      };
      for (final item in pending) {
        final resolvedPoint = resolvedById[item.aggregate.id];
        if (resolvedPoint == null) {
          unresolvedAndCachedCount += 1;
          _writeCachedBranchLocation(
            item.aggregate,
            _SalesLiveMapCachedBranchLocation.unresolved(
              sourceSignature: item.aggregate.locationSourceSignature,
              cachedAt: refreshedAt,
            ),
          );
          _logBranchGeolocation(item.aggregate, null);
          continue;
        }

        resolvedAndCachedCount += 1;
        final cachedLocation = _SalesLiveMapCachedBranchLocation.fromResolved(
          sourceSignature: item.aggregate.locationSourceSignature,
          cachedAt: refreshedAt,
          resolved: resolvedPoint,
        );
        _writeCachedBranchLocation(item.aggregate, cachedLocation);
        pointsByIndex[item.index] = cachedLocation.toPoint(item.aggregate);
      }
    }

    return _SalesLiveMapGeolocationResult(
      points: pointsByIndex.whereType<AppBrazilStoreSalesPoint>().toList(
        growable: false,
      ),
      cacheHitCount: cacheHitCount,
      cacheMissCount: pending.length,
      cacheUnresolvedHitCount: cacheUnresolvedHitCount,
      resolvedAndCachedCount: resolvedAndCachedCount,
      unresolvedAndCachedCount: unresolvedAndCachedCount,
    );
  }

  _SalesLiveMapCachedBranchLocation? _readCachedBranchLocation(
    _SalesLiveMapBranchAggregate aggregate, {
    required DateTime now,
  }) {
    final cached = _branchLocationCache[aggregate.id];
    if (cached == null) {
      return null;
    }
    if (cached.isExpired(now, ttl: _branchLocationCacheTtl) ||
        cached.sourceSignature != aggregate.locationSourceSignature) {
      _branchLocationCache.remove(aggregate.id);
      return null;
    }
    return cached;
  }

  void _writeCachedBranchLocation(
    _SalesLiveMapBranchAggregate aggregate,
    _SalesLiveMapCachedBranchLocation location,
  ) {
    _branchLocationCache.remove(aggregate.id);
    _branchLocationCache[aggregate.id] = location;
    while (_branchLocationCache.length > _branchLocationCacheMaxEntries) {
      _branchLocationCache.remove(_branchLocationCache.keys.first);
    }
  }

  void _logParticipantMetrics(
    AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>
    report,
  ) {
    if (!_shouldTracePerformance) {
      return;
    }

    AppLogger.info(
      'Sales live map agent SQL participants',
      context: <String, Object?>{
        'operation': 'LoadSalesLiveMapUseCase',
        'participantCount': report.participants.length,
        'participants': report.participants
            .map(
              (participant) => <String, Object?>{
                'agentId': participant.agentId,
                'displayName': participant.displayName,
                'elapsedMs': participant.elapsedMs,
                'rowCount': participant.rows.length,
                'sourceRowCount': participant.sourceRowCount,
                'success': participant.isSuccess,
                'failureType': participant.failure?.runtimeType.toString(),
                'rowCapReached': participant.reachedSourceRowLimit(
                  AgentQueriesBoundedResultMaxRows
                      .resumoTotalVendasMunicipioFilialPeriodo,
                ),
              },
            )
            .toList(growable: false),
      },
    );
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

  SalesLiveMapLoadResult _cancelledResult({
    required DateTime refreshedAt,
  }) {
    _logTrace(
      'Sales live map load cancelled before local processing completed',
      <String, Object?>{'refreshedAt': refreshedAt.toIso8601String()},
    );
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
      refreshedAt: refreshedAt,
      cancelled: true,
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

  Stopwatch? _startTraceStopwatch() {
    if (!_shouldTracePerformance) {
      return null;
    }
    return Stopwatch()..start();
  }

  void _logTrace(String message, Map<String, Object?> context) {
    if (!_shouldTracePerformance) {
      return;
    }
    AppLogger.info(
      message,
      context: <String, Object?>{
        'operation': 'LoadSalesLiveMapUseCase',
        ...context,
      },
    );
  }

  bool get _shouldTracePerformance => kDebugMode || kProfileMode;

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

  int _returnedRowCount(
    AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>
    report,
  ) {
    return report.participants.fold<int>(
      0,
      (total, participant) => total + participant.rows.length,
    );
  }

  int _sourceRowCount(
    AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>
    report,
  ) {
    return report.participants.fold<int>(
      0,
      (total, participant) => total + participant.sourceRowCount,
    );
  }

  int _geolocationConcurrencyFor(int branchCount) {
    if (branchCount <= 1) {
      return 1;
    }
    return branchCount < geolocationMaxConcurrency
        ? branchCount
        : geolocationMaxConcurrency;
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

  String get locationSourceSignature {
    return <String>[
      _normalizeLocationPart(ufMunicipioFilial),
      _normalizeLocationPart(nomeMunicipioFilial),
      _normalizeLocationPart(cepFilial),
      _normalizeLocationPart(codigoIbgeMunicipioFilial),
    ].join('|');
  }

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

  static String _normalizeLocationPart(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return '';
    }
    return trimmed.toUpperCase();
  }
}

class _SalesLiveMapGeolocationResult {
  const _SalesLiveMapGeolocationResult({
    this.points = const <AppBrazilStoreSalesPoint>[],
    this.cacheHitCount = 0,
    this.cacheMissCount = 0,
    this.cacheUnresolvedHitCount = 0,
    this.resolvedAndCachedCount = 0,
    this.unresolvedAndCachedCount = 0,
    this.cancelled = false,
  });

  final List<AppBrazilStoreSalesPoint> points;
  final int cacheHitCount;
  final int cacheMissCount;
  final int cacheUnresolvedHitCount;
  final int resolvedAndCachedCount;
  final int unresolvedAndCachedCount;
  final bool cancelled;
}

class _SalesLiveMapCachedBranchLocation {
  const _SalesLiveMapCachedBranchLocation({
    required this.sourceSignature,
    required this.cachedAt,
    required this.resolved,
    this.uf,
    this.latitude,
    this.longitude,
    this.municipalityCode,
    this.city,
    this.locationResolution,
  });

  factory _SalesLiveMapCachedBranchLocation.fromResolved({
    required String sourceSignature,
    required DateTime cachedAt,
    required AppBrazilStoreSalesResolvedPoint resolved,
  }) {
    final point = resolved.point;
    return _SalesLiveMapCachedBranchLocation(
      sourceSignature: sourceSignature,
      cachedAt: cachedAt,
      resolved: true,
      uf: point.uf,
      latitude: point.latitude,
      longitude: point.longitude,
      municipalityCode: point.municipalityCode,
      city: point.city,
      locationResolution: point.locationResolution,
    );
  }

  const _SalesLiveMapCachedBranchLocation.unresolved({
    required this.sourceSignature,
    required this.cachedAt,
  }) : resolved = false,
       uf = null,
       latitude = null,
       longitude = null,
       municipalityCode = null,
       city = null,
       locationResolution = null;

  final String sourceSignature;
  final DateTime cachedAt;
  final bool resolved;
  final String? uf;
  final double? latitude;
  final double? longitude;
  final String? municipalityCode;
  final String? city;
  final AppBrazilStoreSalesLocationResolution? locationResolution;

  bool isExpired(DateTime now, {required Duration ttl}) {
    return now.difference(cachedAt) > ttl;
  }

  AppBrazilStoreSalesPoint? toPoint(_SalesLiveMapBranchAggregate aggregate) {
    final resolvedUf = uf;
    final resolvedLatitude = latitude;
    final resolvedLongitude = longitude;
    if (!resolved ||
        resolvedUf == null ||
        resolvedLatitude == null ||
        resolvedLongitude == null) {
      return null;
    }

    return AppBrazilStoreSalesPoint(
      id: aggregate.id,
      name: aggregate.name,
      uf: resolvedUf,
      latitude: resolvedLatitude,
      longitude: resolvedLongitude,
      salesAmount: aggregate.totalVenda,
      salesCount: aggregate.qtdVendas,
      municipalityCode: municipalityCode,
      city: city,
      locationResolution: locationResolution,
      subtitle:
          'Agente ${aggregate.agentName} - Empresa ${aggregate.codEmpresa} - Filial ${aggregate.codFilial}',
      payload: aggregate,
    );
  }
}
