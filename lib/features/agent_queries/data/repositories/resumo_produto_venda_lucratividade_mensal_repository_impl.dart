import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_produto_venda_lucratividade_mensal_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_produto_venda_lucratividade_mensal_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_produto_venda_lucratividade_mensal_repository.dart';

/// Monthly product profitability (`ResumoProdutoVendaLucratividadeMensal`).
///
/// ## Transport
///
/// Uses relay **unary** with `preferDbStreaming: false`. Nested-subquery +
/// streaming variants returned empty success payloads on the E2E SQL Anywhere
/// agent; the CTE rewrite returns Top-N monthly buckets on unary. Skips the
/// short transport cache and retries once on empty success because the agent
/// can still return an empty replay for the same `client_token`.
class ResumoProdutoVendaLucratividadeMensalRepositoryImpl
    implements ResumoProdutoVendaLucratividadeMensalRepository {
  ResumoProdutoVendaLucratividadeMensalRepositoryImpl(
    this._agentQueriesRepository,
  );

  /// Agent-side SQL timeout: 90 % of the active bridge timeout, capped here
  /// and floored at the minimum so very short bridge timeouts stay usable.
  static const int _defaultSqlTimeoutMs = 108000;
  static const int _minSqlTimeoutMs = 5000;

  /// Delay before retrying an empty success (agent replay / flakiness).
  static const Duration emptySuccessRetryDelay = Duration(seconds: 2);

  static const String _operation = 'loadResumoProdutoVendaLucratividadeMensal';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<List<ResumoProdutoVendaLucratividadeMensalRow>>> loadAll({
    required String userId,
    required String agentId,
    required ResumoProdutoVendaLucratividadeMensalFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        List<ResumoProdutoVendaLucratividadeMensalRow>
      >(
        message: validationError,
        operation: _operation,
        agentId: agentId.trim(),
      );
    }

    final effectiveBridgeMs =
        bridgeTimeoutMs ?? AppEnvironment.agentSqlBridgeTimeoutMs;
    final effectiveSqlMs = (effectiveBridgeMs * 0.9).round().clamp(
      _minSqlTimeoutMs,
      _defaultSqlTimeoutMs,
    );

    Future<AppResult<List<ResumoProdutoVendaLucratividadeMensalRow>>>
    executeOnce() {
      final request = AgentSqlExecuteRequest(
        agentId: agentId,
        requestingUserId: userId,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
        sql: ResumoProdutoVendaLucratividadeMensalSql.query,
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
          maxRows: AgentQueriesBoundedResultMaxRows
              .resumoProdutoVendaLucratividadeMensal,
          sqlTimeoutMs: effectiveSqlMs,
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
        List<ResumoProdutoVendaLucratividadeMensalRow>
      >(
        agentQueriesRepository: _agentQueriesRepository,
        request: request,
        operation: _operation,
        agentId: agentId.trim(),
        unexpectedRowsLogMessage: 'Unexpected row shape for $_operation',
        mapExecution: (executionResult) => _mapExecution(
          executionResult,
          agentId: agentId.trim(),
        ),
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
        'agentId': agentId.trim(),
        'retryDelayMs': emptySuccessRetryDelay.inMilliseconds,
      },
    );
    await Future<void>.delayed(emptySuccessRetryDelay);
    return executeOnce();
  }

  List<ResumoProdutoVendaLucratividadeMensalRow> _mapExecution(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
  }) {
    if (executionResult.rows.isEmpty) {
      return const <ResumoProdutoVendaLucratividadeMensalRow>[];
    }

    if (executionResult.rows.length >=
        AgentQueriesBoundedResultMaxRows
            .resumoProdutoVendaLucratividadeMensal) {
      AppLogger.warning(
        'Agent row count reached max_rows cap (possible truncation)',
        context: <String, Object?>{
          'operation': _operation,
          'agentId': agentId,
          'rowCount': executionResult.rows.length,
          'maxRows': AgentQueriesBoundedResultMaxRows
              .resumoProdutoVendaLucratividadeMensal,
        },
      );
    }

    return executionResult.rows
        .map(
          (row) => ResumoProdutoVendaLucratividadeMensalRowModel.fromMap(
            row,
          ).toEntity(),
        )
        .toList(growable: false);
  }
}
