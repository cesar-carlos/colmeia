import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/data/models/produto_vendido_tendencia_de_venda_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/produto_vendido_tendencia_de_venda_summary_row_model.dart';
import 'package:colmeia/features/agent_queries/data/produto_tendencia_paged_sql_execution_mapper.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_screen_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_summary_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_screen_data.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_tendencia_de_venda_repository.dart';

/// Product sales trend (`ProdutoVendidoTendenciaDeVenda`).
///
/// ## Transport
///
/// Standalone `loadPage` / `loadSummary` and screen `loadPageAndSummary` use
/// relay **unary** with `preferDbStreaming: false`. Streaming returned empty
/// success payloads on the E2E SQL Anywhere agent for this CTE shape;
/// pagination uses `loadPage` and must not wipe the detail table. Retries once
/// on empty success because the agent can still return an empty replay.
///
/// Transport cache is enabled for identical filter fingerprints. Day-bucket /
/// Hive facts are **not** used: custom period windows and metric/threshold
/// knobs do not map cleanly onto fixed calendar day facts.
///
/// `loadPageAndSummary` runs one tagged `UNION ALL` query over a shared CTE
/// universe (summary + page + top movers) instead of `sql.executeBatch`.
class ProdutoVendidoTendenciaDeVendaRepositoryImpl
    implements ProdutoVendidoTendenciaDeVendaRepository {
  ProdutoVendidoTendenciaDeVendaRepositoryImpl(this._agentQueriesRepository);

  /// 90 % of the active bridge timeout, clamped for very short overrides.
  static const int _defaultSqlTimeoutMs = 162000;
  static const int _minSqlTimeoutMs = 5000;
  static const int _maxRowsPageBuffer = 25;

  /// Delay before retrying an empty success (agent replay / flakiness).
  static const Duration emptySuccessRetryDelay = Duration(seconds: 2);

  static const String _operation = 'loadProdutoVendidoTendenciaDeVendaPage';
  static const String _summaryOperation =
      'loadProdutoVendidoTendenciaDeVendaSummary';
  static const String _screenOperation =
      'loadProdutoVendidoTendenciaDeVendaPageAndSummary';
  static const String _topMoversOperation =
      'loadProdutoVendidoTendenciaDeVendaTopMovers';

  static const String errorScreenUniverseMismatch =
      'pageFilter and summaryFilter must share the same search, grupo, marca, '
      'filial, metric, volume floor, threshold, origem, and periods for '
      'screen load';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<ProdutoVendidoTendenciaDeVendaPageResult>> loadPage({
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
        ProdutoVendidoTendenciaDeVendaPageResult
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
    final trimmedAgentId = agentId.trim();

    Future<AppResult<ProdutoVendidoTendenciaDeVendaPageResult>> executeOnce() {
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
          codFilial: filter.codFilial,
          metricMode: filter.metricMode,
          minVolumeUnits: filter.minVolumeUnits,
          trendThresholdPercent: filter.trendThresholdPercent,
        ),
        clientToken: clientToken,
        bridgeTimeoutMs: effectiveBridgeMs,
        namedParams: _buildPeriodNamedParams(filter),
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
      );

      return AgentSqlRepositoryExecution.execute<
        ProdutoVendidoTendenciaDeVendaPageResult
      >(
        agentQueriesRepository: _agentQueriesRepository,
        request: request,
        operation: _operation,
        agentId: trimmedAgentId,
        unexpectedRowsLogMessage: 'Unexpected row shape for $_operation',
        unexpectedRowsUiKey: AgentSqlRpcFailureUiKey.unexpectedAgentResponse,
        mapExecution: (executionResult) => _mapPagedExecution(
          executionResult,
          agentId: trimmedAgentId,
          sqlMaxRowsCap: sqlMaxRowsCap,
        ),
        cancelScope: cancelScope,
      );
    }

    final first = await executeOnce();
    if (first.isError()) {
      return first;
    }
    final firstPage = first.getOrThrow();
    if (firstPage.items.isNotEmpty || firstPage.totalCount > 0) {
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
    final pageResult = await loadPage(
      userId: userId,
      agentId: agentId,
      filter: filter,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      cancelScope: cancelScope,
    );
    return pageResult.map((page) => page.items);
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

    final trimmedAgentId = agentId.trim();

    Future<AppResult<List<ProdutoVendidoTendenciaDeVendaSummaryRow>>>
    executeOnce() {
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
          codFilial: filter.codFilial,
          metricMode: filter.metricMode,
          minVolumeUnits: filter.minVolumeUnits,
          trendThresholdPercent: filter.trendThresholdPercent,
        ),
        clientToken: clientToken,
        bridgeTimeoutMs: effectiveBridgeMs,
        namedParams: _buildPeriodNamedParams(filter),
        executeOptions: AgentSqlExecuteOptions(
          executionMode: AgentSqlExecutionMode.preserve,
          maxRows: AgentQueriesBoundedResultMaxRows
              .produtoVendidoTendenciaDeVendaSummary,
          sqlTimeoutMs: effectiveSqlMs,
          preferDbStreaming: false,
        ),
        useRelay: true,
        // Explicit unary: documented streaming exception for this CTE report.
        // ignore: avoid_redundant_argument_values
        relayMode: AgentSqlRelayMode.unary,
      );

      return AgentSqlRepositoryExecution.execute<
        List<ProdutoVendidoTendenciaDeVendaSummaryRow>
      >(
        agentQueriesRepository: _agentQueriesRepository,
        request: request,
        operation: _summaryOperation,
        agentId: trimmedAgentId,
        unexpectedRowsLogMessage: 'Unexpected row shape for $_summaryOperation',
        unexpectedRowsUiKey:
            AgentSqlRpcFailureUiKey.tendenciaSummaryUnexpectedFormat,
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
        operation: _screenOperation,
        agentId: agentId.trim(),
      );
    }
    final summaryErr = summaryFilter.validationError();
    if (summaryErr != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        ProdutoVendidoTendenciaDeVendaScreenData
      >(
        message: summaryErr,
        operation: _screenOperation,
        agentId: agentId.trim(),
      );
    }
    final universeErr = _screenUniverseMismatchError(
      pageFilter: pageFilter,
      summaryFilter: summaryFilter,
    );
    if (universeErr != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        ProdutoVendidoTendenciaDeVendaScreenData
      >(
        message: universeErr,
        operation: _screenOperation,
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
    final pageMaxRowsCap = (pageFilter.pageSize + _maxRowsPageBuffer).clamp(
      _maxRowsPageBuffer + 1,
      AgentQueriesBoundedResultMaxRows.produtoVendidoTendenciaDeVenda,
    );
    const summaryMaxRows =
        AgentQueriesBoundedResultMaxRows.produtoVendidoTendenciaDeVendaSummary;
    const topMoversMaxRows = AgentQueriesBoundedResultMaxRows
        .produtoVendidoTendenciaDeVendaTopMovers;
    final screenMaxRows =
        (summaryMaxRows + pageMaxRowsCap + (2 * topMoversMaxRows)).clamp(
          _maxRowsPageBuffer + 1,
          AgentQueriesBoundedResultMaxRows.produtoVendidoTendenciaDeVenda,
        );

    Future<AppResult<ProdutoVendidoTendenciaDeVendaScreenData>> executeOnce() {
      final request = AgentSqlExecuteRequest(
        agentId: agentId,
        requestingUserId: userId,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
        sql: ProdutoVendidoTendenciaDeVendaScreenSql.query(
          startRow: pageFilter.startRow,
          endRow: pageFilter.endRow,
          searchTerm: pageFilter.normalizedSearchTerm,
          pageClassificacao: pageFilter.normalizedClassificacao,
          summaryClassificacao: summaryFilter.normalizedClassificacao,
          codGrupoProduto: pageFilter.codGrupoProduto,
          codMarca: pageFilter.codMarca,
          codFilial: pageFilter.codFilial,
          metricMode: pageFilter.metricMode,
          minVolumeUnits: pageFilter.minVolumeUnits,
          trendThresholdPercent: pageFilter.trendThresholdPercent,
          topMoversSortBy: pageFilter.topMoversSortBy,
        ),
        clientToken: clientToken,
        bridgeTimeoutMs: effectiveBridgeMs,
        namedParams: _buildPeriodNamedParams(pageFilter),
        executeOptions: AgentSqlExecuteOptions(
          executionMode: AgentSqlExecutionMode.preserve,
          maxRows: screenMaxRows,
          sqlTimeoutMs: effectiveSqlMs,
          preferDbStreaming: false,
        ),
        useRelay: true,
        // Explicit unary: documented streaming exception for this CTE report.
        // ignore: avoid_redundant_argument_values
        relayMode: AgentSqlRelayMode.unary,
      );

      return AgentSqlRepositoryExecution.execute<
        ProdutoVendidoTendenciaDeVendaScreenData
      >(
        agentQueriesRepository: _agentQueriesRepository,
        request: request,
        operation: _screenOperation,
        agentId: trimmedAgentId,
        unexpectedRowsLogMessage: 'Unexpected row shape for $_screenOperation',
        unexpectedRowsUiKey: AgentSqlRpcFailureUiKey.unexpectedAgentResponse,
        mapExecution: (executionResult) => _mapScreenExecution(
          executionResult,
          agentId: trimmedAgentId,
          pageMaxRowsCap: pageMaxRowsCap,
        ),
        cancelScope: cancelScope,
      );
    }

    final first = await executeOnce();
    if (first.isError()) {
      return first;
    }
    final firstData = first.getOrThrow();
    if (!_isEmptyScreenData(firstData)) {
      return first;
    }

    AppLogger.info(
      'Retrying empty unary success for $_screenOperation',
      context: <String, Object?>{
        'operation': _screenOperation,
        'agentId': trimmedAgentId,
        'retryDelayMs': emptySuccessRetryDelay.inMilliseconds,
      },
    );
    await Future<void>.delayed(emptySuccessRetryDelay);
    return executeOnce();
  }

  static bool _isEmptyScreenData(
    ProdutoVendidoTendenciaDeVendaScreenData data,
  ) {
    return data.totalCount == 0 &&
        data.rows.isEmpty &&
        data.summaryRows.isEmpty &&
        data.topGainers.isEmpty &&
        data.topLosers.isEmpty;
  }

  static String? _screenUniverseMismatchError({
    required ProdutoVendidoTendenciaDeVendaFilter pageFilter,
    required ProdutoVendidoTendenciaDeVendaFilter summaryFilter,
  }) {
    if (pageFilter.normalizedSearchTerm != summaryFilter.normalizedSearchTerm ||
        pageFilter.codGrupoProduto != summaryFilter.codGrupoProduto ||
        pageFilter.codMarca != summaryFilter.codMarca ||
        pageFilter.codFilial != summaryFilter.codFilial ||
        pageFilter.metricMode != summaryFilter.metricMode ||
        pageFilter.minVolumeUnits != summaryFilter.minVolumeUnits ||
        pageFilter.trendThresholdPercent !=
            summaryFilter.trendThresholdPercent ||
        pageFilter.trimmedOrigem != summaryFilter.trimmedOrigem ||
        !_sameCalendarDate(
          pageFilter.periodoAtualInicio,
          summaryFilter.periodoAtualInicio,
        ) ||
        !_sameCalendarDate(
          pageFilter.periodoAtualFim,
          summaryFilter.periodoAtualFim,
        ) ||
        !_sameCalendarDate(
          pageFilter.periodoAnteriorInicio,
          summaryFilter.periodoAnteriorInicio,
        ) ||
        !_sameCalendarDate(
          pageFilter.periodoAnteriorFim,
          summaryFilter.periodoAnteriorFim,
        )) {
      return errorScreenUniverseMismatch;
    }
    return null;
  }

  static bool _sameCalendarDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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

  ProdutoVendidoTendenciaDeVendaScreenData _mapScreenExecution(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
    required int pageMaxRowsCap,
  }) {
    if (executionResult.rows.isEmpty) {
      return const ProdutoVendidoTendenciaDeVendaScreenData(
        rows: <ProdutoVendidoTendenciaDeVendaRow>[],
        totalCount: 0,
        summaryRows: <ProdutoVendidoTendenciaDeVendaSummaryRow>[],
        topGainers: <ProdutoVendidoTendenciaDeVendaRow>[],
        topLosers: <ProdutoVendidoTendenciaDeVendaRow>[],
      );
    }

    if (executionResult.rows.length >=
        AgentQueriesBoundedResultMaxRows.produtoVendidoTendenciaDeVenda) {
      AppLogger.warning(
        'Agent row count reached max_rows cap (possible truncation)',
        context: <String, Object?>{
          'operation': _screenOperation,
          'agentId': agentId,
          'rowCount': executionResult.rows.length,
          'maxRows':
              AgentQueriesBoundedResultMaxRows.produtoVendidoTendenciaDeVenda,
        },
      );
    }

    final summaryMaps = <Map<String, dynamic>>[];
    final pageMaps = <Map<String, dynamic>>[];
    final gainerMaps = <Map<String, dynamic>>[];
    final loserMaps = <Map<String, dynamic>>[];

    for (final row in executionResult.rows) {
      final kind = AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
        row,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('RowKind'),
      ).toUpperCase();
      switch (kind) {
        case ProdutoVendidoTendenciaDeVendaScreenSql.rowKindSummary:
          summaryMaps.add(row);
        case ProdutoVendidoTendenciaDeVendaScreenSql.rowKindPage:
          pageMaps.add(row);
        case ProdutoVendidoTendenciaDeVendaScreenSql.rowKindGainer:
          gainerMaps.add(row);
        case ProdutoVendidoTendenciaDeVendaScreenSql.rowKindLoser:
          loserMaps.add(row);
        default:
          throw FormatException(
            'Unexpected RowKind "$kind" for $_screenOperation',
          );
      }
    }

    final pageResult = _mapPagedExecution(
      AgentSqlExecutionResult(rows: pageMaps, rowCount: pageMaps.length),
      agentId: agentId,
      sqlMaxRowsCap: pageMaxRowsCap,
    );

    return ProdutoVendidoTendenciaDeVendaScreenData(
      rows: pageResult.items,
      totalCount: pageResult.totalCount,
      summaryRows: _mapSummaryExecution(
        AgentSqlExecutionResult(
          rows: summaryMaps,
          rowCount: summaryMaps.length,
        ),
      ),
      topGainers: _mapExecution(
        AgentSqlExecutionResult(rows: gainerMaps, rowCount: gainerMaps.length),
        agentId: agentId,
        operation: _topMoversOperation,
        sqlMaxRowsCap: AgentQueriesBoundedResultMaxRows
            .produtoVendidoTendenciaDeVendaTopMovers,
      ),
      topLosers: _mapExecution(
        AgentSqlExecutionResult(rows: loserMaps, rowCount: loserMaps.length),
        agentId: agentId,
        operation: _topMoversOperation,
        sqlMaxRowsCap: AgentQueriesBoundedResultMaxRows
            .produtoVendidoTendenciaDeVendaTopMovers,
      ),
    );
  }

  ProdutoVendidoTendenciaDeVendaPageResult _mapPagedExecution(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
    required int sqlMaxRowsCap,
  }) {
    final mapped = ProdutoTendenciaPagedSqlExecutionMapper.mapPagedRows(
      executionResult: executionResult,
      operation: _operation,
      agentId: agentId,
      sqlMaxRowsCap: sqlMaxRowsCap,
      mapRow: (row) =>
          ProdutoVendidoTendenciaDeVendaRowModel.fromMap(row).toEntity(),
    );
    return ProdutoVendidoTendenciaDeVendaPageResult(
      items: mapped.items,
      totalCount: mapped.totalCount,
    );
  }

  List<ProdutoVendidoTendenciaDeVendaRow> _mapExecution(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
    required String operation,
    required int sqlMaxRowsCap,
  }) {
    if (executionResult.rows.isEmpty) {
      return const <ProdutoVendidoTendenciaDeVendaRow>[];
    }

    if (executionResult.rows.length >= sqlMaxRowsCap) {
      AppLogger.warning(
        'Agent row count reached max_rows cap (possible truncation)',
        context: <String, Object?>{
          'operation': operation,
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
