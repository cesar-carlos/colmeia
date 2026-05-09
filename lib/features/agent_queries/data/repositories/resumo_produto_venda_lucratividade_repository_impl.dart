import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_produto_venda_lucratividade_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_produto_venda_lucratividade_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_produto_venda_lucratividade_repository.dart';

class ResumoProdutoVendaLucratividadeRepositoryImpl
    implements ResumoProdutoVendaLucratividadeRepository {
  ResumoProdutoVendaLucratividadeRepositoryImpl(this._agentQueriesRepository);

  /// One row per branch — very small result set; lighter than the monthly
  /// variant but covers the full period in a single aggregate.
  static const int _defaultBridgeTimeoutMs = 120000;

  /// 90 % of the active bridge timeout, clamped so short timeouts stay usable.
  static const int _defaultSqlTimeoutMs = 108000;
  static const int _minSqlTimeoutMs = 5000;

  static const String _operation = 'loadResumoProdutoVendaLucratividade';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<List<ResumoProdutoVendaLucratividadeRow>>> loadAll({
    required String userId,
    required String agentId,
    required ResumoProdutoVendaLucratividadeFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        List<ResumoProdutoVendaLucratividadeRow>
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
      sql: ResumoProdutoVendaLucratividadeSql.query,
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
            AgentQueriesBoundedResultMaxRows.resumoProdutoVendaLucratividade,
        sqlTimeoutMs: effectiveSqlMs,
      ),
      useRelay: true,
    );

    return AgentSqlRepositoryExecution.execute<
      List<ResumoProdutoVendaLucratividadeRow>
    >(
      agentQueriesRepository: _agentQueriesRepository,
      request: request,
      operation: _operation,
      agentId: agentId.trim(),
      unexpectedRowsLogMessage: 'Unexpected row shape for $_operation',
      mapExecution: (executionResult) =>
          _mapExecution(executionResult, agentId: agentId.trim()),
    );
  }

  List<ResumoProdutoVendaLucratividadeRow> _mapExecution(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
  }) {
    if (executionResult.rows.isEmpty) {
      return const <ResumoProdutoVendaLucratividadeRow>[];
    }

    if (executionResult.rows.length >=
        AgentQueriesBoundedResultMaxRows.resumoProdutoVendaLucratividade) {
      AppLogger.warning(
        'Agent row count reached max_rows cap (possible truncation)',
        context: <String, Object?>{
          'operation': _operation,
          'agentId': agentId,
          'rowCount': executionResult.rows.length,
          'maxRows':
              AgentQueriesBoundedResultMaxRows.resumoProdutoVendaLucratividade,
        },
      );
    }

    return executionResult.rows
        .map(
          (row) =>
              ResumoProdutoVendaLucratividadeRowModel.fromMap(row).toEntity(),
        )
        .toList(growable: false);
  }
}
