import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/data/models/municipio_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/municipio_list_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/data/resumo_vendas_diarias_suggestion_sql_params.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/municipio_list_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/municipio_list_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/municipio_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/municipio_list_repository.dart';

class MunicipioListRepositoryImpl implements MunicipioListRepository {
  MunicipioListRepositoryImpl(this._agentQueriesRepository);

  static const int _defaultBridgeTimeoutMs = 120000;
  static const String _operation = 'loadMunicipioListPage';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<MunicipioListPageResult>> loadPage({
    required String userId,
    required String agentId,
    required MunicipioListFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        MunicipioListPageResult
      >(
        message: validationError,
        operation: _operation,
        agentId: agentId.trim(),
      );
    }

    final filterParams = _filterNamedParams(filter);

    final request = AgentSqlExecuteRequest(
      agentId: agentId,
      requestingUserId: userId,
      sql: MunicipioListSql.pagedQuery,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs ?? _defaultBridgeTimeoutMs,
      namedParams: <String, Object?>{
        ...filterParams,
        'startRow': filter.startRow,
        'endRow': filter.endRow,
      },
      executeOptions: const AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.preserve,
        maxRows: AgentQueriesBoundedResultMaxRows.municipioListPage,
      ),
      useRelay: true,
    );

    return AgentSqlRepositoryExecution.execute<MunicipioListPageResult>(
      agentQueriesRepository: _agentQueriesRepository,
      request: request,
      operation: _operation,
      agentId: agentId.trim(),
      unexpectedRowsLogMessage: 'Unexpected row shape for $_operation',
      mapExecution: _mapPagedExecution,
    );
  }

  Map<String, Object?> _filterNamedParams(MunicipioListFilter filter) {
    return <String, Object?>{
      'uf': filter.sqlUfParam,
      'searchPattern':
          ResumoVendasDiariasSuggestionSqlParams.buildPrefixSearchPattern(
            filter.searchTerm,
          ),
    };
  }

  MunicipioListPageResult _mapPagedExecution(
    AgentSqlExecutionResult executionResult,
  ) {
    if (executionResult.rows.isEmpty) {
      return const MunicipioListPageResult(
        items: <MunicipioRow>[],
        totalCount: 0,
      );
    }

    final totalCount = AgentQueriesSqlRowMapReader.readRequiredInt(
      executionResult.rows.first,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('TotalCount'),
    );

    final items = executionResult.rows
        .where(_rowHasMunicipioCod)
        .map((row) => MunicipioRowModel.fromMap(row).toEntity())
        .toList(growable: false);

    return MunicipioListPageResult(items: items, totalCount: totalCount);
  }

  static bool _rowHasMunicipioCod(Map<String, dynamic> row) {
    final raw = AgentQueriesSqlRowMapReader.lookupFirst(
      row,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodMunicipio'),
    );
    return raw != null;
  }
}
