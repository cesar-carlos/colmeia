import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_anual_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_anual_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_sql_dimension_filters.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_anual_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:result_dart/result_dart.dart';

class ResumoParcelasAnualRepositoryImpl
    implements ResumoParcelasAnualRepository {
  ResumoParcelasAnualRepositoryImpl(
    this._agentQueriesRepository,
  );

  static const int _defaultBridgeTimeoutMs = 120000;
  static const String _operation = 'loadResumoParcelasAnual';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<List<ResumoParcelasAnualRow>>> load({
    required String agentId,
    required ResumoParcelasAnualFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return Failure<List<ResumoParcelasAnualRow>, AppFailure>(
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

    final request = AgentSqlExecuteRequest(
      agentId: agentId,
      sql: ResumoParcelasAnualSql.query,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs ?? _defaultBridgeTimeoutMs,
      namedParams: <String, Object?>{
        'dataVendaInicio': AgentQueriesSqlLocalDate.format(
          filter.dataVendaInicio,
        ),
        'dataVendaFim': AgentQueriesSqlLocalDate.format(filter.dataVendaFim),
        'origem': filter.trimmedOrigem,
        'geraFinanceiro': filter.trimmedGeraFinanceiro,
        'preVenda': filter.trimmedPreVenda,
        ...ResumoParcelasSqlDimensionFilters.namedParams(
          codEmpresa: filter.codEmpresa,
          codFilial: filter.codFilial,
          codVendedor: filter.codVendedor,
        ),
      },
      executeOptions: const AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.preserve,
        maxRows: AgentQueriesBoundedResultMaxRows.resumoParcelasAnual,
      ),
    );

    final result = await _agentQueriesRepository.executeSql(request);
    return result.fold(
      (executionResult) => _mapExecutionToRows(
        executionResult,
        agentId: agentId.trim(),
        filter: filter,
      ),
      Failure<List<ResumoParcelasAnualRow>, AppFailure>.new,
    );
  }

  AppResult<List<ResumoParcelasAnualRow>> _mapExecutionToRows(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
    required ResumoParcelasAnualFilter filter,
  }) {
    try {
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
      return Success<List<ResumoParcelasAnualRow>, AppFailure>(rows);
    } catch (error, stackTrace) {
      if (error is! FormatException && error is! ArgumentError) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      AppLogger.error(
        'Unexpected row shape for ResumoParcelasAnual',
        context: <String, Object?>{
          'operation': _operation,
          'agentId': agentId,
        },
        error: error,
        stackTrace: stackTrace,
      );
      final message = error is FormatException
          ? error.message
          : error.toString();
      return Failure<List<ResumoParcelasAnualRow>, AppFailure>(
        UnknownFailure(
          message: message,
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
