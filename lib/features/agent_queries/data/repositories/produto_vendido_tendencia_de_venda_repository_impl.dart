import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_batch_item_rpc_failure_mapper.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_read_only_batch_options.dart';
import 'package:colmeia/features/agent_queries/data/models/produto_vendido_tendencia_de_venda_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/produto_vendido_tendencia_de_venda_summary_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_summary_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_screen_data.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_tendencia_de_venda_repository.dart';
import 'package:result_dart/result_dart.dart';

class ProdutoVendidoTendenciaDeVendaRepositoryImpl
    implements ProdutoVendidoTendenciaDeVendaRepository {
  ProdutoVendidoTendenciaDeVendaRepositoryImpl(this._agentQueriesRepository);

  /// 90 % of the active bridge timeout, clamped for very short overrides.
  static const int _defaultSqlTimeoutMs = 162000;
  static const int _minSqlTimeoutMs = 5000;
  static const int _maxRowsPageBuffer = 25;

  static const String _operation = 'loadProdutoVendidoTendenciaDeVenda';
  static const String _summaryOperation =
      'loadProdutoVendidoTendenciaDeVendaSummary';
  static const String _batchOperation =
      'loadProdutoVendidoTendenciaDeVendaPageAndSummary';
  static const int _batchIndexPage = 0;
  static const int _batchIndexSummary = 1;
  static const int _batchIndexTopGainers = 2;
  static const int _batchIndexTopLosers = 3;

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
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        List<ProdutoVendidoTendenciaDeVendaRow>
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
        searchTerm: filter.normalizedSearchTerm,
        classificacao: filter.normalizedClassificacao,
        codGrupoProduto: filter.codGrupoProduto,
        codMarca: filter.codMarca,
      ),
      clientToken: clientToken,
      bridgeTimeoutMs: effectiveBridgeMs,
      namedParams: _buildPeriodNamedParams(filter),
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
      List<ProdutoVendidoTendenciaDeVendaRow>
    >(
      agentQueriesRepository: _agentQueriesRepository,
      request: request,
      operation: _operation,
      agentId: agentId.trim(),
      unexpectedRowsLogMessage: 'Unexpected row shape for $_operation',
      unexpectedRowsUiKey: AgentSqlRpcFailureUiKey.unexpectedAgentResponse,
      mapExecution: (executionResult) => _mapPagedExecution(
        executionResult,
        agentId: agentId.trim(),
        sqlMaxRowsCap: sqlMaxRowsCap,
      ).rows,
      cancelScope: cancelScope,
    );
  }

  @override
  Future<AppResult<List<ProdutoVendidoTendenciaDeVendaSummaryRow>>>
  loadSummary({
    required String userId,
    required String agentId,
    required ProdutoVendidoTendenciaDeVendaFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        List<ProdutoVendidoTendenciaDeVendaSummaryRow>
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

    final request = AgentSqlExecuteRequest(
      agentId: agentId,
      requestingUserId: userId,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      sql: ProdutoVendidoTendenciaDeVendaSummarySql.query(
        searchTerm: filter.normalizedSearchTerm,
        classificacao: filter.normalizedClassificacao,
        codGrupoProduto: filter.codGrupoProduto,
        codMarca: filter.codMarca,
      ),
      clientToken: clientToken,
      bridgeTimeoutMs: effectiveBridgeMs,
      namedParams: _buildPeriodNamedParams(filter),
      executeOptions: AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.preserve,
        maxRows: AgentQueriesBoundedResultMaxRows
            .produtoVendidoTendenciaDeVendaSummary,
        sqlTimeoutMs: effectiveSqlMs,
        preferDbStreaming: true,
      ),
      useRelay: true,
      relayMode: AgentSqlRelayMode.streaming,
    );

    return AgentSqlRepositoryExecution.execute<
      List<ProdutoVendidoTendenciaDeVendaSummaryRow>
    >(
      agentQueriesRepository: _agentQueriesRepository,
      request: request,
      operation: _summaryOperation,
      agentId: agentId.trim(),
      unexpectedRowsLogMessage: 'Unexpected row shape for $_summaryOperation',
      unexpectedRowsUiKey:
          AgentSqlRpcFailureUiKey.tendenciaSummaryUnexpectedFormat,
      mapExecution: _mapSummaryExecution,
      cancelScope: cancelScope,
    );
  }

  @override
  Future<AppResult<ProdutoVendidoTendenciaDeVendaScreenData>>
  loadPageAndSummary({
    required String userId,
    required String agentId,
    required ProdutoVendidoTendenciaDeVendaFilter pageFilter,
    required ProdutoVendidoTendenciaDeVendaFilter summaryFilter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final pageErr = pageFilter.validationError();
    if (pageErr != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        ProdutoVendidoTendenciaDeVendaScreenData
      >(
        message: pageErr,
        operation: _batchOperation,
        agentId: agentId.trim(),
      );
    }
    final summaryErr = summaryFilter.validationError();
    if (summaryErr != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        ProdutoVendidoTendenciaDeVendaScreenData
      >(
        message: summaryErr,
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
    final sqlMaxRowsCap = (pageFilter.pageSize + _maxRowsPageBuffer).clamp(
      _maxRowsPageBuffer + 1,
      AgentQueriesBoundedResultMaxRows.produtoVendidoTendenciaDeVenda,
    );
    const summaryMaxRows =
        AgentQueriesBoundedResultMaxRows.produtoVendidoTendenciaDeVendaSummary;
    const topMoversMaxRows =
        AgentQueriesBoundedResultMaxRows.produtoVendidoTendenciaDeVendaTopMovers;
    final batchMaxRows = [
      sqlMaxRowsCap,
      summaryMaxRows,
      topMoversMaxRows,
    ].reduce((a, b) => a > b ? a : b);

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
      options: AgentSqlReadOnlyBatchOptions.dashboard(
        sqlTimeoutMs: effectiveSqlMs,
        maxRows: batchMaxRows,
      ),
      commands: <AgentSqlExecuteBatchCommand>[
        AgentSqlExecuteBatchCommand(
          sql: ProdutoVendidoTendenciaDeVendaSql.pagedQuery(
            startRow: pageFilter.startRow,
            endRow: pageFilter.endRow,
            searchTerm: pageFilter.normalizedSearchTerm,
            classificacao: pageFilter.normalizedClassificacao,
            codGrupoProduto: pageFilter.codGrupoProduto,
            codMarca: pageFilter.codMarca,
          ),
          namedParams: _buildPeriodNamedParams(pageFilter),
          executionOrder: _batchIndexPage,
        ),
        AgentSqlExecuteBatchCommand(
          sql: ProdutoVendidoTendenciaDeVendaSummarySql.query(
            searchTerm: summaryFilter.normalizedSearchTerm,
            classificacao: summaryFilter.normalizedClassificacao,
            codGrupoProduto: summaryFilter.codGrupoProduto,
            codMarca: summaryFilter.codMarca,
          ),
          namedParams: _buildPeriodNamedParams(summaryFilter),
          executionOrder: _batchIndexSummary,
        ),
        AgentSqlExecuteBatchCommand(
          sql: ProdutoVendidoTendenciaDeVendaSql.topGainersQuery(
            searchTerm: pageFilter.normalizedSearchTerm,
            classificacao: pageFilter.normalizedClassificacao,
            codGrupoProduto: pageFilter.codGrupoProduto,
            codMarca: pageFilter.codMarca,
          ),
          namedParams: _buildPeriodNamedParams(pageFilter),
          executionOrder: _batchIndexTopGainers,
        ),
        AgentSqlExecuteBatchCommand(
          sql: ProdutoVendidoTendenciaDeVendaSql.topLosersQuery(
            searchTerm: pageFilter.normalizedSearchTerm,
            classificacao: pageFilter.normalizedClassificacao,
            codGrupoProduto: pageFilter.codGrupoProduto,
            codMarca: pageFilter.codMarca,
          ),
          namedParams: _buildPeriodNamedParams(pageFilter),
          executionOrder: _batchIndexTopLosers,
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
      Failure<ProdutoVendidoTendenciaDeVendaScreenData, AppFailure>.new,
    );
  }

  AppResult<ProdutoVendidoTendenciaDeVendaScreenData> _mapPageAndSummaryBatch(
    AgentSqlBatchExecutionResult execution, {
    required String agentId,
    required int sqlMaxRowsCap,
  }) {
    final byIndex = <int, AgentSqlBatchExecutionItem>{
      for (final item in execution.items) item.index: item,
    };
    for (final index in <int>[
      _batchIndexPage,
      _batchIndexSummary,
      _batchIndexTopGainers,
      _batchIndexTopLosers,
    ]) {
      final failure = AgentSqlBatchItemRpcFailureMapper.failureForItemOrNull(
        byIndex: byIndex,
        index: index,
        operation: _batchOperation,
      );
      if (failure != null) {
        return Failure<ProdutoVendidoTendenciaDeVendaScreenData, AppFailure>(
          _withBatchItemFailureUiKey(failure),
        );
      }
    }

    final pageItem = byIndex[_batchIndexPage]!;
    final summaryItem = byIndex[_batchIndexSummary]!;
    final topGainersItem = byIndex[_batchIndexTopGainers]!;
    final topLosersItem = byIndex[_batchIndexTopLosers]!;

    try {
      final pageResult = _mapPagedExecution(
        AgentSqlExecutionResult(
          rows: pageItem.rows,
          rowCount: pageItem.rowCount,
        ),
        agentId: agentId,
        sqlMaxRowsCap: sqlMaxRowsCap,
      );
      final rows = pageResult.rows;
      final summaryRows = _mapSummaryExecution(
        AgentSqlExecutionResult(
          rows: summaryItem.rows,
          rowCount: summaryItem.rowCount,
        ),
      );
      final topGainers = _mapExecution(
        AgentSqlExecutionResult(
          rows: topGainersItem.rows,
          rowCount: topGainersItem.rowCount,
        ),
        agentId: agentId,
        sqlMaxRowsCap: AgentQueriesBoundedResultMaxRows
            .produtoVendidoTendenciaDeVendaTopMovers,
      );
      final topLosers = _mapExecution(
        AgentSqlExecutionResult(
          rows: topLosersItem.rows,
          rowCount: topLosersItem.rowCount,
        ),
        agentId: agentId,
        sqlMaxRowsCap: AgentQueriesBoundedResultMaxRows
            .produtoVendidoTendenciaDeVendaTopMovers,
      );
      return Success<ProdutoVendidoTendenciaDeVendaScreenData, AppFailure>(
        ProdutoVendidoTendenciaDeVendaScreenData(
          rows: rows,
          totalCount: pageResult.totalCount,
          summaryRows: summaryRows,
          topGainers: topGainers,
          topLosers: topLosers,
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
      return Failure<ProdutoVendidoTendenciaDeVendaScreenData, AppFailure>(
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

  Map<String, Object?> _buildPeriodNamedParams(
    ProdutoVendidoTendenciaDeVendaFilter filter,
  ) {
    return <String, Object?>{
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
    };
  }

  _PagedRowsResult _mapPagedExecution(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
    required int sqlMaxRowsCap,
  }) {
    if (executionResult.rows.isEmpty) {
      return const _PagedRowsResult(
        rows: <ProdutoVendidoTendenciaDeVendaRow>[],
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

    final rows = executionResult.rows
        .where(_rowHasProdutoKey)
        .map(
          (row) =>
              ProdutoVendidoTendenciaDeVendaRowModel.fromMap(row).toEntity(),
        )
        .toList(growable: false);

    return _PagedRowsResult(rows: rows, totalCount: totalCount);
  }

  List<ProdutoVendidoTendenciaDeVendaRow> _mapExecution(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
    required int sqlMaxRowsCap,
  }) {
    if (executionResult.rows.isEmpty) {
      return const <ProdutoVendidoTendenciaDeVendaRow>[];
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

    return executionResult.rows
        .map(
          (row) =>
              ProdutoVendidoTendenciaDeVendaRowModel.fromMap(row).toEntity(),
        )
        .toList(growable: false);
  }

  static bool _rowHasProdutoKey(Map<String, dynamic> row) {
    final raw = AgentQueriesSqlRowMapReader.lookupFirst(
      row,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodProduto'),
    );
    return raw != null;
  }

  static AppFailure _withBatchItemFailureUiKey(AppFailure failure) {
    if (failure is! RpcFailure || failure.reason != 'missing_batch_item') {
      return failure;
    }
    if (failure.context[AgentSqlRpcFailureUiKey.field] ==
        AgentSqlRpcFailureUiKey.queryLoadFailed) {
      return failure;
    }
    return RpcFailure(
      message: failure.message,
      userMessage: failure.userMessage,
      rpcCode: failure.rpcCode,
      retryable: failure.retryable,
      reason: failure.reason,
      category: failure.category,
      technicalMessage: failure.technicalMessage,
      correlationId: failure.correlationId,
      timestamp: failure.timestamp,
      retryAfter: failure.retryAfter,
      cause: failure.cause,
      stackTrace: failure.stackTrace,
      context: <String, Object?>{
        ...failure.context,
        AgentSqlRpcFailureUiKey.field: AgentSqlRpcFailureUiKey.queryLoadFailed,
      },
    );
  }

  List<ProdutoVendidoTendenciaDeVendaSummaryRow> _mapSummaryExecution(
    AgentSqlExecutionResult executionResult,
  ) {
    if (executionResult.rows.isEmpty) {
      return const <ProdutoVendidoTendenciaDeVendaSummaryRow>[];
    }

    return executionResult.rows
        .map(
          (row) => ProdutoVendidoTendenciaDeVendaSummaryRowModel.fromMap(
            row,
          ).toEntity(),
        )
        .toList(growable: false);
  }
}

class _PagedRowsResult {
  const _PagedRowsResult({required this.rows, required this.totalCount});

  final List<ProdutoVendidoTendenciaDeVendaRow> rows;
  final int totalCount;
}
