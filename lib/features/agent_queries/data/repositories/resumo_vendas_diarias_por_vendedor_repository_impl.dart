import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_vendas_diarias_por_vendedor_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_vendas_diarias_por_vendedor_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_repository.dart';

class ResumoVendasDiariasPorVendedorRepositoryImpl
    implements ResumoVendasDiariasPorVendedorRepository {
  ResumoVendasDiariasPorVendedorRepositoryImpl(
    this._agentQueriesRepository,
  );

  static const int _defaultBridgeTimeoutMs = 120000;
  static const String _operation = 'loadResumoVendasDiariasPorVendedor';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<List<ResumoVendasDiariasPorVendedorRow>>> load({
    required String userId,
    required String agentId,
    required ResumoVendasDiariasPorVendedorFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        List<ResumoVendasDiariasPorVendedorRow>
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
      sql: ResumoVendasDiariasPorVendedorSql.query(
        codVendedor: filter.sqlCodVendedor,
        bairro: filter.sqlBairro,
        municipio: filter.sqlMunicipio,
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
        maxRows:
            AgentQueriesBoundedResultMaxRows.resumoVendasDiariasPorVendedor,
      ),
      useRelay: true,
    );

    return AgentSqlRepositoryExecution.execute<
      List<ResumoVendasDiariasPorVendedorRow>
    >(
      agentQueriesRepository: _agentQueriesRepository,
      request: request,
      operation: _operation,
      agentId: agentId.trim(),
      unexpectedRowsLogMessage:
          'Unexpected row shape for ResumoVendasDiariasPorVendedor',
      mapExecution: _mapExecutionToRows,
    );
  }

  List<ResumoVendasDiariasPorVendedorRow> _mapExecutionToRows(
    AgentSqlExecutionResult executionResult,
  ) {
    return executionResult.rows
        .map(
          (row) =>
              ResumoVendasDiariasPorVendedorRowModel.fromMap(row).toEntity(),
        )
        .toList(growable: false);
  }
}
