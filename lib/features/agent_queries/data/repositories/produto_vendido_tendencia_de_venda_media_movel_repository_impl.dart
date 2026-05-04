import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/data/models/produto_vendido_tendencia_de_venda_media_movel_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/produto_vendido_tendencia_de_venda_media_movel_summary_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_media_movel_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_media_movel_summary_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_summary_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_tendencia_de_venda_media_movel_repository.dart';
import 'package:result_dart/result_dart.dart';

class ProdutoVendidoTendenciaDeVendaMediaMovelRepositoryImpl
    implements ProdutoVendidoTendenciaDeVendaMediaMovelRepository {
  ProdutoVendidoTendenciaDeVendaMediaMovelRepositoryImpl(
    this._agentQueriesRepository,
  );

  /// HTTP bridge wait for a moving-average product report with multiple joins.
  static const int _defaultBridgeTimeoutMs = 180000;

  /// 90 % of the active bridge timeout, clamped for short overrides.
  static const int _defaultSqlTimeoutMs = 162000;
  static const int _minSqlTimeoutMs = 5000;
  static const int _maxRowsPageBuffer = 25;

  static const String _operation =
      'loadProdutoVendidoTendenciaDeVendaMediaMovelPage';
  static const String _summaryOperation =
      'loadProdutoVendidoTendenciaDeVendaMediaMovelSummary';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<ProdutoVendidoTendenciaDeVendaMediaMovelPageResult>>
  loadPage({
    required String userId,
    required String agentId,
    required ProdutoVendidoTendenciaDeVendaMediaMovelFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return Failure<
        ProdutoVendidoTendenciaDeVendaMediaMovelPageResult,
        AppFailure
      >(
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
      AgentQueriesBoundedResultMaxRows.produtoVendidoTendenciaDeVendaMediaMovel,
    );

    final request = AgentSqlExecuteRequest(
      agentId: agentId,
      requestingUserId: userId,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      sql: ProdutoVendidoTendenciaDeVendaMediaMovelSql.pagedQuery(
        quantidadeDias: filter.quantidadeDias,
        searchTerm: filter.normalizedSearchTerm,
        classificacao: filter.normalizedClassificacao,
        codGrupoProduto: filter.codGrupoProduto,
        codMarca: filter.codMarca,
        sortBy: filter.sortBy,
      ),
      clientToken: clientToken,
      bridgeTimeoutMs: effectiveBridgeMs,
      namedParams: <String, Object?>{
        'startRow': filter.startRow,
        'endRow': filter.endRow,
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
      (executionResult) => _mapPagedExecution(
        executionResult,
        agentId: agentId.trim(),
        sqlMaxRowsCap: sqlMaxRowsCap,
      ),
      Failure<ProdutoVendidoTendenciaDeVendaMediaMovelPageResult, AppFailure>
          .new,
    );
  }

  @override
  Future<AppResult<List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>>>
  loadSummary({
    required String userId,
    required String agentId,
    required ProdutoVendidoTendenciaDeVendaMediaMovelFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return Failure<
        List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>,
        AppFailure
      >(
        ValidationFailure(
          message: validationError,
          userMessage: 'Os filtros da consulta sao invalidos.',
          context: <String, Object?>{
            'operation': _summaryOperation,
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
      sql: ProdutoVendidoTendenciaDeVendaMediaMovelSummarySql.query(
        quantidadeDias: filter.quantidadeDias,
        searchTerm: filter.normalizedSearchTerm,
        classificacao: filter.normalizedClassificacao,
        codGrupoProduto: filter.codGrupoProduto,
        codMarca: filter.codMarca,
      ),
      clientToken: clientToken,
      bridgeTimeoutMs: effectiveBridgeMs,
      executeOptions: AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.preserve,
        maxRows: AgentQueriesBoundedResultMaxRows
            .produtoVendidoTendenciaDeVendaMediaMovelSummary,
        sqlTimeoutMs: effectiveSqlMs,
      ),
      useRelay: true,
    );

    final result = await _agentQueriesRepository.executeSql(request);
    return result.fold(
      (executionResult) => _mapSummaryExecution(
        executionResult,
        agentId: agentId.trim(),
      ),
      Failure<
            List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>,
            AppFailure
          >
          .new,
    );
  }

  AppResult<ProdutoVendidoTendenciaDeVendaMediaMovelPageResult>
  _mapPagedExecution(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
    required int sqlMaxRowsCap,
  }) {
    if (executionResult.rows.isEmpty) {
      return const Success<
        ProdutoVendidoTendenciaDeVendaMediaMovelPageResult,
        AppFailure
      >(
        ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
          items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[],
          totalCount: 0,
        ),
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

      final totalCount = AgentQueriesSqlRowMapReader.readRequiredInt(
        executionResult.rows.first,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('TotalCount'),
      );

      final items = executionResult.rows
          .where(_rowHasProdutoKey)
          .map(
            (row) => ProdutoVendidoTendenciaDeVendaMediaMovelRowModel.fromMap(
              row,
            ).toEntity(),
          )
          .toList(growable: false);

      return Success<
        ProdutoVendidoTendenciaDeVendaMediaMovelPageResult,
        AppFailure
      >(
        ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
          items: items,
          totalCount: totalCount,
        ),
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
      return Failure<
        ProdutoVendidoTendenciaDeVendaMediaMovelPageResult,
        AppFailure
      >(
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

  static bool _rowHasProdutoKey(Map<String, dynamic> row) {
    final raw = AgentQueriesSqlRowMapReader.lookupFirst(
      row,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodProduto'),
    );
    return raw != null;
  }

  AppResult<List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>>
  _mapSummaryExecution(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
  }) {
    if (executionResult.rows.isEmpty) {
      return const Success<
        List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>,
        AppFailure
      >(<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[]);
    }

    try {
      final items = executionResult.rows
          .map(
            (row) =>
                ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRowModel.fromMap(
                  row,
                ).toEntity(),
          )
          .toList(growable: false);
      return Success<
        List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>,
        AppFailure
      >(items);
    } on FormatException catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected row shape for $_summaryOperation',
        context: <String, Object?>{
          'operation': _summaryOperation,
          'agentId': agentId,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<
        List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>,
        AppFailure
      >(
        UnknownFailure(
          message: error.message,
          userMessage:
              'Resumo da media movel veio em formato inesperado. '
              'Tente novamente.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': _summaryOperation,
            'agentId': agentId,
          },
        ),
      );
    }
  }
}
