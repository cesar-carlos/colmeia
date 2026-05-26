import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/data/models/cadastro_filial_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/cadastro_filial_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/cadastro_filial_repository.dart';

class CadastroFilialRepositoryImpl implements CadastroFilialRepository {
  CadastroFilialRepositoryImpl(this._agentQueriesRepository);

  static const String _operation = 'loadCadastroFilialPage';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<CadastroFilialPageResult>> loadPage({
    required String userId,
    required String agentId,
    required CadastroFilialFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final trimmedAgentId = agentId.trim();
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        CadastroFilialPageResult
      >(
        message: validationError,
        operation: _operation,
        agentId: trimmedAgentId,
      );
    }

    final selectedBranches = filter.branchesForAgent(trimmedAgentId);

    final request = AgentSqlExecuteRequest(
      agentId: agentId,
      requestingUserId: userId,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      sql: CadastroFilialSql.query(
        branches: selectedBranches,
        hasSelectedBranches: filter.hasSelectedBranches,
        codEmpresa: filter.codEmpresa,
        codFilial: filter.codFilial,
      ),
      clientToken: clientToken,
      bridgeTimeoutMs:
          bridgeTimeoutMs ?? AppEnvironment.agentSqlBridgeTimeoutMs,
      namedParams: <String, Object?>{
        'startRow': filter.startRow,
        'endRow': filter.endRow,
      },
      executeOptions: const AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.preserve,
        maxRows: AgentQueriesBoundedResultMaxRows.cadastroFilialPage,
      ),
      useRelay: true,
    );

    return AgentSqlRepositoryExecution.execute<CadastroFilialPageResult>(
      agentQueriesRepository: _agentQueriesRepository,
      request: request,
      operation: _operation,
      agentId: trimmedAgentId,
      unexpectedRowsLogMessage: 'Unexpected row shape for $_operation',
      mapExecution: _mapPagedExecution,
      cancelScope: cancelScope,
    );
  }

  CadastroFilialPageResult _mapPagedExecution(
    AgentSqlExecutionResult executionResult,
  ) {
    if (executionResult.rows.isEmpty) {
      return const CadastroFilialPageResult(
        items: <CadastroFilialRow>[],
        totalCount: 0,
      );
    }

    final totalCount = AgentQueriesSqlRowMapReader.readRequiredInt(
      executionResult.rows.first,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('TotalCount'),
    );

    final items = executionResult.rows
        .where(_rowHasBranchKey)
        .map((row) => CadastroFilialRowModel.fromMap(row).toEntity())
        .toList(growable: false);

    return CadastroFilialPageResult(items: items, totalCount: totalCount);
  }

  static bool _rowHasBranchKey(Map<String, dynamic> row) {
    final raw = AgentQueriesSqlRowMapReader.lookupFirst(
      row,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodEmpresa'),
    );
    return raw != null;
  }
}
