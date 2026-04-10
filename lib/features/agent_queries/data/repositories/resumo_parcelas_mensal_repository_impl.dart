import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_mensal_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_mensal_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_labels.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_mensal_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:result_dart/result_dart.dart';

class ResumoParcelasMensalRepositoryImpl
    implements ResumoParcelasMensalRepository {
  ResumoParcelasMensalRepositoryImpl(
    this._agentQueriesRepository,
  );

  static const int _defaultBridgeTimeoutMs = 120000;
  static const String _operation = 'loadResumoParcelasMensal';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<List<ResumoParcelasMensalRow>>> load({
    required String agentId,
    required ResumoParcelasMensalFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return Failure<List<ResumoParcelasMensalRow>, AppFailure>(
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
      sql: ResumoParcelasMensalSql.query,
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
      },
      executeOptions: const AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.preserve,
        maxRows: AgentQueriesBoundedResultMaxRows.resumoParcelasMensal,
      ),
    );

    final result = await _agentQueriesRepository.executeSql(request);
    return result.fold(
      (executionResult) => _mapExecutionToRows(
        executionResult,
        agentId: agentId.trim(),
      ),
      Failure<List<ResumoParcelasMensalRow>, AppFailure>.new,
    );
  }

  AppResult<List<ResumoParcelasMensalRow>> _mapExecutionToRows(
    AgentSqlExecutionResult executionResult, {
      required String agentId,
    }) {
    try {
      final rows = executionResult.rows
          .map(
            (row) => ResumoParcelasMensalRowModel.fromMap(row).toEntity(),
          )
          .toList(growable: false);
      if (kDebugMode && rows.isNotEmpty) {
        final sorted = List<ResumoParcelasMensalRow>.of(rows)
          ..sort((a, b) {
            final byAno = a.ano.compareTo(b.ano);
            return byAno != 0 ? byAno : a.mes.compareTo(b.mes);
          });
        final calendarOutOfRangeRowCount = rows
            .where(
              (r) => !ResumoParcelasMensalLabels.isValidCalendarYear(r.ano),
            )
            .length;
        AppLogger.debug(
          'ResumoParcelasMensal load summary',
          context: <String, Object?>{
            'operation': _operation,
            'agentId': agentId,
            'rowCount': rows.length,
            'anoMesFirst': sorted.first.anoMes,
            'anoMesLast': sorted.last.anoMes,
            'calendarOutOfRangeRowCount': calendarOutOfRangeRowCount,
          },
        );
      }
      return Success<List<ResumoParcelasMensalRow>, AppFailure>(rows);
    } catch (error, stackTrace) {
      if (error is! FormatException && error is! ArgumentError) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      AppLogger.error(
        'Unexpected row shape for ResumoParcelasMensal',
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
      return Failure<List<ResumoParcelasMensalRow>, AppFailure>(
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
