import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_warn_if_sql_rows_at_cap.dart';
import 'package:colmeia/features/agent_queries/data/models/nota_entrada_item_row_model.dart';
import 'package:colmeia/features/agent_queries/data/notas_entrada_itens_sql_params.dart';
import 'package:colmeia/features/agent_queries/data/queries/notas_entrada_itens_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_item_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_itens_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_itens_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/notas_entrada_itens_repository.dart';

/// Line items of one numbered entrada note.
class NotasEntradaItensRepositoryImpl implements NotasEntradaItensRepository {
  NotasEntradaItensRepositoryImpl(this._agentQueriesRepository);

  static const int _defaultSqlTimeoutMs = 170000;
  static const int _minSqlTimeoutMs = 5000;
  static const String _operation = 'loadNotasEntradaItens';
  static const int sqlMaxRowsCap =
      AgentQueriesBoundedResultMaxRows.notasEntradaItens;

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<NotasEntradaItensResult>> load({
    required String userId,
    required String agentId,
    required NotasEntradaItensFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        NotasEntradaItensResult
      >(
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
      sql: NotasEntradaItensSql.query,
      clientToken: clientToken,
      bridgeTimeoutMs: effectiveBridgeMs,
      namedParams: NotasEntradaItensSqlParams.namedParamsFor(filter),
      executeOptions: AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.preserve,
        maxRows: sqlMaxRowsCap,
        sqlTimeoutMs: effectiveSqlMs,
        preferDbStreaming: false,
      ),
      useRelay: true,
      // Explicit unary: CTE shapes are not reliable on SQL Anywhere
      // streaming agents.
      // ignore: avoid_redundant_argument_values
      relayMode: AgentSqlRelayMode.unary,
      skipTransportCache: true,
    );

    return AgentSqlRepositoryExecution.execute<NotasEntradaItensResult>(
      agentQueriesRepository: _agentQueriesRepository,
      request: request,
      operation: _operation,
      agentId: trimmedAgentId,
      unexpectedRowsLogMessage: 'Unexpected row shape for $_operation',
      mapExecution: (executionResult) => _mapExecution(
        executionResult,
        agentId: trimmedAgentId,
      ),
      cancelScope: cancelScope,
    );
  }

  NotasEntradaItensResult _mapExecution(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
  }) {
    agentQueriesWarnIfSqlRowsAtCap(
      operation: _operation,
      agentId: agentId,
      returnedRowCount: executionResult.rows.length,
      maxRows: sqlMaxRowsCap,
    );

    final items = executionResult.rows
        .map((row) => NotaEntradaItemRowModel.fromMap(row).toEntity())
        .toList(growable: false);

    return NotasEntradaItensResult(
      items: List<NotaEntradaItemRow>.unmodifiable(items),
      isTruncated: executionResult.rows.length >= sqlMaxRowsCap,
      maxRows: sqlMaxRowsCap,
    );
  }
}
