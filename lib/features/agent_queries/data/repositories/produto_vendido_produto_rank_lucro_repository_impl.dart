import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/models/produto_vendido_produto_rank_lucro_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_produto_rank_lucro_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_bridge_timeout.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_produto_rank_lucro_repository.dart';

/// Top product ranking by quantity sold and profit metrics
/// (`ProdutoVendidoProdutoRankLucro`) — one `sql.execute` round-trip.
///
/// ## Transport
///
/// Uses relay **unary** with `preferDbStreaming: false`. Streaming on the E2E
/// SQL Anywhere agent returns an empty success payload for this CTE ranking
/// (same class of defect as product billing ranking). Skips the short transport
/// cache and retries once on empty success. Revisit streaming only after the
/// agent/hub fix is validated.
class ProdutoVendidoProdutoRankLucroRepositoryImpl
    implements ProdutoVendidoProdutoRankLucroRepository {
  ProdutoVendidoProdutoRankLucroRepositoryImpl(this._agentQueriesRepository);

  static const String _operation = 'loadProdutoVendidoProdutoRankLucro';

  /// Delay before retrying an empty success (agent replay / flakiness).
  static const Duration emptySuccessRetryDelay = Duration(seconds: 2);

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<List<ProdutoVendidoProdutoRankLucroRow>>> loadAll({
    required String userId,
    required String agentId,
    required ProdutoVendidoProdutoRankLucroFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        List<ProdutoVendidoProdutoRankLucroRow>
      >(
        message: validationError,
        operation: _operation,
        agentId: agentId.trim(),
      );
    }

    final timeouts = AgentSqlBridgeTimeout.resolve(
      bridgeTimeoutMs: bridgeTimeoutMs,
    );
    final trimmedAgentId = agentId.trim();

    Future<AppResult<List<ProdutoVendidoProdutoRankLucroRow>>> executeOnce() {
      final request = AgentSqlExecuteRequest(
        agentId: agentId,
        requestingUserId: userId,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
        sql: ProdutoVendidoProdutoRankLucroSql.query(
          sortBy: filter.sortBy,
          sortDirection: filter.sortDirection,
        ),
        clientToken: clientToken,
        bridgeTimeoutMs: timeouts.bridgeMs,
        namedParams: <String, Object?>{
          'dataVendaInicio': AgentQueriesSqlLocalDate.format(
            filter.dataVendaInicio,
          ),
          'dataVendaFim': AgentQueriesSqlLocalDate.format(filter.dataVendaFim),
          'origem': filter.trimmedOrigem,
        },
        executeOptions: AgentSqlExecuteOptions(
          executionMode: AgentSqlExecutionMode.preserve,
          maxRows:
              AgentQueriesBoundedResultMaxRows.produtoVendidoProdutoRankLucro,
          sqlTimeoutMs: timeouts.sqlMs,
          // Streaming returns an empty success payload for this CTE ranking on
          // the SQL Anywhere E2E agent (unary returns TOP 15 rows).
          preferDbStreaming: false,
        ),
        useRelay: true,
        // Explicit unary: default is unary, but this report is a documented
        // streaming exception — keep the mode visible for readers and the
        // unary-report guard test.
        // ignore: avoid_redundant_argument_values
        relayMode: AgentSqlRelayMode.unary,
        skipTransportCache: true,
      );

      return AgentSqlRepositoryExecution.execute<
        List<ProdutoVendidoProdutoRankLucroRow>
      >(
        agentQueriesRepository: _agentQueriesRepository,
        request: request,
        operation: _operation,
        agentId: trimmedAgentId,
        unexpectedRowsLogMessage: 'Unexpected row shape for $_operation',
        mapExecution: (executionResult) =>
            _mapExecution(executionResult, agentId: trimmedAgentId),
        cancelScope: cancelScope,
      );
    }

    final first = await executeOnce();
    if (first.isError()) {
      return first;
    }
    final firstRows = first.getOrThrow();
    if (firstRows.isNotEmpty) {
      return first;
    }

    AppLogger.info(
      'Retrying empty unary success for $_operation',
      context: <String, Object?>{
        'operation': _operation,
        'agentId': trimmedAgentId,
        'retryDelayMs': emptySuccessRetryDelay.inMilliseconds,
      },
    );
    await Future<void>.delayed(emptySuccessRetryDelay);
    return executeOnce();
  }

  List<ProdutoVendidoProdutoRankLucroRow> _mapExecution(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
  }) {
    if (executionResult.rows.isEmpty) {
      return const <ProdutoVendidoProdutoRankLucroRow>[];
    }

    if (executionResult.rows.length >=
        AgentQueriesBoundedResultMaxRows.produtoVendidoProdutoRankLucro) {
      AppLogger.warning(
        'Agent row count reached max_rows cap (possible truncation)',
        context: <String, Object?>{
          'operation': _operation,
          'agentId': agentId,
          'rowCount': executionResult.rows.length,
          'maxRows':
              AgentQueriesBoundedResultMaxRows.produtoVendidoProdutoRankLucro,
        },
      );
    }

    return executionResult.rows
        .map(
          (row) =>
              ProdutoVendidoProdutoRankLucroRowModel.fromMap(row).toEntity(),
        )
        .toList(growable: false);
  }
}
