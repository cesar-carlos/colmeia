import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_branch_aggregate.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_location_diagnostics.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:flutter/foundation.dart';

const String _kOperation = 'LoadSalesLiveMapUseCase';

/// Diagnostic logging and trace stopwatch for `LoadSalesLiveMapUseCase`.
///
/// All info/trace logs are gated by [shouldTracePerformance] so production
/// release builds stay quiet; debug-level structured logs (per-branch
/// geolocation, location summary) always emit through `AppLogger.debug` —
/// consumers/sinks filter further.
class SalesLiveMapDiagnosticsLogger {
  const SalesLiveMapDiagnosticsLogger();

  bool get shouldTracePerformance => kDebugMode || kProfileMode;

  /// Returns a started `Stopwatch` when tracing is enabled, or `null`
  /// otherwise so the caller skips work for production builds.
  Stopwatch? startTraceStopwatch() {
    if (!shouldTracePerformance) {
      return null;
    }
    return Stopwatch()..start();
  }

  /// Emits an info-level trace under the use case operation namespace.
  /// No-op when [shouldTracePerformance] is false.
  void trace(String message, Map<String, Object?> context) {
    if (!shouldTracePerformance) {
      return;
    }
    AppLogger.info(
      message,
      context: <String, Object?>{'operation': _kOperation, ...context},
    );
  }

  /// Logs participants of the sales SQL execution report for triage.
  /// No-op when tracing is disabled.
  void logParticipantMetrics(
    AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>
    report,
  ) {
    if (!shouldTracePerformance) {
      return;
    }

    AppLogger.info(
      'Sales live map agent SQL participants',
      context: <String, Object?>{
        'operation': _kOperation,
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

  /// Debug-level structured log for a single branch geolocation result.
  void logBranchGeolocation(
    SalesLiveMapBranchAggregate aggregate,
    SalesLiveMapResolvedPoint? resolved,
  ) {
    final point = resolved?.point;
    AppLogger.debug(
      'Sales live map branch geolocation resolved',
      context: <String, Object?>{
        'operation': _kOperation,
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

  /// Debug-level aggregate summary of geolocation resolutions for this run.
  void logLocationSummary(SalesLiveMapLocationDiagnostics diagnostics) {
    if (!diagnostics.hasAnySignal) {
      return;
    }

    AppLogger.debug(
      'Sales live map geolocation summary',
      context: <String, Object?>{
        'operation': _kOperation,
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
}
