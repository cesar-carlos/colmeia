import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_produto_venda_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_produto_venda_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_produto_venda_repository.dart';
import 'package:result_dart/result_dart.dart';

class ResumoProdutoVendaRepositoryImpl implements ResumoProdutoVendaRepository {
  ResumoProdutoVendaRepositoryImpl(this._agentQueriesRepository);

  /// HTTP bridge wait — resumo can be heavy (wide joins + aggregate + parcel
  /// pick); aligned with other multi-join agent reports.
  static const int _defaultBridgeTimeoutMs = 180000;

  /// Agent-side SQL timeout (`options.timeout_ms`), same order of magnitude
  /// as [_defaultBridgeTimeoutMs] so the DB does not stop after the HTTP
  /// channel has already waited longer.
  static const int _defaultSqlTimeoutMs = 180000;
  static const String _operation = 'loadResumoProdutoVendaPage';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<ResumoProdutoVendaPageResult>> loadPage({
    required String userId,
    required String agentId,
    required ResumoProdutoVendaFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return Failure<ResumoProdutoVendaPageResult, AppFailure>(
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

    final request = AgentSqlExecuteRequest(
      agentId: agentId,
      requestingUserId: userId,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      sql: ResumoProdutoVendaSql.pagedQuery(
        sortBy: filter.sortBy,
        sortDirection: filter.sortDirection,
        rowNumberOrdering: filter.rowNumberOrdering,
      ),
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs ?? _defaultBridgeTimeoutMs,
      namedParams: <String, Object?>{
        'dataVendaInicio': AgentQueriesSqlLocalDate.format(
          filter.dataVendaInicio,
        ),
        'dataVendaFim': AgentQueriesSqlLocalDate.format(filter.dataVendaFim),
        'origem': filter.trimmedOrigem,
        'startRow': filter.startRow,
        'endRow': filter.endRow,
      },
      executeOptions: AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.preserve,
        maxRows: filter.sqlMaxRowsCap,
        sqlTimeoutMs: _defaultSqlTimeoutMs,
      ),
    );

    final result = await _agentQueriesRepository.executeSql(request);
    return result.fold(
      (executionResult) => _mapPagedExecution(
        executionResult,
        agentId: agentId.trim(),
        sqlMaxRowsCap: filter.sqlMaxRowsCap,
      ),
      Failure<ResumoProdutoVendaPageResult, AppFailure>.new,
    );
  }

  AppResult<ResumoProdutoVendaPageResult> _mapPagedExecution(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
    required int sqlMaxRowsCap,
  }) {
    if (executionResult.rows.isEmpty) {
      return const Success<ResumoProdutoVendaPageResult, AppFailure>(
        ResumoProdutoVendaPageResult(items: <ResumoProdutoVendaRow>[], totalCount: 0),
      );
    }

    try {
      if (executionResult.rows.length >= sqlMaxRowsCap) {
        AppLogger.warning(
          'Agent row count reached max_rows cap (possible truncation)',
          context: <String, Object?>{
            'operation': _operation,
            'agentId': agentId,
            'rowCount': executionResult.rows.length,
            'sqlMaxRowsCap': sqlMaxRowsCap,
          },
        );
      }

      final totalCount = AgentQueriesSqlRowMapReader.readRequiredInt(
        executionResult.rows.first,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('TotalCount'),
      );

      final items = executionResult.rows
          .where(_rowHasProdutoKey)
          .map((row) => ResumoProdutoVendaRowModel.fromMap(row).toEntity())
          .toList(growable: false);

      return Success<ResumoProdutoVendaPageResult, AppFailure>(
        ResumoProdutoVendaPageResult(items: items, totalCount: totalCount),
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
      return Failure<ResumoProdutoVendaPageResult, AppFailure>(
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

  static bool _rowHasProdutoKey(Map<String, dynamic> row) {
    final raw = AgentQueriesSqlRowMapReader.lookupFirst(
      row,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodProduto'),
    );
    return raw != null;
  }
}
