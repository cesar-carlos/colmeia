import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcela_forma_pagamento_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcela_forma_pagamento_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/data/repositories/progressive_report_loader.dart';
import 'package:colmeia/features/agent_queries/data/repositories/scoped_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_progress.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/progressive_report_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_repository.dart';

class ResumoParcelaFormaPagamentoRepositoryImpl
    implements
        ResumoParcelaFormaPagamentoRepository,
        ProgressiveReportRepository<
          ResumoParcelaFormaPagamentoFilter,
          ResumoParcelaFormaPagamentoRow
        > {
  ResumoParcelaFormaPagamentoRepositoryImpl(
    this._agentQueriesRepository,
  );

  static const String _operation = 'loadResumoParcelaFormaPagamento';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<List<ResumoParcelaFormaPagamentoRow>>> load({
    required String userId,
    required String agentId,
    required ResumoParcelaFormaPagamentoFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    AgentQueriesCancelScope? cancelScope,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        List<ResumoParcelaFormaPagamentoRow>
      >(
        message: validationError,
        operation: _operation,
        agentId: agentId.trim(),
      );
    }

    final request = AgentSqlExecuteRequest(
      agentId: agentId,
      requestingUserId: userId,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      sql: ResumoParcelaFormaPagamentoSql.query,
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
        preferDbStreaming: true,
        maxRows: AgentQueriesBoundedResultMaxRows.resumoParcelaFormaPagamento,
      ),
      useRelay: true,
      relayMode: AgentSqlRelayMode.streaming,
    );

    return AgentSqlRepositoryExecution.execute<
      List<ResumoParcelaFormaPagamentoRow>
    >(
      agentQueriesRepository: _agentQueriesRepository,
      request: request,
      cancelScope: cancelScope,
      operation: _operation,
      agentId: agentId.trim(),
      unexpectedRowsLogMessage:
          'Unexpected row shape for ResumoParcelaFormaPagamento',
      mapExecution: _mapExecutionToRows,
    );
  }

  List<ResumoParcelaFormaPagamentoRow> _mapExecutionToRows(
    AgentSqlExecutionResult executionResult,
  ) {
    return executionResult.rows
        .map(
          (row) => ResumoParcelaFormaPagamentoRowModel.fromMap(row).toEntity(),
        )
        .toList(growable: false);
  }

  @override
  Stream<AppResult<AgentQueryProgress<ResumoParcelaFormaPagamentoRow>>>
  loadProgressively({
    required String userId,
    required String agentId,
    required ResumoParcelaFormaPagamentoFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) => const ProgressiveReportLoader<ResumoParcelaFormaPagamentoRow>().load(
    parent: cancelScope,
    mapRows: _mapExecutionToRows,
    execute: (scope) =>
        ResumoParcelaFormaPagamentoRepositoryImpl(
          ScopedAgentQueriesRepository(_agentQueriesRepository, scope),
        ).load(
          userId: userId,
          agentId: agentId,
          filter: filter,
          clientToken: clientToken,
          bridgeTimeoutMs: bridgeTimeoutMs,
          hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
          hubConnectedFromApprovedCatalogRow:
              hubConnectedFromApprovedCatalogRow,
        ),
  );
}
