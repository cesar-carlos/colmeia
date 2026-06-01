import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcela_forma_pagamento_row_model_v2.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcela_forma_pagamento_sql_v2.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter_v2.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row_v2.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_repository_v2.dart';

class ResumoParcelaFormaPagamentoRepositoryImplV2
    implements ResumoParcelaFormaPagamentoRepositoryV2 {
  ResumoParcelaFormaPagamentoRepositoryImplV2(
    this._agentQueriesRepository,
  );

  static const String _operation = 'loadResumoParcelaFormaPagamentoV2';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<List<ResumoParcelaFormaPagamentoRowV2>>> load({
    required String userId,
    required String agentId,
    required ResumoParcelaFormaPagamentoFilterV2 filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        List<ResumoParcelaFormaPagamentoRowV2>
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
      sql: ResumoParcelaFormaPagamentoSqlV2.query,
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
      List<ResumoParcelaFormaPagamentoRowV2>
    >(
      agentQueriesRepository: _agentQueriesRepository,
      request: request,
      operation: _operation,
      agentId: agentId.trim(),
      unexpectedRowsLogMessage:
          'Unexpected row shape for ResumoParcelaFormaPagamentoV2',
      mapExecution: _mapExecutionToRows,
    );
  }

  List<ResumoParcelaFormaPagamentoRowV2> _mapExecutionToRows(
    AgentSqlExecutionResult executionResult,
  ) {
    return executionResult.rows
        .map(
          (row) =>
              ResumoParcelaFormaPagamentoRowModelV2.fromMap(row).toEntity(),
        )
        .toList(growable: false);
  }
}
