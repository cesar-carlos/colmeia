import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_warn_if_sql_rows_at_cap.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_total_vendas_municipio_filial_periodo_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_total_vendas_municipio_filial_periodo_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_loaded_rows.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_vendas_municipio_filial_periodo_repository.dart';
import 'package:flutter/foundation.dart';

class ResumoTotalVendasMunicipioFilialPeriodoRepositoryImpl
    implements ResumoTotalVendasMunicipioFilialPeriodoRepository {
  ResumoTotalVendasMunicipioFilialPeriodoRepositoryImpl(
    this._agentQueriesRepository,
  );

  static const int _defaultBridgeTimeoutMs = 120000;
  static const String _operation =
      'loadResumoTotalVendasMunicipioFilialPeriodo';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<
    AppResult<AgentQueryLoadedRows<ResumoTotalVendasMunicipioFilialPeriodoRow>>
  >
  load({
    required String userId,
    required String agentId,
    required ResumoTotalVendasMunicipioFilialPeriodoFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        AgentQueryLoadedRows<ResumoTotalVendasMunicipioFilialPeriodoRow>
      >(
        message: validationError,
        operation: _operation,
        agentId: agentId.trim(),
      );
    }
    final trimmedAgentId = agentId.trim();
    final branchFilters = filter.branchesForAgent(trimmedAgentId);

    final request = AgentSqlExecuteRequest(
      agentId: agentId,
      requestingUserId: userId,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      sql: ResumoTotalVendasMunicipioFilialPeriodoSql.query(
        branches: branchFilters,
        codEmpresa: filter.codEmpresa,
        codFilial: filter.codFilial,
      ),
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs ?? _defaultBridgeTimeoutMs,
      namedParams: <String, Object?>{
        'dataVendaInicio': AgentQueriesSqlLocalDate.format(
          filter.dataVendaInicio,
        ),
        'dataVendaFim': AgentQueriesSqlLocalDate.format(filter.dataVendaFim),
        'origem': filter.trimmedOrigem,
        'geraFinanceiro': filter.trimmedGeraFinanceiro,
        'preVenda': filter.trimmedPreVenda,
      },
      executeOptions: const AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.preserve,
        preferDbStreaming: true,
        maxRows: AgentQueriesBoundedResultMaxRows
            .resumoTotalVendasMunicipioFilialPeriodo,
      ),
      useRelay: true,
      relayMode: AgentSqlRelayMode.streaming,
    );

    return AgentSqlRepositoryExecution.execute<
      AgentQueryLoadedRows<ResumoTotalVendasMunicipioFilialPeriodoRow>
    >(
      agentQueriesRepository: _agentQueriesRepository,
      request: request,
      operation: _operation,
      agentId: trimmedAgentId,
      unexpectedRowsLogMessage:
          'Unexpected row shape for ResumoTotalVendasMunicipioFilialPeriodo',
      mapExecution: (executionResult) => _mapExecutionToRows(
        executionResult,
        agentId: trimmedAgentId,
        filter: filter,
      ),
      cancelScope: cancelScope,
    );
  }

  AgentQueryLoadedRows<ResumoTotalVendasMunicipioFilialPeriodoRow>
  _mapExecutionToRows(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
    required ResumoTotalVendasMunicipioFilialPeriodoFilter filter,
  }) {
    final rows = executionResult.rows
        .map(
          (row) => ResumoTotalVendasMunicipioFilialPeriodoRowModel.fromMap(
            row,
          ).toEntity(),
        )
        .toList(growable: false);
    agentQueriesWarnIfSqlRowsAtCap(
      operation: _operation,
      agentId: agentId,
      returnedRowCount: executionResult.rowCount,
      maxRows: AgentQueriesBoundedResultMaxRows
          .resumoTotalVendasMunicipioFilialPeriodo,
    );
    if (kDebugMode) {
      _logLoadSummary(rows, agentId: agentId, filter: filter);
    }
    return AgentQueryLoadedRows<ResumoTotalVendasMunicipioFilialPeriodoRow>(
      rows: rows,
      sourceRowCount: executionResult.rowCount,
    );
  }

  void _logLoadSummary(
    List<ResumoTotalVendasMunicipioFilialPeriodoRow> rows, {
    required String agentId,
    required ResumoTotalVendasMunicipioFilialPeriodoFilter filter,
  }) {
    var totalSalesCount = 0;
    var totalSalesAmount = 0.0;
    for (final row in rows) {
      totalSalesCount += row.qtdVendas;
      totalSalesAmount += row.totalVenda;
    }

    AppLogger.debug(
      'ResumoTotalVendasMunicipioFilialPeriodo load summary',
      context: <String, Object?>{
        'operation': _operation,
        'agentId': agentId,
        'rowCount': rows.length,
        'filterStart': AgentQueriesSqlLocalDate.format(
          filter.dataVendaInicio,
        ),
        'filterEnd': AgentQueriesSqlLocalDate.format(filter.dataVendaFim),
        'codEmpresa': filter.codEmpresa,
        'codFilial': filter.codFilial,
        'totalSalesCount': totalSalesCount,
        'totalSalesAmount': totalSalesAmount,
      },
    );
  }
}
