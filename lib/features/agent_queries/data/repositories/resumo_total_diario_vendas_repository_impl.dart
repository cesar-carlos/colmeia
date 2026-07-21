import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_warn_if_sql_rows_at_cap.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_total_diario_vendas_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_total_diario_vendas_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_diario_vendas_repository.dart';
import 'package:flutter/foundation.dart';

/// Daily sales totals (`ResumoTotalDiarioVendas`).
///
/// ## Transport
///
/// Uses relay **unary** with `preferDbStreaming: false`. Sibling sales-hub
/// reports empty-streamed on the E2E SQL Anywhere agent; this path stays
/// aligned with those unary exceptions. Always skips the short transport cache
/// and retries once on empty success (agent replay / flakiness).
class ResumoTotalDiarioVendasRepositoryImpl
    implements ResumoTotalDiarioVendasRepository {
  ResumoTotalDiarioVendasRepositoryImpl(this._agentQueriesRepository);

  static const String operation = 'loadResumoTotalDiarioVendas';
  static const String _operation = operation;

  /// Delay before retrying an empty success (agent replay / flakiness).
  static const Duration emptySuccessRetryDelay = Duration(seconds: 2);

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<List<ResumoTotalDiarioVendasRow>>> load({
    required String userId,
    required String agentId,
    required ResumoTotalDiarioVendasFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        List<ResumoTotalDiarioVendasRow>
      >(
        message: validationError,
        operation: _operation,
        agentId: agentId.trim(),
      );
    }

    final trimmedAgentId = agentId.trim();

    Future<AppResult<List<ResumoTotalDiarioVendasRow>>> executeOnce() {
      final request = AgentSqlExecuteRequest(
        agentId: agentId,
        requestingUserId: userId,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
        sql: ResumoTotalDiarioVendasSql.query,
        clientToken: clientToken,
        bridgeTimeoutMs:
            bridgeTimeoutMs ?? AppEnvironment.agentSqlBridgeTimeoutMs,
        namedParams: <String, Object?>{
          'dataVendaInicio': AgentQueriesSqlLocalDate.format(
            filter.dataVendaInicio,
          ),
          'dataVendaFim': AgentQueriesSqlLocalDate.format(filter.dataVendaFim),
          'origem': filter.trimmedOrigem,
          'geraFinanceiro': filter.trimmedGeraFinanceiro,
          'preVenda': filter.trimmedPreVenda,
        },
        executeOptions: const AgentSqlExecuteOptions(
          executionMode: AgentSqlExecutionMode.preserve,
          preferDbStreaming: false,
          maxRows: AgentQueriesBoundedResultMaxRows.resumoTotalDiarioVendas,
        ),
        useRelay: true,
        // Explicit unary: documented streaming exception for sales-hub reports.
        // ignore: avoid_redundant_argument_values
        relayMode: AgentSqlRelayMode.unary,
        // Sales-hub daily totals always bypass the short transport cache,
        // including default loads (same policy as other unary report exceptions).
        skipTransportCache: switch (cachePolicy) {
          AgentQueryLoadPolicy.defaultLoad ||
          AgentQueryLoadPolicy.forceRefresh ||
          AgentQueryLoadPolicy.networkOnly => true,
        },
      );

      return AgentSqlRepositoryExecution.execute<
        List<ResumoTotalDiarioVendasRow>
      >(
        agentQueriesRepository: _agentQueriesRepository,
        request: request,
        operation: _operation,
        agentId: trimmedAgentId,
        unexpectedRowsLogMessage:
            'Unexpected row shape for ResumoTotalDiarioVendas',
        mapExecution: (executionResult) => _mapExecutionToRows(
          executionResult,
          agentId: trimmedAgentId,
          filter: filter,
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
        'agentId': trimmedAgentId,
        'retryDelayMs': emptySuccessRetryDelay.inMilliseconds,
      },
    );
    await Future<void>.delayed(emptySuccessRetryDelay);
    return executeOnce();
  }

  List<ResumoTotalDiarioVendasRow> _mapExecutionToRows(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
    required ResumoTotalDiarioVendasFilter filter,
  }) {
    final rows = executionResult.rows
        .map(
          (row) => ResumoTotalDiarioVendasRowModel.fromMap(row).toEntity(),
        )
        .toList(growable: false);
    agentQueriesWarnIfSqlRowsAtCap(
      operation: _operation,
      agentId: agentId,
      returnedRowCount: rows.length,
      maxRows: AgentQueriesBoundedResultMaxRows.resumoTotalDiarioVendas,
    );
    if (kDebugMode) {
      _logLoadSummary(
        rows,
        agentId: agentId,
        filter: filter,
      );
    }
    return rows;
  }

  void _logLoadSummary(
    List<ResumoTotalDiarioVendasRow> rows, {
    required String agentId,
    required ResumoTotalDiarioVendasFilter filter,
  }) {
    DateTime? firstDay;
    DateTime? lastDay;
    var daysWithSales = 0;
    var totalSalesCount = 0;
    var totalSalesAmount = 0.0;
    final saleDays = <DateTime>{};

    for (final row in rows) {
      final day = DateTime(
        row.dataVenda.year,
        row.dataVenda.month,
        row.dataVenda.day,
      );
      if (firstDay == null || day.isBefore(firstDay)) {
        firstDay = day;
      }
      if (lastDay == null || day.isAfter(lastDay)) {
        lastDay = day;
      }
      if (row.qtdVendas > 0 || row.valorTotalDiarioVenda > 0) {
        saleDays.add(day);
      }
      totalSalesCount += row.qtdVendas;
      totalSalesAmount += row.valorTotalDiarioVenda;
    }
    daysWithSales = saleDays.length;

    AppLogger.debug(
      'ResumoTotalDiarioVendas load summary',
      context: <String, Object?>{
        'operation': _operation,
        'agentId': agentId,
        'rowCount': rows.length,
        'filterStart': AgentQueriesSqlLocalDate.format(
          filter.dataVendaInicio,
        ),
        'filterEnd': AgentQueriesSqlLocalDate.format(filter.dataVendaFim),
        'firstReturnedDay': firstDay == null
            ? null
            : AgentQueriesSqlLocalDate.format(firstDay),
        'lastReturnedDay': lastDay == null
            ? null
            : AgentQueriesSqlLocalDate.format(lastDay),
        'daysWithSales': daysWithSales,
        'totalSalesCount': totalSalesCount,
        'totalSalesAmount': totalSalesAmount,
      },
    );
  }
}
