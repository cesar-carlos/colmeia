import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_forma_pagamento_por_mes_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_forma_pagamento_por_mes_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/data/repositories/progressive_report_loader.dart';
import 'package:colmeia/features/agent_queries/data/repositories/scoped_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_progress.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/progressive_report_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_forma_pagamento_por_mes_repository.dart';

class ResumoParcelasFormaPagamentoPorMesRepositoryImpl
    implements
        ResumoParcelasFormaPagamentoPorMesRepository,
        ProgressiveReportRepository<
          ResumoParcelasFormaPagamentoPorMesFilter,
          ResumoParcelasFormaPagamentoPorMesRow
        > {
  ResumoParcelasFormaPagamentoPorMesRepositoryImpl(
    this._agentQueriesRepository,
  );

  /// Bridge operation id; keep in sync with the agent command allowlist.
  static const String _operation = 'loadResumoParcelasFormaPagamentoPorMes';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<List<ResumoParcelasFormaPagamentoPorMesRow>>> load({
    required String userId,
    required String agentId,
    required ResumoParcelasFormaPagamentoPorMesFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    AgentQueriesCancelScope? cancelScope,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        List<ResumoParcelasFormaPagamentoPorMesRow>
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
      sql: ResumoParcelasFormaPagamentoPorMesSql.query(
        codEmpresa: filter.codEmpresa,
        codFilial: filter.codFilial,
        codVendedor: filter.codVendedor,
      ),
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
        maxRows:
            AgentQueriesBoundedResultMaxRows.resumoParcelasFormaPagamentoPorMes,
      ),
      useRelay: true,
      relayMode: AgentSqlRelayMode.streaming,
    );

    return AgentSqlRepositoryExecution.execute<
      List<ResumoParcelasFormaPagamentoPorMesRow>
    >(
      agentQueriesRepository: _agentQueriesRepository,
      request: request,
      cancelScope: cancelScope,
      operation: _operation,
      agentId: agentId.trim(),
      unexpectedRowsLogMessage:
          'Unexpected row shape for ResumoParcelasFormaPagamentoPorMes',
      mapExecution: _mapExecutionToRows,
    );
  }

  List<ResumoParcelasFormaPagamentoPorMesRow> _mapExecutionToRows(
    AgentSqlExecutionResult executionResult,
  ) {
    return executionResult.rows
        .map(
          (row) => ResumoParcelasFormaPagamentoPorMesRowModel.fromMap(
            row,
          ).toEntity(),
        )
        .toList(growable: false);
  }

  @override
  Stream<AppResult<AgentQueryProgress<ResumoParcelasFormaPagamentoPorMesRow>>>
  loadProgressively({
    required String userId,
    required String agentId,
    required ResumoParcelasFormaPagamentoPorMesFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) => const ProgressiveReportLoader<ResumoParcelasFormaPagamentoPorMesRow>()
      .load(
        parent: cancelScope,
        mapRows: _mapExecutionToRows,
        execute: (scope) =>
            ResumoParcelasFormaPagamentoPorMesRepositoryImpl(
              ScopedAgentQueriesRepository(_agentQueriesRepository, scope),
            ).load(
              userId: userId,
              agentId: agentId,
              filter: filter,
              clientToken: clientToken,
              bridgeTimeoutMs: bridgeTimeoutMs,
              hubPresenceOnlineAgentIdsSnapshot:
                  hubPresenceOnlineAgentIdsSnapshot,
              hubConnectedFromApprovedCatalogRow:
                  hubConnectedFromApprovedCatalogRow,
            ),
      );
}
