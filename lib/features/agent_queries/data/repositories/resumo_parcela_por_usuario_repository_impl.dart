import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcela_por_usuario_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcela_por_usuario_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_por_usuario_repository.dart';

class ResumoParcelaPorUsuarioRepositoryImpl
    implements ResumoParcelaPorUsuarioRepository {
  ResumoParcelaPorUsuarioRepositoryImpl(
    this._agentQueriesRepository,
  );

  static const int _defaultBridgeTimeoutMs = 120000;
  static const String _operation = 'loadResumoParcelaPorUsuario';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<List<ResumoParcelaPorUsuarioRow>>> load({
    required String userId,
    required String agentId,
    required ResumoParcelaPorUsuarioFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        List<ResumoParcelaPorUsuarioRow>
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
      sql: ResumoParcelaPorUsuarioSql.query,
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
        maxRows: AgentQueriesBoundedResultMaxRows.resumoParcelaPorUsuario,
      ),
      useRelay: true,
      relayMode: AgentSqlRelayMode.streaming,
    );

    return AgentSqlRepositoryExecution.execute<
      List<ResumoParcelaPorUsuarioRow>
    >(
      agentQueriesRepository: _agentQueriesRepository,
      request: request,
      operation: _operation,
      agentId: agentId.trim(),
      unexpectedRowsLogMessage:
          'Unexpected row shape for ResumoParcelaPorUsuario',
      mapExecution: _mapExecutionToRows,
    );
  }

  List<ResumoParcelaPorUsuarioRow> _mapExecutionToRows(
    AgentSqlExecutionResult executionResult,
  ) {
    return executionResult.rows
        .map(
          (row) => ResumoParcelaPorUsuarioRowModel.fromMap(row).toEntity(),
        )
        .toList(growable: false);
  }
}
