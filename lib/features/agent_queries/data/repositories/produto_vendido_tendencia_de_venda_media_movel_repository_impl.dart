import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_batch_item_rpc_failure_mapper.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_read_only_batch_options.dart';
import 'package:colmeia/features/agent_queries/data/models/produto_vendido_tendencia_de_venda_media_movel_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/produto_vendido_tendencia_de_venda_media_movel_summary_row_model.dart';
import 'package:colmeia/features/agent_queries/data/produto_tendencia_paged_sql_execution_mapper.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_media_movel_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_media_movel_summary_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_screen_data.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_summary_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_tendencia_de_venda_media_movel_repository.dart';
import 'package:result_dart/result_dart.dart';

/// Product sales trend by moving average (`ProdutoVendidoTendenciaDeVendaMediaMovel`).
///
/// ## Transport
///
/// Standalone `loadPage` / `loadSummary` use relay **unary** with
/// `preferDbStreaming: false`. Streaming returned empty success payloads on the
/// E2E SQL Anywhere agent for this CTE/window shape; pagination uses `loadPage`
/// and must not wipe the detail table. Skips the short transport cache and
/// retries once on empty success because the agent can still return an empty
/// replay.
///
/// `loadPageAndSummary` stays on `sql.executeBatch` (relay unary at the batch
/// layer) and already returned correct rows on the same agent.
class ProdutoVendidoTendenciaDeVendaMediaMovelRepositoryImpl
    implements ProdutoVendidoTendenciaDeVendaMediaMovelRepository {
  ProdutoVendidoTendenciaDeVendaMediaMovelRepositoryImpl(
    this._agentQueriesRepository,
  );

  /// 90 % of the active bridge timeout, clamped for short overrides.
  static const int _defaultSqlTimeoutMs = 162000;
  static const int _minSqlTimeoutMs = 5000;
  static const int _maxRowsPageBuffer = 25;

  /// Delay before retrying an empty success (agent replay / flakiness).
  static const Duration emptySuccessRetryDelay = Duration(seconds: 2);

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

    final effectiveBridgeMs =
        bridgeTimeoutMs ?? AppEnvironment.agentSqlBridgeMediumTimeoutMs;
    final effectiveSqlMs = (effectiveBridgeMs * 0.9).round().clamp(
      _minSqlTimeoutMs,
      _defaultSqlTimeoutMs,
    );
    final sqlMaxRowsCap = (filter.pageSize + _maxRowsPageBuffer).clamp(
      _maxRowsPageBuffer + 1,
      AgentQueriesBoundedResultMaxRows.produtoVendidoTendenciaDeVendaMediaMovel,
    );
    final trimmedAgentId = agentId.trim();
    var emptyRawPayload = false;

    Future<AppResult<ProdutoVendidoTendenciaDeVendaMediaMovelPageResult>>
    executeOnce() {
      emptyRawPayload = false;
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
          preferDbStreaming: false,
        ),
        useRelay: true,
        // Explicit unary: documented streaming exception for this CTE report.
        // ignore: avoid_redundant_argument_values
        relayMode: AgentSqlRelayMode.unary,
        skipTransportCache: true,
      );

      return AgentSqlRepositoryExecution.execute<
        ProdutoVendidoTendenciaDeVendaMediaMovelPageResult
      >(
        agentQueriesRepository: _agentQueriesRepository,
        request: request,
        operation: _operation,
        agentId: trimmedAgentId,
        unexpectedRowsLogMessage: 'Unexpected row shape for $_operation',
        unexpectedRowsUiKey: AgentSqlRpcFailureUiKey.unexpectedAgentResponse,
        mapExecution: (executionResult) {
          emptyRawPayload = executionResult.rows.isEmpty;
          return _mapPagedExecution(
            executionResult,
            agentId: trimmedAgentId,
            sqlMaxRowsCap: sqlMaxRowsCap,
          );
        },
        cancelScope: cancelScope,
      );
    }

    final first = await executeOnce();
    if (first.isError()) {
      return first;
    }
    if (!emptyRawPayload) {
      return first;
    }

    AppLogger.info(
      'Retrying empty unary success for $_operation',
      context: <String, Object?>{
        'operation': _operation,
        'agentId': trimmedAgentId,
        'retryDelayMs': emptySuccessRetryDelay.inMilliseconds,
      },
    );
    await Future<void>.delayed(emptySuccessRetryDelay);
    return executeOnce();
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

    final effectiveBridgeMs =
        bridgeTimeoutMs ?? AppEnvironment.agentSqlBridgeMediumTimeoutMs;
    final effectiveSqlMs = (effectiveBridgeMs * 0.9).round().clamp(
      _minSqlTimeoutMs,
      _defaultSqlTimeoutMs,
    );
    final trimmedAgentId = agentId.trim();

    Future<AppResult<List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>>>
    executeOnce() {
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
          preferDbStreaming: false,
        ),
        useRelay: true,
        // Explicit unary: documented streaming exception for this CTE report.
        // ignore: avoid_redundant_argument_values
        relayMode: AgentSqlRelayMode.unary,
        skipTransportCache: true,
      );

      return AgentSqlRepositoryExecution.execute<
        List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>
      >(
        agentQueriesRepository: _agentQueriesRepository,
        request: request,
        operation: _summaryOperation,
        agentId: trimmedAgentId,
        unexpectedRowsLogMessage: 'Unexpected row shape for $_summaryOperation',
        unexpectedRowsUiKey:
            AgentSqlRpcFailureUiKey.mediaMovelSummaryUnexpectedFormat,
        mapExecution: _mapSummaryExecution,
        cancelScope: cancelScope,
      );
    }

    final first = await executeOnce();
    if (first.isError()) {
      return first;
    }
    final firstRows = first.getOrThrow();
    if (firstRows.isNotEmpty) {
      return first;
    }

    AppLogger.info(
      'Retrying empty unary success for $_summaryOperation',
      context: <String, Object?>{
        'operation': _summaryOperation,
        'agentId': trimmedAgentId,
        'retryDelayMs': emptySuccessRetryDelay.inMilliseconds,
      },
    );
    await Future<void>.delayed(emptySuccessRetryDelay);
    return executeOnce();
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
    final effectiveBridgeMs =
        bridgeTimeoutMs ?? AppEnvironment.agentSqlBridgeMediumTimeoutMs;
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

    // Each batch command is an independent SQL batch on the agent; shared CTEs
    // cannot be hoisted across items. Hub parallelism is enabled via
    // [AgentSqlReadOnlyBatchOptions.dashboard] (max_parallel_read_only_batch_items).
    final request = AgentSqlExecuteBatchRequest(
      agentId: agentId,
      requestingUserId: userId,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      clientToken: clientToken,
      bridgeTimeoutMs: effectiveBridgeMs,
      useRelay: true,
      skipTransportCache: true,
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
    final batchFailure =
        AgentSqlBatchItemRpcFailureMapper.firstFailureForIndicesOrNull(
          byIndex: byIndex,
          indices: <int>[_batchIndexPage, _batchIndexSummary],
          operation: _batchOperation,
        );
    if (batchFailure != null) {
      return Failure<
        ProdutoVendidoTendenciaDeVendaMediaMovelScreenData,
        AppFailure
      >(
        AgentSqlBatchItemRpcFailureMapper.withQueryLoadFailedUiKey(
          batchFailure,
        ),
      );
    }

    final pageItem = byIndex[_batchIndexPage]!;
    final summaryItem = byIndex[_batchIndexSummary]!;

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
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': _batchOperation,
            'agentId': agentId,
            AgentSqlRpcFailureUiKey.field:
                AgentSqlRpcFailureUiKey.unexpectedAgentResponse,
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
    final mapped = ProdutoTendenciaPagedSqlExecutionMapper.mapPagedRows(
      executionResult: executionResult,
      operation: _operation,
      agentId: agentId,
      sqlMaxRowsCap: sqlMaxRowsCap,
      mapRow: (row) => ProdutoVendidoTendenciaDeVendaMediaMovelRowModel.fromMap(
        row,
      ).toEntity(),
    );
    return ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
      items: mapped.items,
      totalCount: mapped.totalCount,
    );
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
