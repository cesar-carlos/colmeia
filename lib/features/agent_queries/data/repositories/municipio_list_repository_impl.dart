import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/data/models/municipio_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/municipio_list_sql.dart';
import 'package:colmeia/features/agent_queries/data/resumo_vendas_diarias_suggestion_sql_params.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/municipio_list_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/municipio_list_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/municipio_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/municipio_list_repository.dart';
import 'package:result_dart/result_dart.dart';

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
      return Failure<MunicipioListPageResult, AppFailure>(
        ValidationFailure(
          message: validationError,
          userMessage: 'Os filtros da consulta sao invalidos.',
          context: <String, Object?>{
            'operation': _operation,
            'agentId': agentId.trim(),
          },
        ),
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
    );

    final result = await _agentQueriesRepository.executeSql(request);
    return result.fold(
      (executionResult) => _mapPagedExecution(
        executionResult,
        agentId: agentId.trim(),
      ),
      Failure<MunicipioListPageResult, AppFailure>.new,
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

  AppResult<MunicipioListPageResult> _mapPagedExecution(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
  }) {
    if (executionResult.rows.isEmpty) {
      return const Success<MunicipioListPageResult, AppFailure>(
        MunicipioListPageResult(items: <MunicipioRow>[], totalCount: 0),
      );
    }

    try {
      final totalCount = AgentQueriesSqlRowMapReader.readRequiredInt(
        executionResult.rows.first,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('TotalCount'),
      );

      final items = executionResult.rows
          .where(_rowHasMunicipioCod)
          .map((row) => MunicipioRowModel.fromMap(row).toEntity())
          .toList(growable: false);

      return Success<MunicipioListPageResult, AppFailure>(
        MunicipioListPageResult(items: items, totalCount: totalCount),
      );
    } on FormatException catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected row shape for $_operation',
        context: <String, Object?>{
          'operation': _operation,
          'agentId': agentId,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<MunicipioListPageResult, AppFailure>(
        UnknownFailure(
          message: error.message,
          userMessage: 'Resposta do agente estava em formato inesperado. '
              'Tente novamente.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': _operation,
            'agentId': agentId,
          },
        ),
      );
    }
  }

  static bool _rowHasMunicipioCod(Map<String, dynamic> row) {
    final raw = AgentQueriesSqlRowMapReader.lookupFirst(
      row,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodMunicipio'),
    );
    return raw != null;
  }
}
