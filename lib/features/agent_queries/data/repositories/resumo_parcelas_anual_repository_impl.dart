import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_anual_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_anual_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_anual_repository.dart';
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
      },
      executeOptions: const AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.preserve,
      ),
    );

    final result = await _agentQueriesRepository.executeSql(request);
    return result.fold(
      (executionResult) => _mapExecutionToRows(
        executionResult,
        agentId: agentId.trim(),
      ),
      Failure<List<ResumoParcelasAnualRow>, AppFailure>.new,
    );
  }

  AppResult<List<ResumoParcelasAnualRow>> _mapExecutionToRows(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
  }) {
    try {
      final rows = executionResult.rows
          .map(
            (row) => ResumoParcelasAnualRowModel.fromMap(row).toEntity(),
          )
          .toList(growable: false);
      return Success<List<ResumoParcelasAnualRow>, AppFailure>(rows);
    } on FormatException catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected row shape for ResumoParcelasAnual',
        context: <String, Object?>{
          'operation': _operation,
          'agentId': agentId,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<List<ResumoParcelasAnualRow>, AppFailure>(
        UnknownFailure(
          message: error.message,
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
