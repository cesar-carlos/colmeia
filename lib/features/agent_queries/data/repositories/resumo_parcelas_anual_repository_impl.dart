import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_anual_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_anual_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/data/repositories/progressive_report_loader.dart';
import 'package:colmeia/features/agent_queries/data/repositories/scoped_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_progress.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/progressive_report_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_anual_repository.dart';
import 'package:flutter/foundation.dart';

class ResumoParcelasAnualRepositoryImpl
    implements
        ResumoParcelasAnualRepository,
        ProgressiveReportRepository<
          ResumoParcelasAnualFilter,
          ResumoParcelasAnualRow
        > {
  ResumoParcelasAnualRepositoryImpl(
    this._agentQueriesRepository,
  );

  static const String _operation = 'loadResumoParcelasAnual';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<List<ResumoParcelasAnualRow>>> load({
    required String userId,
    required String agentId,
    required ResumoParcelasAnualFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    AgentQueriesCancelScope? cancelScope,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        List<ResumoParcelasAnualRow>
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
      sql: ResumoParcelasAnualSql.query(
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
        maxRows: AgentQueriesBoundedResultMaxRows.resumoParcelasAnual,
      ),
      useRelay: true,
      relayMode: AgentSqlRelayMode.streaming,
    );

    return AgentSqlRepositoryExecution.execute<List<ResumoParcelasAnualRow>>(
      agentQueriesRepository: _agentQueriesRepository,
      request: request,
      cancelScope: cancelScope,
      operation: _operation,
      agentId: agentId.trim(),
      unexpectedRowsLogMessage: 'Unexpected row shape for ResumoParcelasAnual',
      mapExecution: (executionResult) => _mapExecutionToRows(
        executionResult,
        agentId: agentId.trim(),
        filter: filter,
      ),
    );
  }

  List<ResumoParcelasAnualRow> _mapExecutionToRows(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
    required ResumoParcelasAnualFilter filter,
  }) {
    final rows = executionResult.rows
        .map(
          (row) => ResumoParcelasAnualRowModel.fromMap(row).toEntity(),
        )
        .toList(growable: false);
    if (kDebugMode && rows.isNotEmpty) {
      final sorted = List<ResumoParcelasAnualRow>.of(rows)
        ..sort((a, b) {
          final e = a.codEmpresa.compareTo(b.codEmpresa);
          if (e != 0) {
            return e;
          }
          final f = a.codFilial.compareTo(b.codFilial);
          if (f != 0) {
            return f;
          }
          return a.anoDataVenda.compareTo(b.anoDataVenda);
        });
      final branchKeys = <String>{};
      final yearKeys = <int>{};
      var minAno = rows.first.anoDataVenda;
      var maxAno = rows.first.anoDataVenda;
      for (final r in rows) {
        branchKeys.add('${r.codEmpresa}:${r.codFilial}');
        yearKeys.add(r.anoDataVenda);
        if (r.anoDataVenda < minAno) {
          minAno = r.anoDataVenda;
        }
        if (r.anoDataVenda > maxAno) {
          maxAno = r.anoDataVenda;
        }
      }
      AppLogger.debug(
        'ResumoParcelasAnual load summary',
        context: <String, Object?>{
          'operation': _operation,
          'agentId': agentId,
          'rowCount': rows.length,
          'anoDataVendaMin': minAno,
          'anoDataVendaMax': maxAno,
          'orderedFirstKey':
              '${sorted.first.codEmpresa}:${sorted.first.codFilial}:'
              '${sorted.first.anoDataVenda}',
          'orderedLastKey':
              '${sorted.last.codEmpresa}:${sorted.last.codFilial}:'
              '${sorted.last.anoDataVenda}',
          'distinctBranchKeyCount': branchKeys.length,
          'distinctYearKeyCount': yearKeys.length,
          'sqlDimensionFiltersActive':
              filter.codEmpresa != null ||
              filter.codFilial != null ||
              filter.codVendedor != null,
        },
      );
    }
    return rows;
  }

  @override
  Stream<AppResult<AgentQueryProgress<ResumoParcelasAnualRow>>>
  loadProgressively({
    required String userId,
    required String agentId,
    required ResumoParcelasAnualFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) => const ProgressiveReportLoader<ResumoParcelasAnualRow>().load(
    parent: cancelScope,
    mapRows: (executionResult) => _mapExecutionToRows(
      executionResult,
      agentId: agentId.trim(),
      filter: filter,
    ),
    execute: (scope) =>
        ResumoParcelasAnualRepositoryImpl(
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
