import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/data/models/cliente_option_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/cliente_options_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/data/resumo_vendas_diarias_suggestion_sql_params.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cliente_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cliente_options_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cliente_options_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/cliente_options_repository.dart';

class ClienteOptionsRepositoryImpl implements ClienteOptionsRepository {
  ClienteOptionsRepositoryImpl(this._agentQueriesRepository);

  static const String _operation = 'loadClienteOptionsPage';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<ClienteOptionsPageResult>> loadPage({
    required String userId,
    required String agentId,
    required ClienteOptionsFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        ClienteOptionsPageResult
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
      sql: ClienteOptionsSql.pagedQuery,
      clientToken: clientToken,
      bridgeTimeoutMs:
          bridgeTimeoutMs ?? AppEnvironment.agentSqlBridgeTimeoutMs,
      namedParams: <String, Object?>{
        'searchPattern':
            ResumoVendasDiariasSuggestionSqlParams.buildSearchPattern(
              filter.searchTerm,
            ),
        'searchDigitsPattern':
            ResumoVendasDiariasSuggestionSqlParams.buildDigitsOnlySearchPattern(
              filter.searchTerm,
            ),
        'startRow': filter.startRow,
        'endRow': filter.endRow,
      },
      executeOptions: const AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.preserve,
        maxRows: AgentQueriesBoundedResultMaxRows.clienteOptionsPage,
      ),
      useRelay: true,
    );

    return AgentSqlRepositoryExecution.execute<ClienteOptionsPageResult>(
      agentQueriesRepository: _agentQueriesRepository,
      request: request,
      operation: _operation,
      agentId: agentId.trim(),
      unexpectedRowsLogMessage: 'Unexpected row shape for $_operation',
      cancelScope: cancelScope,
      mapExecution: _mapPagedExecution,
    );
  }

  ClienteOptionsPageResult _mapPagedExecution(
    AgentSqlExecutionResult executionResult,
  ) {
    if (executionResult.rows.isEmpty) {
      return const ClienteOptionsPageResult(
        items: <ClienteOption>[],
        totalCount: 0,
      );
    }

    final totalCount = AgentQueriesSqlRowMapReader.readRequiredInt(
      executionResult.rows.first,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('TotalCount'),
    );

    final items = executionResult.rows
        .where(_rowHasClienteCod)
        .map((row) => ClienteOptionModel.fromMap(row).toEntity())
        .toList(growable: false);

    return ClienteOptionsPageResult(items: items, totalCount: totalCount);
  }

  static bool _rowHasClienteCod(Map<String, dynamic> row) {
    final raw = AgentQueriesSqlRowMapReader.lookupFirst(
      row,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodCliente'),
    );
    return raw != null;
  }
}
