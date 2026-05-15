import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_warn_if_sql_rows_at_cap.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_total_vendas_municipio_filial_diario_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_total_vendas_municipio_filial_diario_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_diario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_diario_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_vendas_municipio_filial_diario_repository.dart';
import 'package:flutter/foundation.dart';

class ResumoTotalVendasMunicipioFilialDiarioRepositoryImpl
    implements ResumoTotalVendasMunicipioFilialDiarioRepository {
  ResumoTotalVendasMunicipioFilialDiarioRepositoryImpl(
    this._agentQueriesRepository,
  );

  static const int _defaultBridgeTimeoutMs = 120000;
  static const String _operation = 'loadResumoTotalVendasMunicipioFilialDiario';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<List<ResumoTotalVendasMunicipioFilialDiarioRow>>> load({
    required String userId,
    required String agentId,
    required ResumoTotalVendasMunicipioFilialDiarioFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        List<ResumoTotalVendasMunicipioFilialDiarioRow>
      >(
        message: validationError,
        operation: _operation,
        agentId: agentId.trim(),
      );
    }

    final request = AgentSqlExecuteRequest(
      agentId: agentId,
      requestingUserId: userId,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      sql: ResumoTotalVendasMunicipioFilialDiarioSql.query,
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
            .resumoTotalVendasMunicipioFilialDiario,
      ),
      useRelay: true,
      relayMode: AgentSqlRelayMode.streaming,
    );

    return AgentSqlRepositoryExecution.execute<
      List<ResumoTotalVendasMunicipioFilialDiarioRow>
    >(
      agentQueriesRepository: _agentQueriesRepository,
      request: request,
      operation: _operation,
      agentId: agentId.trim(),
      unexpectedRowsLogMessage:
          'Unexpected row shape for ResumoTotalVendasMunicipioFilialDiario',
      mapExecution: (executionResult) => _mapExecutionToRows(
        executionResult,
        agentId: agentId.trim(),
        filter: filter,
      ),
    );
  }

  List<ResumoTotalVendasMunicipioFilialDiarioRow> _mapExecutionToRows(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
    required ResumoTotalVendasMunicipioFilialDiarioFilter filter,
  }) {
    final rows = executionResult.rows
        .map(
          (row) => ResumoTotalVendasMunicipioFilialDiarioRowModel.fromMap(
            row,
          ).toEntity(),
        )
        .toList(growable: false);
    agentQueriesWarnIfSqlRowsAtCap(
      operation: _operation,
      agentId: agentId,
      returnedRowCount: rows.length,
      maxRows: AgentQueriesBoundedResultMaxRows
          .resumoTotalVendasMunicipioFilialDiario,
    );
    if (kDebugMode) {
      _logLoadSummary(
        rows,
        agentId: agentId,
        filter: filter,
      );
    }
    return rows;
  }

  void _logLoadSummary(
    List<ResumoTotalVendasMunicipioFilialDiarioRow> rows, {
    required String agentId,
    required ResumoTotalVendasMunicipioFilialDiarioFilter filter,
  }) {
    var totalSalesCount = 0;
    var totalSalesAmount = 0.0;
    for (final row in rows) {
      totalSalesCount += row.qtdVendas;
      totalSalesAmount += row.totalVenda;
    }

    AppLogger.debug(
      'ResumoTotalVendasMunicipioFilialDiario load summary',
      context: <String, Object?>{
        'operation': _operation,
        'agentId': agentId,
        'rowCount': rows.length,
        'filterStart': AgentQueriesSqlLocalDate.format(
          filter.dataVendaInicio,
        ),
        'filterEnd': AgentQueriesSqlLocalDate.format(filter.dataVendaFim),
        'totalSalesCount': totalSalesCount,
        'totalSalesAmount': totalSalesAmount,
      },
    );
  }
}
