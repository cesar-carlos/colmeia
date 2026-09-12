import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/data/models/nota_entrada_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/notas_entrada_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/data/resumo_vendas_diarias_suggestion_sql_params.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/notas_entrada_repository.dart';

/// Numbered, non-cancelled entrada notes for one company and branch.
class NotasEntradaRepositoryImpl implements NotasEntradaRepository {
  NotasEntradaRepositoryImpl(this._agentQueriesRepository);

  static const int _defaultSqlTimeoutMs = 170000;
  static const int _minSqlTimeoutMs = 5000;
  static const String _operation = 'loadNotasEntradaPage';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<NotasEntradaPageResult>> loadPage({
    required String userId,
    required String agentId,
    required NotasEntradaFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<NotasEntradaPageResult>(
        message: validationError,
        operation: _operation,
        agentId: agentId.trim(),
      );
    }

    final trimmedAgentId = agentId.trim();
    final effectiveBridgeMs =
        bridgeTimeoutMs ?? AppEnvironment.agentSqlBridgeMediumTimeoutMs;
    final effectiveSqlMs = (effectiveBridgeMs * 0.9).round().clamp(
      _minSqlTimeoutMs,
      _defaultSqlTimeoutMs,
    );
    final request = AgentSqlExecuteRequest(
      agentId: agentId,
      requestingUserId: userId,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      sql: NotasEntradaSql.pagedQuery(
        hasDataLancamentoInicio: filter.dataLancamentoInicio != null,
        hasDataLancamentoFim: filter.dataLancamentoFim != null,
      ),
      clientToken: clientToken,
      bridgeTimeoutMs: effectiveBridgeMs,
      namedParams: _namedParamsFor(filter),
      executeOptions: AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.preserve,
        maxRows: filter.pageSize,
        sqlTimeoutMs: effectiveSqlMs,
        preferDbStreaming: false,
      ),
      useRelay: true,
      // Explicit unary: paged CTE shapes are not reliable on SQL Anywhere
      // streaming agents.
      // ignore: avoid_redundant_argument_values
      relayMode: AgentSqlRelayMode.unary,
      skipTransportCache: true,
    );

    return AgentSqlRepositoryExecution.execute<NotasEntradaPageResult>(
      agentQueriesRepository: _agentQueriesRepository,
      request: request,
      operation: _operation,
      agentId: trimmedAgentId,
      unexpectedRowsLogMessage: 'Unexpected row shape for $_operation',
      mapExecution: (executionResult) => _mapPagedExecution(
        executionResult,
        agentId: trimmedAgentId,
        sqlMaxRowsCap: filter.pageSize,
      ),
      cancelScope: cancelScope,
    );
  }

  NotasEntradaPageResult _mapPagedExecution(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
    required int sqlMaxRowsCap,
  }) {
    if (executionResult.rows.isEmpty) {
      return const NotasEntradaPageResult(
        items: <NotaEntradaRow>[],
        totalCount: 0,
      );
    }

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
        .where(_rowHasCompraKey)
        .map((row) => NotaEntradaRowModel.fromMap(row).toEntity())
        .toList(growable: false);

    return NotasEntradaPageResult(items: items, totalCount: totalCount);
  }

  static Map<String, Object?> _namedParamsFor(NotasEntradaFilter filter) {
    final params = <String, Object?>{
      'codEmpresa': filter.codEmpresa,
      'codFilial': filter.codFilial,
      'nomeFornecedorPattern':
          ResumoVendasDiariasSuggestionSqlParams.buildSearchPattern(
            filter.normalizedSearchTerm,
          ),
      'startRow': filter.startRow,
      'endRow': filter.endRow,
    };
    final dataLancamentoInicio = filter.dataLancamentoInicio;
    if (dataLancamentoInicio != null) {
      params['dataLancamentoInicio'] = AgentQueriesSqlLocalDate.format(
        dataLancamentoInicio,
      );
    }
    final dataLancamentoFim = filter.dataLancamentoFim;
    if (dataLancamentoFim != null) {
      params['dataLancamentoFim'] = AgentQueriesSqlLocalDate.format(
        dataLancamentoFim,
      );
    }
    return params;
  }

  static bool _rowHasCompraKey(Map<String, dynamic> row) {
    final raw = AgentQueriesSqlRowMapReader.lookupFirst(
      row,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CompraId'),
    );
    return raw != null;
  }
}
