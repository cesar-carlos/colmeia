import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_produto_venda_lucratividade_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_produto_venda_lucratividade_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_produto_venda_lucratividade_repository.dart';
import 'package:result_dart/result_dart.dart';

class ResumoProdutoVendaLucratividadeRepositoryImpl
    implements ResumoProdutoVendaLucratividadeRepository {
  ResumoProdutoVendaLucratividadeRepositoryImpl(this._agentQueriesRepository);

  /// One row per branch — very small result set; lighter than the monthly
  /// variant but covers the full period in a single aggregate.
  static const int _defaultBridgeTimeoutMs = 120000;

  /// 90 % of the active bridge timeout, clamped so short timeouts stay usable.
  static const int _defaultSqlTimeoutMs = 108000;
  static const int _minSqlTimeoutMs = 5000;

  static const String _operation = 'loadResumoProdutoVendaLucratividade';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<List<ResumoProdutoVendaLucratividadeRow>>> loadAll({
    required String userId,
    required String agentId,
    required ResumoProdutoVendaLucratividadeFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return Failure<List<ResumoProdutoVendaLucratividadeRow>, AppFailure>(
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

    final effectiveBridgeMs = bridgeTimeoutMs ?? _defaultBridgeTimeoutMs;
    final effectiveSqlMs = (effectiveBridgeMs * 0.9).round().clamp(
      _minSqlTimeoutMs,
      _defaultSqlTimeoutMs,
    );

    final request = AgentSqlExecuteRequest(
      agentId: agentId,
      requestingUserId: userId,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      sql: ResumoProdutoVendaLucratividadeSql.query,
      clientToken: clientToken,
      bridgeTimeoutMs: effectiveBridgeMs,
      namedParams: <String, Object?>{
        'dataVendaInicio': AgentQueriesSqlLocalDate.format(
          filter.dataVendaInicio,
        ),
        'dataVendaFim': AgentQueriesSqlLocalDate.format(filter.dataVendaFim),
        'origem': filter.trimmedOrigem,
      },
      executeOptions: AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.preserve,
        maxRows:
            AgentQueriesBoundedResultMaxRows.resumoProdutoVendaLucratividade,
        sqlTimeoutMs: effectiveSqlMs,
      ),
      useRelay: true,
    );

    final result = await _agentQueriesRepository.executeSql(request);
    return result.fold(
      (executionResult) =>
          _mapExecution(executionResult, agentId: agentId.trim()),
      Failure<List<ResumoProdutoVendaLucratividadeRow>, AppFailure>.new,
    );
  }

  AppResult<List<ResumoProdutoVendaLucratividadeRow>> _mapExecution(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
  }) {
    if (executionResult.rows.isEmpty) {
      return const Success<
        List<ResumoProdutoVendaLucratividadeRow>,
        AppFailure
      >(
        <ResumoProdutoVendaLucratividadeRow>[],
      );
    }

    try {
      if (executionResult.rows.length >=
          AgentQueriesBoundedResultMaxRows.resumoProdutoVendaLucratividade) {
        AppLogger.warning(
          'Agent row count reached max_rows cap (possible truncation)',
          context: <String, Object?>{
            'operation': _operation,
            'agentId': agentId,
            'rowCount': executionResult.rows.length,
            'maxRows': AgentQueriesBoundedResultMaxRows
                .resumoProdutoVendaLucratividade,
          },
        );
      }

      final items = executionResult.rows
          .map(
            (row) =>
                ResumoProdutoVendaLucratividadeRowModel.fromMap(row).toEntity(),
          )
          .toList(growable: false);

      return Success<List<ResumoProdutoVendaLucratividadeRow>, AppFailure>(
        items,
      );
    } on FormatException catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected row shape for $_operation',
        context: <String, Object?>{
          'operation': _operation,
          'agentId': agentId,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<List<ResumoProdutoVendaLucratividadeRow>, AppFailure>(
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
