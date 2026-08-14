import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/data/models/margem_produto_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/margem_produto_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/data/resumo_vendas_diarias_suggestion_sql_params.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/margem_produto_repository.dart';
import 'package:result_dart/result_dart.dart';

/// Paged product-margin catalog (`MargemProduto`).
///
/// ## Transport
///
/// Uses relay **unary** with `preferDbStreaming: false`. E2E SQL Anywhere
/// streaming returned empty success for CTE page shapes; unary returns the
/// page slice. Skips the short transport cache. A raw empty payload is a
/// transport glitch, not an empty catalog — we retry once. A legitimate empty
/// page is a `TotalCount = 0` sentinel row.
class MargemProdutoRepositoryImpl implements MargemProdutoRepository {
  MargemProdutoRepositoryImpl(
    this._agentQueriesRepository, {
    this.emptySuccessRetryDelay = const Duration(seconds: 2),
  });

  /// Upper bound for the agent-side SQL timeout (`options.timeout_ms`).
  /// The effective value is derived as 90 % of the active bridge timeout,
  /// so a slow query surfaces as a DB-level timeout rather than HTTP
  /// cancellation.
  static const int _defaultSqlTimeoutMs = 170000;

  /// Floor for the effective SQL timeout regardless of how small a caller sets
  /// the bridge timeout. Prevents near-zero values when the bridge timeout is
  /// unusually short.
  static const int _minSqlTimeoutMs = 5000;

  /// Margin added above [MargemProdutoFilter.pageSize] when setting
  /// `max_rows` on the agent. Prevents the agent from truncating a full page
  /// while staying well below the bridge payload limit.
  static const int _maxRowsPageBuffer = 25;

  static const String _operation = 'loadMargemProdutoPage';

  final AgentQueriesRepository _agentQueriesRepository;
  final Duration emptySuccessRetryDelay;

  @override
  Future<AppResult<MargemProdutoPageResult>> loadPage({
    required String userId,
    required String agentId,
    required MargemProdutoFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        MargemProdutoPageResult
      >(
        message: validationError,
        operation: _operation,
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
    var emptyRawPayload = false;

    Future<AppResult<MargemProdutoPageResult>> executeOnce() {
      emptyRawPayload = false;
      final request = AgentSqlExecuteRequest(
        agentId: agentId,
        requestingUserId: userId,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
        // Fixed SQL order: NomeProduto ASC, CodProduto ASC (stable paging).
        sql: MargemProdutoSql.pagedQuery(),
        clientToken: clientToken,
        bridgeTimeoutMs: effectiveBridgeMs,
        namedParams: <String, Object?>{
          'codEmpresa': filter.codEmpresa,
          'codFilial': filter.codFilial,
          'nomeProdutoPattern':
              ResumoVendasDiariasSuggestionSqlParams.buildSearchPattern(
                filter.normalizedSearchTerm,
              ),
          'startRow': filter.startRow,
          'endRow': filter.endRow,
        },
        executeOptions: AgentSqlExecuteOptions(
          executionMode: AgentSqlExecutionMode.preserve,
          maxRows: filter.pageSize + _maxRowsPageBuffer,
          sqlTimeoutMs: effectiveSqlMs,
          preferDbStreaming: false,
        ),
        useRelay: true,
        // Explicit unary: documented streaming exception for this CTE page.
        // ignore: avoid_redundant_argument_values
        relayMode: AgentSqlRelayMode.unary,
        skipTransportCache: true,
      );

      return AgentSqlRepositoryExecution.execute<MargemProdutoPageResult>(
        agentQueriesRepository: _agentQueriesRepository,
        request: request,
        operation: _operation,
        agentId: trimmedAgentId,
        unexpectedRowsLogMessage: 'Unexpected row shape for $_operation',
        mapExecution: (executionResult) {
          emptyRawPayload = executionResult.rows.isEmpty;
          return _mapPagedExecution(
            executionResult,
            agentId: trimmedAgentId,
            sqlMaxRowsCap: filter.pageSize + _maxRowsPageBuffer,
          );
        },
        cancelScope: cancelScope,
      );
    }

    final first = await executeOnce();
    if (first.isError() || !emptyRawPayload) {
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
    final second = await executeOnce();
    if (second.isError() || !emptyRawPayload) {
      return second;
    }

    return Failure<MargemProdutoPageResult, AppFailure>(
      UnknownFailure(
        message:
            'Margem produto execute returned empty payload '
            '(missing TotalCount sentinel)',
        userMessage:
            AgentSqlRepositoryExecution.defaultUnexpectedRowsUserMessage,
        context: <String, Object?>{
          'operation': _operation,
          'agentId': trimmedAgentId,
        },
      ),
    );
  }

  MargemProdutoPageResult _mapPagedExecution(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
    required int sqlMaxRowsCap,
  }) {
    if (executionResult.rows.isEmpty) {
      return const MargemProdutoPageResult(
        items: <MargemProdutoRow>[],
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
        .map((row) => MargemProdutoRowModel.fromMap(row).toEntity())
        .toList(growable: false);

    return MargemProdutoPageResult(items: items, totalCount: totalCount);
  }

  static bool _rowHasProdutoKey(Map<String, dynamic> row) {
    final raw = AgentQueriesSqlRowMapReader.lookupFirst(
      row,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodProduto'),
    );
    return raw != null;
  }
}
