import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/models/produto_vendido_produto_rank_lucro_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_produto_rank_lucro_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_produto_rank_lucro_repository.dart';

class ProdutoVendidoProdutoRankLucroRepositoryImpl
    implements ProdutoVendidoProdutoRankLucroRepository {
  ProdutoVendidoProdutoRankLucroRepositoryImpl(this._agentQueriesRepository);

  /// Multi-join sale lines + custo aggregate; aligns with profitability reports.
  static const int _defaultBridgeTimeoutMs = 180000;

  static const int _defaultSqlTimeoutMs = 162000;
  static const int _minSqlTimeoutMs = 5000;

  static const String _operation = 'loadProdutoVendidoProdutoRankLucro';

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

    final effectiveBridgeMs = bridgeTimeoutMs ?? _defaultBridgeTimeoutMs;
    final effectiveSqlMs = (effectiveBridgeMs * 0.9).round().clamp(
      _minSqlTimeoutMs,
      _defaultSqlTimeoutMs,
    );

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
      bridgeTimeoutMs: effectiveBridgeMs,
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
        sqlTimeoutMs: effectiveSqlMs,
        preferDbStreaming: true,
      ),
      useRelay: true,
      relayMode: AgentSqlRelayMode.streaming,
    );

    return AgentSqlRepositoryExecution.execute<
      List<ProdutoVendidoProdutoRankLucroRow>
    >(
      agentQueriesRepository: _agentQueriesRepository,
      request: request,
      operation: _operation,
      agentId: agentId.trim(),
      unexpectedRowsLogMessage: 'Unexpected row shape for $_operation',
      mapExecution: (executionResult) =>
          _mapExecution(executionResult, agentId: agentId.trim()),
      cancelScope: cancelScope,
    );
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
