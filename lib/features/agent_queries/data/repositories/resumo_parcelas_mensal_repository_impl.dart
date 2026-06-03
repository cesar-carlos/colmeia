import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_mensal_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_mensal_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy_extensions.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_labels.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_mensal_repository.dart';
import 'package:flutter/foundation.dart';

int _compareResumoParcelasMensalRowsSqlOrder(
  ResumoParcelasMensalRow a,
  ResumoParcelasMensalRow b,
) {
  final byEmpresa = a.codEmpresa.compareTo(b.codEmpresa);
  if (byEmpresa != 0) {
    return byEmpresa;
  }
  final byFilial = a.codFilial.compareTo(b.codFilial);
  if (byFilial != 0) {
    return byFilial;
  }
  final byAno = a.ano.compareTo(b.ano);
  return byAno != 0 ? byAno : a.mes.compareTo(b.mes);
}

class ResumoParcelasMensalRepositoryImpl
    implements ResumoParcelasMensalRepository {
  ResumoParcelasMensalRepositoryImpl(
    this._agentQueriesRepository,
  );

  static const String _operation = 'loadResumoParcelasMensal';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<List<ResumoParcelasMensalRow>>> load({
    required String userId,
    required String agentId,
    required ResumoParcelasMensalFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        List<ResumoParcelasMensalRow>
      >(
        message: validationError,
        operation: _operation,
        agentId: agentId.trim(),
      );
    }

    final periodAndFlagsParams = <String, Object?>{
      'dataVendaInicio': AgentQueriesSqlLocalDate.format(
        filter.dataVendaInicio,
      ),
      'dataVendaFim': AgentQueriesSqlLocalDate.format(filter.dataVendaFim),
      'origem': filter.trimmedOrigem,
      'geraFinanceiro': filter.trimmedGeraFinanceiro,
      'preVenda': filter.trimmedPreVenda,
    };
    final request = AgentSqlExecuteRequest(
      agentId: agentId,
      requestingUserId: userId,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      sql: ResumoParcelasMensalSql.query(
        codEmpresa: filter.codEmpresa,
        codFilial: filter.codFilial,
        codVendedor: filter.codVendedor,
      ),
      clientToken: clientToken,
      bridgeTimeoutMs:
          bridgeTimeoutMs ?? AppEnvironment.agentSqlBridgeLongTimeoutMs,
      namedParams: periodAndFlagsParams,
      executeOptions: const AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.preserve,
        preferDbStreaming: true,
        maxRows: AgentQueriesBoundedResultMaxRows.resumoParcelasMensal,
      ),
      useRelay: true,
      relayMode: AgentSqlRelayMode.streaming,
      skipTransportCache: cachePolicy.bypassTransportCache,
    );

    return AgentSqlRepositoryExecution.execute<List<ResumoParcelasMensalRow>>(
      agentQueriesRepository: _agentQueriesRepository,
      request: request,
      operation: _operation,
      agentId: agentId.trim(),
      unexpectedRowsLogMessage: 'Unexpected row shape for ResumoParcelasMensal',
      mapExecution: (executionResult) => _mapExecutionToRows(
        executionResult,
        agentId: agentId.trim(),
        filter: filter,
      ),
      cancelScope: cancelScope,
    );
  }

  List<ResumoParcelasMensalRow> _mapExecutionToRows(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
    required ResumoParcelasMensalFilter filter,
  }) {
    final rows =
        executionResult.rows
            .map(
              (row) => ResumoParcelasMensalRowModel.fromMap(row).toEntity(),
            )
            .toList()
          ..sort(_compareResumoParcelasMensalRowsSqlOrder);
    if (kDebugMode && rows.isNotEmpty) {
      final calendarOutOfRangeRowCount = rows
          .where(
            (r) => !ResumoParcelasMensalLabels.isValidCalendarYear(r.ano),
          )
          .length;
      final monthKeys = <String>{};
      final branchKeys = <String>{};
      for (final r in rows) {
        monthKeys.add('${r.ano}-${r.mes}');
        branchKeys.add('${r.codEmpresa}:${r.codFilial}');
      }
      AppLogger.debug(
        'ResumoParcelasMensal load summary',
        context: <String, Object?>{
          'operation': _operation,
          'agentId': agentId,
          'rowCount': rows.length,
          'anoMesFirst': rows.first.anoMes,
          'anoMesLast': rows.last.anoMes,
          'calendarOutOfRangeRowCount': calendarOutOfRangeRowCount,
          'distinctCalendarMonthKeyCount': monthKeys.length,
          'distinctBranchKeyCount': branchKeys.length,
          'sqlDimensionFiltersActive':
              filter.codEmpresa != null ||
              filter.codFilial != null ||
              filter.codVendedor != null,
        },
      );
    }
    return rows;
  }
}
