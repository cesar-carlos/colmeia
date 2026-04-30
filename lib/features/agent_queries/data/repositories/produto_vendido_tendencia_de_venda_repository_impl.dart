import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/models/produto_vendido_tendencia_de_venda_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_tendencia_de_venda_repository.dart';
import 'package:result_dart/result_dart.dart';

class ProdutoVendidoTendenciaDeVendaRepositoryImpl
    implements ProdutoVendidoTendenciaDeVendaRepository {
  ProdutoVendidoTendenciaDeVendaRepositoryImpl(this._agentQueriesRepository);

  /// Product-level aggregate with two periods and metadata joins.
  static const int _defaultBridgeTimeoutMs = 180000;

  /// 90 % of the active bridge timeout, clamped for very short overrides.
  static const int _defaultSqlTimeoutMs = 162000;
  static const int _minSqlTimeoutMs = 5000;
  static const int _maxRowsPageBuffer = 25;

  static const String _operation = 'loadProdutoVendidoTendenciaDeVenda';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<List<ProdutoVendidoTendenciaDeVendaRow>>> loadAll({
    required String userId,
    required String agentId,
    required ProdutoVendidoTendenciaDeVendaFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return Failure<List<ProdutoVendidoTendenciaDeVendaRow>, AppFailure>(
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
    final sqlMaxRowsCap = (filter.pageSize + _maxRowsPageBuffer).clamp(
      _maxRowsPageBuffer + 1,
      AgentQueriesBoundedResultMaxRows.produtoVendidoTendenciaDeVenda,
    );

    final request = AgentSqlExecuteRequest(
      agentId: agentId,
      requestingUserId: userId,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      sql: ProdutoVendidoTendenciaDeVendaSql.pagedQuery(
        startRow: filter.startRow,
        endRow: filter.endRow,
      ),
      clientToken: clientToken,
      bridgeTimeoutMs: effectiveBridgeMs,
      namedParams: <String, Object?>{
        'periodoAtualInicio': AgentQueriesSqlLocalDate.format(
          filter.periodoAtualInicio,
        ),
        'periodoAtualFim': AgentQueriesSqlLocalDate.format(
          filter.periodoAtualFim,
        ),
        'periodoAnteriorInicio': AgentQueriesSqlLocalDate.format(
          filter.periodoAnteriorInicio,
        ),
        'periodoAnteriorFim': AgentQueriesSqlLocalDate.format(
          filter.periodoAnteriorFim,
        ),
        'origem': filter.trimmedOrigem,
      },
      executeOptions: AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.preserve,
        maxRows: sqlMaxRowsCap,
        sqlTimeoutMs: effectiveSqlMs,
      ),
      useRelay: true,
    );

    final result = await _agentQueriesRepository.executeSql(request);
    return result.fold(
      (executionResult) => _mapExecution(
        executionResult,
        agentId: agentId.trim(),
        sqlMaxRowsCap: sqlMaxRowsCap,
      ),
      Failure<List<ProdutoVendidoTendenciaDeVendaRow>, AppFailure>.new,
    );
  }

  AppResult<List<ProdutoVendidoTendenciaDeVendaRow>> _mapExecution(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
    required int sqlMaxRowsCap,
  }) {
    if (executionResult.rows.isEmpty) {
      return const Success<List<ProdutoVendidoTendenciaDeVendaRow>, AppFailure>(
        <ProdutoVendidoTendenciaDeVendaRow>[],
      );
    }

    try {
      if (executionResult.rows.length >= sqlMaxRowsCap) {
        AppLogger.warning(
          'Agent row count reached max_rows cap (possible truncation)',
          context: <String, Object?>{
            'operation': _operation,
            'agentId': agentId,
            'rowCount': executionResult.rows.length,
            'sqlMaxRowsCap': sqlMaxRowsCap,
          },
        );
      }

      final items = executionResult.rows
          .map(
            (row) =>
                ProdutoVendidoTendenciaDeVendaRowModel.fromMap(row).toEntity(),
          )
          .toList(growable: false);

      return Success<List<ProdutoVendidoTendenciaDeVendaRow>, AppFailure>(
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
      return Failure<List<ProdutoVendidoTendenciaDeVendaRow>, AppFailure>(
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
