import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_read_only_batch_options.dart';
import 'package:colmeia/features/agent_queries/data/models/produto_vendido_tendencia_de_venda_media_movel_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/produto_vendido_tendencia_de_venda_media_movel_summary_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_media_movel_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_media_movel_summary_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_screen_data.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_summary_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
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
  static const String _batchOperation =
      'loadProdutoVendidoTendenciaDeVendaMediaMovelPageAndSummary';
  static const int _batchIndexPage = 0;
  static const int _batchIndexSummary = 1;

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
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        ProdutoVendidoTendenciaDeVendaMediaMovelPageResult
      >(
        message: validationError,
        operation: _operation,
        agentId: agentId.trim(),
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
        preferDbStreaming: true,
      ),
      useRelay: true,
      relayMode: AgentSqlRelayMode.streaming,
    );

    return AgentSqlRepositoryExecution.execute<
      ProdutoVendidoTendenciaDeVendaMediaMovelPageResult
    >(
      agentQueriesRepository: _agentQueriesRepository,
      request: request,
      operation: _operation,
      agentId: agentId.trim(),
      unexpectedRowsLogMessage: 'Unexpected row shape for $_operation',
      mapExecution: (executionResult) => _mapPagedExecution(
        executionResult,
        agentId: agentId.trim(),
        sqlMaxRowsCap: sqlMaxRowsCap,
      ),
      cancelScope: cancelScope,
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
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>
      >(
        message: validationError,
        operation: _summaryOperation,
        agentId: agentId.trim(),
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
        preferDbStreaming: true,
      ),
      useRelay: true,
      relayMode: AgentSqlRelayMode.streaming,
    );

    return AgentSqlRepositoryExecution.execute<
      List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>
    >(
      agentQueriesRepository: _agentQueriesRepository,
      request: request,
      operation: _summaryOperation,
      agentId: agentId.trim(),
      unexpectedRowsLogMessage: 'Unexpected row shape for $_summaryOperation',
      unexpectedRowsUserMessage:
          'Resumo da media movel veio em formato inesperado. Tente novamente.',
      mapExecution: _mapSummaryExecution,
      cancelScope: cancelScope,
    );
  }

  @override
  Future<AppResult<ProdutoVendidoTendenciaDeVendaMediaMovelScreenData>>
  loadPageAndSummary({
    required String userId,
    required String agentId,
    required ProdutoVendidoTendenciaDeVendaMediaMovelFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        ProdutoVendidoTendenciaDeVendaMediaMovelScreenData
      >(
        message: validationError,
        operation: _batchOperation,
        agentId: agentId.trim(),
      );
    }

    final trimmedAgentId = agentId.trim();
    final effectiveBridgeMs = bridgeTimeoutMs ?? _defaultBridgeTimeoutMs;
    final effectiveSqlMs = (effectiveBridgeMs * 0.9).round().clamp(
      _minSqlTimeoutMs,
      _defaultSqlTimeoutMs,
    );
    final sqlMaxRowsCap = (filter.pageSize + _maxRowsPageBuffer).clamp(
      _maxRowsPageBuffer + 1,
      AgentQueriesBoundedResultMaxRows.produtoVendidoTendenciaDeVendaMediaMovel,
    );
    const summaryMaxRows = AgentQueriesBoundedResultMaxRows
        .produtoVendidoTendenciaDeVendaMediaMovelSummary;
    final batchMaxRows = sqlMaxRowsCap > summaryMaxRows
        ? sqlMaxRowsCap
        : summaryMaxRows;

    final request = AgentSqlExecuteBatchRequest(
      agentId: agentId,
      requestingUserId: userId,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      clientToken: clientToken,
      bridgeTimeoutMs: effectiveBridgeMs,
      useRelay: true,
      options: AgentSqlReadOnlyBatchOptions.dashboard(
        sqlTimeoutMs: effectiveSqlMs,
        maxRows: batchMaxRows,
      ),
      commands: <AgentSqlExecuteBatchCommand>[
        AgentSqlExecuteBatchCommand(
          sql: ProdutoVendidoTendenciaDeVendaMediaMovelSql.pagedQuery(
            quantidadeDias: filter.quantidadeDias,
            searchTerm: filter.normalizedSearchTerm,
            classificacao: filter.normalizedClassificacao,
            codGrupoProduto: filter.codGrupoProduto,
            codMarca: filter.codMarca,
            sortBy: filter.sortBy,
          ),
          namedParams: <String, Object?>{
            'startRow': filter.startRow,
            'endRow': filter.endRow,
          },
          executionOrder: _batchIndexPage,
        ),
        AgentSqlExecuteBatchCommand(
          sql: ProdutoVendidoTendenciaDeVendaMediaMovelSummarySql.query(
            quantidadeDias: filter.quantidadeDias,
            searchTerm: filter.normalizedSearchTerm,
            classificacao: filter.normalizedClassificacao,
            codGrupoProduto: filter.codGrupoProduto,
            codMarca: filter.codMarca,
          ),
          executionOrder: _batchIndexSummary,
        ),
      ],
    );

    final batchResult = await _agentQueriesRepository.executeSqlBatch(
      request,
      cancelScope: cancelScope,
    );
    return batchResult.fold(
      (execution) => _mapPageAndSummaryBatch(
        execution,
        agentId: trimmedAgentId,
        sqlMaxRowsCap: sqlMaxRowsCap,
      ),
      Failure<ProdutoVendidoTendenciaDeVendaMediaMovelScreenData, AppFailure>
          .new,
    );
  }

  AppResult<ProdutoVendidoTendenciaDeVendaMediaMovelScreenData>
  _mapPageAndSummaryBatch(
    AgentSqlBatchExecutionResult execution, {
    required String agentId,
    required int sqlMaxRowsCap,
  }) {
    final byIndex = <int, AgentSqlBatchExecutionItem>{
      for (final item in execution.items) item.index: item,
    };
    final pageItem = byIndex[_batchIndexPage];
    if (pageItem == null) {
      return const Failure<
        ProdutoVendidoTendenciaDeVendaMediaMovelScreenData,
        AppFailure
      >(
        RpcFailure(
          message: 'sql.executeBatch page item is missing',
          userMessage: 'Nao foi possivel carregar esta consulta.',
          rpcCode: null,
          retryable: false,
          reason: 'missing_batch_item',
          context: <String, Object?>{
            'operation': _batchOperation,
            'batchItemIndex': _batchIndexPage,
          },
        ),
      );
    }
    if (!pageItem.ok) {
      return Failure<
        ProdutoVendidoTendenciaDeVendaMediaMovelScreenData,
        AppFailure
      >(
        RpcFailure(
          message: pageItem.error ?? 'sql.executeBatch page item failed',
          userMessage:
              pageItem.error ?? 'Nao foi possivel carregar esta consulta.',
          rpcCode: null,
          retryable: false,
          reason: 'batch_item_failed',
          context: <String, Object?>{
            'operation': _batchOperation,
            'batchItemIndex': _batchIndexPage,
          },
        ),
      );
    }

    final summaryItem = byIndex[_batchIndexSummary];
    if (summaryItem == null) {
      return const Failure<
        ProdutoVendidoTendenciaDeVendaMediaMovelScreenData,
        AppFailure
      >(
        RpcFailure(
          message: 'sql.executeBatch summary item is missing',
          userMessage: 'Nao foi possivel carregar esta consulta.',
          rpcCode: null,
          retryable: false,
          reason: 'missing_batch_item',
          context: <String, Object?>{
            'operation': _batchOperation,
            'batchItemIndex': _batchIndexSummary,
          },
        ),
      );
    }
    if (!summaryItem.ok) {
      return Failure<
        ProdutoVendidoTendenciaDeVendaMediaMovelScreenData,
        AppFailure
      >(
        RpcFailure(
          message: summaryItem.error ?? 'sql.executeBatch summary item failed',
          userMessage:
              summaryItem.error ?? 'Nao foi possivel carregar esta consulta.',
          rpcCode: null,
          retryable: false,
          reason: 'batch_item_failed',
          context: <String, Object?>{
            'operation': _batchOperation,
            'batchItemIndex': _batchIndexSummary,
          },
        ),
      );
    }

    try {
      final pageResult = _mapPagedExecution(
        AgentSqlExecutionResult(
          rows: pageItem.rows,
          rowCount: pageItem.rowCount,
        ),
        agentId: agentId,
        sqlMaxRowsCap: sqlMaxRowsCap,
      );
      final summaryRows = _mapSummaryExecution(
        AgentSqlExecutionResult(
          rows: summaryItem.rows,
          rowCount: summaryItem.rowCount,
        ),
      );
      return Success<
        ProdutoVendidoTendenciaDeVendaMediaMovelScreenData,
        AppFailure
      >(
        ProdutoVendidoTendenciaDeVendaMediaMovelScreenData(
          page: pageResult,
          summaryRows: summaryRows,
        ),
      );
    } on Object catch (error, stackTrace) {
      if (error is! FormatException && error is! ArgumentError) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      AppLogger.error(
        'Unexpected row shape for $_batchOperation',
        context: <String, Object?>{
          'operation': _batchOperation,
          'agentId': agentId,
        },
        error: error,
        stackTrace: stackTrace,
      );
      final message = error is FormatException
          ? error.message
          : error.toString();
      return Failure<
        ProdutoVendidoTendenciaDeVendaMediaMovelScreenData,
        AppFailure
      >(
        UnknownFailure(
          message: message,
          userMessage:
              'Resposta do agente estava em formato inesperado. Tente novamente.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': _batchOperation,
            'agentId': agentId,
          },
        ),
      );
    }
  }

  ProdutoVendidoTendenciaDeVendaMediaMovelPageResult _mapPagedExecution(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
    required int sqlMaxRowsCap,
  }) {
    if (executionResult.rows.isEmpty) {
      return const ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
        items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[],
        totalCount: 0,
      );
    }

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

    return ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
      items: items,
      totalCount: totalCount,
    );
  }

  static bool _rowHasProdutoKey(Map<String, dynamic> row) {
    final raw = AgentQueriesSqlRowMapReader.lookupFirst(
      row,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodProduto'),
    );
    return raw != null;
  }

  List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow> _mapSummaryExecution(
    AgentSqlExecutionResult executionResult,
  ) {
    if (executionResult.rows.isEmpty) {
      return const <ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[];
    }

    return executionResult.rows
        .map(
          (row) =>
              ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRowModel.fromMap(
                row,
              ).toEntity(),
        )
        .toList(growable: false);
  }
}
