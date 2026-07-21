import 'dart:math' as math;

import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/models/ranking_produtos_faturamento_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/ranking_produtos_faturamento_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_bridge_timeout.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_load_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/ranking_produtos_faturamento_repository.dart';
import 'package:flutter/foundation.dart';

/// Ad-hoc billing ranking per agent; parameters vary by screen — transport SQL
/// cache is always skipped (`skipTransportCache: true`).
///
/// ## Transport
///
/// Uses relay **unary** with `preferDbStreaming: false`. Streaming on the E2E
/// SQL Anywhere agent returns an empty success payload for this CTE ranking.
/// Revisit streaming only after the agent/hub fix is validated; unary also
/// means agent-side `sql.cancel` is not guaranteed (fail-fast client cancel
/// only — see `docs/Features/socket/sql_cancel_contract_colmeia_map.md`).
class RankingProdutosFaturamentoRepositoryImpl
    implements RankingProdutosFaturamentoRepository {
  RankingProdutosFaturamentoRepositoryImpl(this._agentQueriesRepository);

  static const String _operation = 'loadRankingProdutosFaturamento';

  /// Conservative upper bound for distinct branches when sizing `max_rows`.
  ///
  /// Kept modest so `(quantidadeProdutos + 1) * maxFilialEstimate` stays in
  /// the range the bridge/agent accepts for this heavy ranking CTE. Raise only
  /// after validating larger `max_rows` on the target agent; prefer
  /// single-branch filters when the catalog exceeds this estimate.
  static const int maxFilialEstimate = 25;

  final AgentQueriesRepository _agentQueriesRepository;

  static int maxRowsForFilter(RankingProdutosFaturamentoFilter filter) {
    final requested = (filter.quantidadeProdutos + 1) * maxFilialEstimate;
    return math.min(
      requested,
      AgentQueriesBoundedResultMaxRows.rankingProdutosFaturamento,
    );
  }

  @override
  Future<AppResult<RankingProdutosFaturamentoLoadResult>> load({
    required String userId,
    required String agentId,
    required RankingProdutosFaturamentoFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        RankingProdutosFaturamentoLoadResult
      >(
        message: validationError,
        operation: _operation,
        agentId: agentId.trim(),
      );
    }

    final timeouts = AgentSqlBridgeTimeout.resolve(
      bridgeTimeoutMs: bridgeTimeoutMs,
    );
    final maxRows = maxRowsForFilter(filter);

    if (kDebugMode) {
      final start = DateTime(
        filter.dataVendaInicio.year,
        filter.dataVendaInicio.month,
        filter.dataVendaInicio.day,
      );
      final end = DateTime(
        filter.dataVendaFim.year,
        filter.dataVendaFim.month,
        filter.dataVendaFim.day,
      );
      AppLogger.info(
        'RankingProdutosFaturamento load',
        context: <String, Object?>{
          'operation': _operation,
          'agentId': agentId.trim(),
          'quantidadeProdutos': filter.quantidadeProdutos,
          'inclusiveDays': end.difference(start).inDays + 1,
          'maxRows': maxRows,
          'maxFilialEstimate': maxFilialEstimate,
        },
      );
    }

    final restrictToSingleBranch =
        filter.codEmpresa != null && filter.codFilial != null;

    final request = AgentSqlExecuteRequest(
      agentId: agentId,
      requestingUserId: userId,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      sql: RankingProdutosFaturamentoSql.buildQuery(
        restrictToSingleBranch: restrictToSingleBranch,
        origem: filter.trimmedOrigem,
        preVenda: filter.trimmedPreVenda,
        quantidadeProdutos: filter.quantidadeProdutos,
      ),
      clientToken: clientToken,
      bridgeTimeoutMs: timeouts.bridgeMs,
      namedParams: _namedParamsFor(filter),
      executeOptions: AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.preserve,
        maxRows: maxRows,
        sqlTimeoutMs: timeouts.sqlMs,
        // Streaming returns an empty success payload for this CTE ranking on
        // the SQL Anywhere E2E agent (unary REST/relay returns Top-N + DIVERSOS).
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
      RankingProdutosFaturamentoLoadResult
    >(
      agentQueriesRepository: _agentQueriesRepository,
      request: request,
      operation: _operation,
      agentId: agentId.trim(),
      unexpectedRowsLogMessage: 'Unexpected row shape for $_operation',
      mapExecution: (executionResult) => RankingProdutosFaturamentoLoadResult(
        rows: _mapExecution(
          executionResult,
          agentId: agentId.trim(),
          maxRows: maxRows,
        ),
      ),
      cancelScope: cancelScope,
    );
  }

  static Map<String, Object?> _namedParamsFor(
    RankingProdutosFaturamentoFilter filter,
  ) {
    // quantidadeProdutos is inlined in SQL (validated int) so ODBC/SQL Anywhere
    // does not see the same named host variable twice.
    final base = <String, Object?>{
      'dataVendaInicio': AgentQueriesSqlLocalDate.format(
        filter.dataVendaInicio,
      ),
      'dataVendaFim': AgentQueriesSqlLocalDate.format(filter.dataVendaFim),
    };

    final codEmpresa = filter.codEmpresa;
    final codFilial = filter.codFilial;
    if (codEmpresa != null && codFilial != null) {
      return <String, Object?>{
        ...base,
        'codEmpresa': codEmpresa,
        'codFilial': codFilial,
      };
    }

    return <String, Object?>{
      ...base,
      'origem': filter.trimmedOrigem,
      'preVenda': filter.trimmedPreVenda,
    };
  }

  List<RankingProdutosFaturamentoRow> _mapExecution(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
    required int maxRows,
  }) {
    if (executionResult.rows.isEmpty) {
      return const <RankingProdutosFaturamentoRow>[];
    }

    if (executionResult.rows.length >= maxRows) {
      AppLogger.warning(
        'Agent row count reached max_rows cap (possible truncation)',
        context: <String, Object?>{
          'operation': _operation,
          'agentId': agentId,
          'rowCount': executionResult.rows.length,
          'maxRows': maxRows,
        },
      );
    }

    return executionResult.rows
        .map(
          (row) => RankingProdutosFaturamentoRowModel.fromMap(row).toEntity(),
        )
        .where(
          (row) => !(row.isDiversos && row.valorVenda == 0),
        )
        .toList(growable: false);
  }
}
