import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/models/produto_vendido_produto_rank_lucro_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_produto_rank_lucro_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_produto_rank_lucro_repository.dart';
import 'package:result_dart/result_dart.dart';

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
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return Failure<List<ProdutoVendidoProdutoRankLucroRow>, AppFailure>(
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
      ),
      useRelay: true,
    );

    final result = await _agentQueriesRepository.executeSql(request);
    return result.fold(
      (executionResult) =>
          _mapExecution(executionResult, agentId: agentId.trim()),
      Failure<List<ProdutoVendidoProdutoRankLucroRow>, AppFailure>.new,
    );
  }

  AppResult<List<ProdutoVendidoProdutoRankLucroRow>> _mapExecution(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
  }) {
    if (executionResult.rows.isEmpty) {
      return const Success<List<ProdutoVendidoProdutoRankLucroRow>, AppFailure>(
        [],
      );
    }

    try {
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

      final items = executionResult.rows
          .map(
            (row) =>
                ProdutoVendidoProdutoRankLucroRowModel.fromMap(row).toEntity(),
          )
          .toList(growable: false);

      return Success<List<ProdutoVendidoProdutoRankLucroRow>, AppFailure>(
        items,
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
      return Failure<List<ProdutoVendidoProdutoRankLucroRow>, AppFailure>(
        UnknownFailure(
          message: error.message,
          userMessage:
              'Resposta do agente estava em formato inesperado. '
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
}
