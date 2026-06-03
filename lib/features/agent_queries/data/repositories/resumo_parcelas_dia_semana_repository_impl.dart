import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_dia_semana_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_dia_semana_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy_extensions.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_dia_semana_repository.dart';
import 'package:flutter/foundation.dart';

class ResumoParcelasDiaSemanaRepositoryImpl
    implements ResumoParcelasDiaSemanaRepository {
  ResumoParcelasDiaSemanaRepositoryImpl(this._agentQueriesRepository);

  static const String _operation = 'loadResumoParcelasDiaSemana';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<List<ResumoParcelasDiaSemanaRow>>> load({
    required String userId,
    required String agentId,
    required ResumoParcelasDiaSemanaFilter filter,
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
        List<ResumoParcelasDiaSemanaRow>
      >(
        message: validationError,
        operation: _operation,
        agentId: agentId.trim(),
      );
    }

    final periodAndFlagsParams = <String, Object?>{
      'dataVendaInicio': AgentQueriesSqlLocalDate.format(
        filter.dataVendaInicio,
      ),
      'dataVendaFim': AgentQueriesSqlLocalDate.format(filter.dataVendaFim),
      'origem': filter.trimmedOrigem,
      'geraFinanceiro': filter.trimmedGeraFinanceiro,
      'preVenda': filter.trimmedPreVenda,
    };
    final request = AgentSqlExecuteRequest(
      agentId: agentId,
      requestingUserId: userId,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      sql: ResumoParcelasDiaSemanaSql.query(
        codEmpresa: filter.codEmpresa,
        codFilial: filter.codFilial,
        codVendedor: filter.codVendedor,
      ),
      clientToken: clientToken,
      bridgeTimeoutMs:
          bridgeTimeoutMs ?? AppEnvironment.agentSqlBridgeTimeoutMs,
      namedParams: periodAndFlagsParams,
      executeOptions: const AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.preserve,
        preferDbStreaming: true,
        maxRows: AgentQueriesBoundedResultMaxRows.resumoParcelasDiaSemana,
      ),
      useRelay: true,
      relayMode: AgentSqlRelayMode.streaming,
      skipTransportCache: cachePolicy.bypassTransportCache,
    );

    return AgentSqlRepositoryExecution.execute<
      List<ResumoParcelasDiaSemanaRow>
    >(
      agentQueriesRepository: _agentQueriesRepository,
      request: request,
      operation: _operation,
      agentId: agentId.trim(),
      unexpectedRowsLogMessage:
          'Unexpected row shape for ResumoParcelasDiaSemana',
      mapExecution: (executionResult) => _mapExecutionToRows(
        executionResult,
        agentId: agentId.trim(),
        filter: filter,
      ),
      cancelScope: cancelScope,
    );
  }

  List<ResumoParcelasDiaSemanaRow> _mapExecutionToRows(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
    required ResumoParcelasDiaSemanaFilter filter,
  }) {
    final rows = executionResult.rows
        .map(
          (row) => ResumoParcelasDiaSemanaRowModel.fromMap(row).toEntity(),
        )
        .toList(growable: false);
    if (kDebugMode && rows.isNotEmpty) {
      final numeros = rows.map((r) => r.diaSemanaNumero).toList()..sort();
      final branchKeys = <String>{};
      final weekdayNums = <int>{};
      final compoundKeys = <String>{};
      for (final r in rows) {
        branchKeys.add('${r.codEmpresa}:${r.codFilial}');
        weekdayNums.add(r.diaSemanaNumero);
        compoundKeys.add(
          '${r.codEmpresa}|${r.codFilial}|${r.diaSemanaNumero}',
        );
      }
      AppLogger.debug(
        'ResumoParcelasDiaSemana load summary',
        context: <String, Object?>{
          'operation': _operation,
          'agentId': agentId,
          'rowCount': rows.length,
          'diaSemanaNumeroMin': numeros.first,
          'diaSemanaNumeroMax': numeros.last,
          'distinctDiaSemanaNumeroCount': weekdayNums.length,
          'distinctBranchKeyCount': branchKeys.length,
          'distinctCompoundKeyCount': compoundKeys.length,
          'sqlDimensionFiltersActive':
              filter.codEmpresa != null ||
              filter.codFilial != null ||
              filter.codVendedor != null,
        },
      );
    }
    return rows;
  }
}
