import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_branch_aggregate.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_branch_aggregator.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_diagnostics_logger.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_geolocator.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_cancel_token.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_failure_reason.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_result.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_location_diagnostics.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_mapped_result.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_progressive_emit_policy.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_result_builder.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';

/// Maps SQL execution reports into progressive live-map emissions, merging
/// branch aggregates with geolocation in staged waves.
class SalesLiveMapReportMapper {
  SalesLiveMapReportMapper({
    required this._branchAggregator,
    required this._diagnosticsLogger,
    required this._geolocator,
    required this._emitPolicy,
  });

  final SalesLiveMapBranchAggregator _branchAggregator;
  final SalesLiveMapDiagnosticsLogger _diagnosticsLogger;
  final SalesLiveMapGeolocator _geolocator;
  final SalesLiveMapProgressiveEmitPolicy _emitPolicy;

  Stream<SalesLiveMapMappedResult> emitMappedReports(
    AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>?
    salesReport, {
    required SalesLiveMapFilter filter,
    required DateTime refreshedAt,
    CadastroFilialAcrossAgentsPageResult? catalogResult,
    AppFailure? salesFailure,
    AppFailure? catalogFailure,
    SalesLiveMapLoadCancelToken? cancelToken,
    bool salesDataPending = false,
    bool allowPartialGeoReuse = false,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
  }) async* {
    final mapStopwatch = _diagnosticsLogger.startTraceStopwatch();
    if (cancelToken?.isCancelled ?? false) {
      yield SalesLiveMapMappedResult(
        result: _emitPolicy.cancelledResult(refreshedAt: refreshedAt),
      );
      return;
    }
    final aggregateStopwatch = _diagnosticsLogger.startTraceStopwatch();
    final catalogReport = catalogResult?.report;
    final AgentQueryExecutionReport<dynamic>? baseReport =
        catalogReport ?? salesReport;
    if (baseReport == null) {
      yield SalesLiveMapMappedResult(
        result: SalesLiveMapResultBuilder.empty(refreshedAt: refreshedAt),
      );
      return;
    }
    final successfulParticipants = baseReport.participants
        .where((participant) => participant.isSuccess)
        .length;
    final returnedRowCount = _returnedRowCount(baseReport);
    final sourceRowCount = _sourceRowCount(baseReport);
    final agentDiagnostics = salesReport == null
        ? (
            salesAgentCount: 0,
            noSalesAgentOptions: const <SalesLiveMapAgentOption>[],
          )
        : _agentDiagnostics(salesReport);
    final salesUnavailableLabelsByAgentId = _branchAggregator
        .salesUnavailableLabelsByAgentId(
          catalogReport: catalogReport,
          salesReport: salesReport,
          salesFailure: salesFailure,
        );
    final aggregates = catalogReport == null
        ? _branchAggregator.aggregateFromSalesReport(salesReport!.participants)
        : _branchAggregator.aggregateFromCatalog(
            catalogReport: catalogReport,
            salesReport: salesReport,
            salesUnavailableLabelsByAgentId: salesUnavailableLabelsByAgentId,
            salesDataPending: salesDataPending,
          );
    final branchOptions = aggregates
        .map((aggregate) => aggregate.toBranchOption())
        .toList(growable: false);
    final visibleAggregates = _branchAggregator.filterByBranchSelection(
      aggregates,
      filter,
    );
    final failedCatalogAgentCount = catalogReport?.failedAgentIds.length ?? 0;
    final failedSalesAgentCount =
        salesReport?.failedAgentIds.length ??
        (salesFailure == null ? 0 : baseReport.plannedTargets.length);
    final failedAgentCount = _branchAggregator.combinedFailedAgentCount(
      catalogReport: catalogReport,
      salesReport: salesReport,
      catalogFailure: catalogFailure,
      salesFailure: salesFailure,
      plannedTargets: baseReport.plannedTargets.length,
    );
    final salesBranchCount = visibleAggregates
        .where((aggregate) => aggregate.qtdVendas > 0)
        .length;
    final salesPendingBranchCount = salesDataPending
        ? visibleAggregates.length
        : 0;
    final salesUnavailableBranchCount = salesDataPending
        ? 0
        : visibleAggregates
              .where((aggregate) => aggregate.salesDataUnavailable)
              .length;
    final noSalesBranchCount = salesDataPending
        ? 0
        : visibleAggregates
              .where(
                (aggregate) =>
                    !aggregate.salesDataUnavailable && aggregate.qtdVendas == 0,
              )
              .length;
    final zeroedBranchCount = noSalesBranchCount + salesUnavailableBranchCount;
    _diagnosticsLogger.trace(
      'Sales live map rows aggregated',
      <String, Object?>{
        'elapsedMs': aggregateStopwatch?.elapsedMilliseconds,
        'reportElapsedMs': baseReport.totalElapsedMs,
        'plannedAgentCount': baseReport.plannedTargets.length,
        'participantCount': baseReport.participants.length,
        'successfulParticipantCount': successfulParticipants,
        'failedAgentCount': failedAgentCount,
        'failedCatalogAgentCount': failedCatalogAgentCount,
        'failedSalesAgentCount': failedSalesAgentCount,
        'missingClientTokenAgentCount':
            baseReport.missingClientTokenTargets.length,
        'skippedOfflineAgentCount':
            baseReport.skippedDueToHubPresenceTargets.length,
        'returnedRowCount': returnedRowCount,
        'sourceRowCount': sourceRowCount,
        'rowCapReachedAgentCount': salesReport == null
            ? 0
            : _branchAggregator.rowCapReachedAgentCount(salesReport),
        'aggregateCount': aggregates.length,
        'visibleAggregateCount': visibleAggregates.length,
        'salesBranchCount': salesBranchCount,
        'salesPendingBranchCount': salesPendingBranchCount,
        'noSalesBranchCount': noSalesBranchCount,
        'salesUnavailableBranchCount': salesUnavailableBranchCount,
        'zeroedBranchCount': zeroedBranchCount,
      },
    );
    if (cancelToken?.isCancelled ?? false) {
      yield SalesLiveMapMappedResult(
        result: _emitPolicy.cancelledResult(refreshedAt: refreshedAt),
      );
      return;
    }

    if (branchOptions.isNotEmpty) {
      yield _mappedResultFromGeolocation(
        geolocation: const SalesLiveMapGeolocationResult(),
        mapStopwatch: mapStopwatch,
        geoDurationMs: 0,
        branchOptions: branchOptions,
        visibleAggregates: visibleAggregates,
        baseReport: baseReport,
        salesReport: salesReport,
        agentDiagnostics: agentDiagnostics,
        failedAgentCount: failedAgentCount,
        salesBranchCount: salesBranchCount,
        salesPendingBranchCount: salesPendingBranchCount,
        salesUnavailableBranchCount: salesUnavailableBranchCount,
        noSalesBranchCount: noSalesBranchCount,
        zeroedBranchCount: zeroedBranchCount,
        salesDataPending: salesDataPending,
        failedCatalogAgentCount: failedCatalogAgentCount,
        failedSalesAgentCount: failedSalesAgentCount,
        paginationStalledAgentCount:
            catalogResult?.paginationStalledAgentIds.length ?? 0,
        refreshedAt: refreshedAt,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      );
      if (cancelToken?.isCancelled ?? false) {
        yield SalesLiveMapMappedResult(
          result: _emitPolicy.cancelledResult(refreshedAt: refreshedAt),
        );
        return;
      }
    }

    var geoDurationMs = 0;
    final sqlGeolocationStopwatch = _diagnosticsLogger.startTraceStopwatch();
    final sqlGeolocation = await _geolocator.resolveSqlMunicipalityPoints(
      visibleAggregates,
      refreshedAt: refreshedAt,
      cancelToken: cancelToken,
    );
    geoDurationMs += sqlGeolocationStopwatch?.elapsedMilliseconds ?? 0;
    if (sqlGeolocation.cancelled) {
      yield SalesLiveMapMappedResult(
        result: _emitPolicy.cancelledResult(refreshedAt: refreshedAt),
      );
      return;
    }
    _diagnosticsLogger.trace(
      'Sales live map SQL municipality geolocation completed',
      <String, Object?>{
        'elapsedMs': sqlGeolocationStopwatch?.elapsedMilliseconds,
        'inputBranchCount': visibleAggregates.length,
        'pointCount': sqlGeolocation.points.length,
        'cacheHitCount': sqlGeolocation.cacheHitCount,
        'cacheMissCount': sqlGeolocation.cacheMissCount,
      },
    );
    yield _mappedResultFromGeolocation(
      geolocation: sqlGeolocation,
      mapStopwatch: mapStopwatch,
      geoDurationMs: geoDurationMs,
      branchOptions: branchOptions,
      visibleAggregates: visibleAggregates,
      baseReport: baseReport,
      salesReport: salesReport,
      agentDiagnostics: agentDiagnostics,
      failedAgentCount: failedAgentCount,
      salesBranchCount: salesBranchCount,
      salesPendingBranchCount: salesPendingBranchCount,
      salesUnavailableBranchCount: salesUnavailableBranchCount,
      noSalesBranchCount: noSalesBranchCount,
      zeroedBranchCount: zeroedBranchCount,
      salesDataPending: salesDataPending,
      failedCatalogAgentCount: failedCatalogAgentCount,
      failedSalesAgentCount: failedSalesAgentCount,
      paginationStalledAgentCount:
          catalogResult?.paginationStalledAgentIds.length ?? 0,
      refreshedAt: refreshedAt,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
    );

    final fullGeolocationStopwatch = _diagnosticsLogger.startTraceStopwatch();
    final geolocation = await _geolocator.resolveBranchPoints(
      visibleAggregates,
      refreshedAt: refreshedAt,
      cancelToken: cancelToken,
      allowPartialGeoReuse: allowPartialGeoReuse,
    );
    geoDurationMs += fullGeolocationStopwatch?.elapsedMilliseconds ?? 0;
    final points = geolocation.points;
    if (geolocation.cancelled) {
      yield SalesLiveMapMappedResult(
        result: _emitPolicy.cancelledResult(refreshedAt: refreshedAt),
      );
      return;
    }
    if (salesDataPending) {
      _geolocator.recordPartialGeoSnapshot(
        aggregates: visibleAggregates,
        points: points,
      );
    }
    _diagnosticsLogger.trace(
      'Sales live map branch geolocation completed',
      <String, Object?>{
        'elapsedMs': fullGeolocationStopwatch?.elapsedMilliseconds,
        'inputBranchCount': visibleAggregates.length,
        'pointCount': points.length,
        'cacheHitCount': geolocation.cacheHitCount,
        'cacheMissCount': geolocation.cacheMissCount,
        'cacheUnresolvedHitCount': geolocation.cacheUnresolvedHitCount,
        'resolvedAndCachedCount': geolocation.resolvedAndCachedCount,
        'unresolvedAndCachedCount': geolocation.unresolvedAndCachedCount,
        'partialGeoReuseCount': geolocation.partialGeoReuseCount,
      },
    );
    yield _mappedResultFromGeolocation(
      geolocation: geolocation,
      mapStopwatch: mapStopwatch,
      geoDurationMs: geoDurationMs,
      branchOptions: branchOptions,
      visibleAggregates: visibleAggregates,
      baseReport: baseReport,
      salesReport: salesReport,
      agentDiagnostics: agentDiagnostics,
      failedAgentCount: failedAgentCount,
      salesBranchCount: salesBranchCount,
      salesPendingBranchCount: salesPendingBranchCount,
      salesUnavailableBranchCount: salesUnavailableBranchCount,
      noSalesBranchCount: noSalesBranchCount,
      zeroedBranchCount: zeroedBranchCount,
      salesDataPending: salesDataPending,
      failedCatalogAgentCount: failedCatalogAgentCount,
      failedSalesAgentCount: failedSalesAgentCount,
      paginationStalledAgentCount:
          catalogResult?.paginationStalledAgentIds.length ?? 0,
      refreshedAt: refreshedAt,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
    );
  }

  static List<AppFailure> collectAgentQueryFailures({
    required AgentQueryExecutionReport<dynamic> baseReport,
    AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>?
    salesReport,
  }) {
    final failures = <AppFailure>[];
    for (final participant in baseReport.participants) {
      final failure = participant.failure;
      if (failure != null) {
        failures.add(failure);
      }
    }
    if (salesReport != null) {
      for (final participant in salesReport.participants) {
        final failure = participant.failure;
        if (failure != null) {
          failures.add(failure);
        }
      }
    }
    return List<AppFailure>.unmodifiable(failures);
  }

  SalesLiveMapMappedResult _mappedResultFromGeolocation({
    required SalesLiveMapGeolocationResult geolocation,
    required Stopwatch? mapStopwatch,
    required int geoDurationMs,
    required List<SalesLiveMapBranchOption> branchOptions,
    required List<SalesLiveMapBranchAggregate> visibleAggregates,
    required AgentQueryExecutionReport<dynamic> baseReport,
    required AgentQueryExecutionReport<
      ResumoTotalVendasMunicipioFilialPeriodoRow
    >?
    salesReport,
    required ({
      int salesAgentCount,
      List<SalesLiveMapAgentOption> noSalesAgentOptions,
    })
    agentDiagnostics,
    required int failedAgentCount,
    required int salesBranchCount,
    required int salesPendingBranchCount,
    required int salesUnavailableBranchCount,
    required int noSalesBranchCount,
    required int zeroedBranchCount,
    required bool salesDataPending,
    required int failedCatalogAgentCount,
    required int failedSalesAgentCount,
    required int paginationStalledAgentCount,
    required DateTime refreshedAt,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
  }) {
    final points = geolocation.points;
    final locationDiagnostics = SalesLiveMapLocationDiagnostics.fromPoints(
      points: points,
      totalBranchCount: visibleAggregates.length,
    );
    _diagnosticsLogger.logLocationSummary(locationDiagnostics);
    final mappedMunicipalityCount =
        SalesLiveMapResultBuilder.mappedMunicipalityCount(points);
    final unmappedBranchOptions =
        SalesLiveMapResultBuilder.unmappedBranchOptions(
          visibleAggregates: visibleAggregates,
          points: points,
        );
    final loadFailed = baseReport.requiresClientTokenSetup;
    return SalesLiveMapMappedResult(
      result: SalesLiveMapLoadResult(
        points: points,
        branchOptions: branchOptions,
        unmappedBranchOptions: unmappedBranchOptions,
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
        queriedAgentCount: baseReport.participants.length,
        plannedAgentCount: baseReport.plannedTargets.length,
        failedAgentCount: failedAgentCount,
        missingClientTokenAgentCount:
            baseReport.missingClientTokenTargets.length,
        skippedOfflineAgentCount:
            baseReport.skippedDueToHubPresenceTargets.length,
        rowCapReachedAgentCount: salesReport == null
            ? 0
            : _branchAggregator.rowCapReachedAgentCount(salesReport),
        paginationStalledAgentCount: paginationStalledAgentCount,
        salesAgentCount: agentDiagnostics.salesAgentCount,
        catalogBranchCount: visibleAggregates.length,
        salesBranchCount: salesBranchCount,
        zeroedBranchCount: zeroedBranchCount,
        noSalesBranchCount: noSalesBranchCount,
        salesUnavailableBranchCount: salesUnavailableBranchCount,
        salesDataPending: salesDataPending,
        salesPendingBranchCount: salesPendingBranchCount,
        failedCatalogAgentCount: failedCatalogAgentCount,
        failedSalesAgentCount: failedSalesAgentCount,
        noSalesAgentOptions: agentDiagnostics.noSalesAgentOptions,
        failedAgentOptions:
            SalesLiveMapResultBuilder.failedAgentOptionsFromReports(
              baseReport: baseReport,
              salesReport: salesReport,
            ),
        missingClientTokenAgentOptions:
            SalesLiveMapResultBuilder.agentOptionsFromTargets(
              baseReport.missingClientTokenTargets,
            ),
        skippedOfflineAgentOptions:
            SalesLiveMapResultBuilder.agentOptionsFromTargets(
              baseReport.skippedDueToHubPresenceTargets,
            ),
        locationDiagnostics: locationDiagnostics,
        loadFailed: loadFailed,
        loadFailureReason: loadFailed
            ? SalesLiveMapLoadFailureReason.missingClientTokenSetup
            : null,
        refreshedAt: refreshedAt,
        partialGeoReuseCount: geolocation.partialGeoReuseCount,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        agentQueryFailures: collectAgentQueryFailures(
          baseReport: baseReport,
          salesReport: salesReport,
        ),
      ),
      mapDurationMs: mapStopwatch?.elapsedMilliseconds ?? 0,
      geoDurationMs: geoDurationMs,
    );
  }

  ({
    int salesAgentCount,
    List<SalesLiveMapAgentOption> noSalesAgentOptions,
  })
  _agentDiagnostics(
    AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>
    report,
  ) {
    final plannedAgentIds = report.plannedTargets
        .map((target) => target.agentId)
        .toSet();
    var salesAgentCount = 0;
    final noSalesAgentOptions = <SalesLiveMapAgentOption>[];

    for (final participant in report.participants) {
      if (!plannedAgentIds.contains(participant.agentId) ||
          !participant.isSuccess) {
        continue;
      }
      if (participant.rows.isEmpty) {
        noSalesAgentOptions.add(
          SalesLiveMapAgentOption(
            id: participant.agentId,
            name: participant.displayName,
          ),
        );
      } else {
        salesAgentCount += 1;
      }
    }

    noSalesAgentOptions.sort((left, right) => left.name.compareTo(right.name));
    return (
      salesAgentCount: salesAgentCount,
      noSalesAgentOptions: List<SalesLiveMapAgentOption>.unmodifiable(
        noSalesAgentOptions,
      ),
    );
  }

  int _returnedRowCount<Row>(AgentQueryExecutionReport<Row> report) {
    return report.participants.fold<int>(
      0,
      (total, participant) => total + participant.rows.length,
    );
  }

  int _sourceRowCount<Row>(AgentQueryExecutionReport<Row> report) {
    return report.participants.fold<int>(
      0,
      (total, participant) => total + participant.sourceRowCount,
    );
  }
}
