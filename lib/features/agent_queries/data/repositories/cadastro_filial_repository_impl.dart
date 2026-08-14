import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/data/models/cadastro_filial_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/cadastro_filial_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/cadastro_filial_repository.dart';
import 'package:result_dart/result_dart.dart';

/// Paged branch registration (`Filial`).
///
/// ## Transport
///
/// Uses relay **unary** with `preferDbStreaming: false`. The CTE page shape
/// (`Tot LEFT JOIN Numbered`) must return a `TotalCount` sentinel even when
/// `Filial` is empty. A raw empty payload is a transport glitch, not "no
/// branch" — we retry once, and pickers then fall back to a simple
/// `SELECT TOP n FROM Filial`. A raw empty payload after that fallback is
/// still a transport glitch — not an empty `Filial` table (that case is a
/// `TotalCount = 0` sentinel on the CTE).
class CadastroFilialRepositoryImpl implements CadastroFilialRepository {
  CadastroFilialRepositoryImpl(
    this._agentQueriesRepository, {
    this.emptySuccessRetryDelay = const Duration(seconds: 2),
  });

  static const String _operation = 'loadCadastroFilialPage';

  final AgentQueriesRepository _agentQueriesRepository;
  final Duration emptySuccessRetryDelay;

  @override
  Future<AppResult<CadastroFilialPageResult>> loadPage({
    required String userId,
    required String agentId,
    required CadastroFilialFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final trimmedAgentId = agentId.trim();
    final validationError = filter.validationError();
    if (validationError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        CadastroFilialPageResult
      >(
        message: validationError,
        operation: _operation,
        agentId: trimmedAgentId,
      );
    }

    final selectedBranches = filter.branchesForAgent(trimmedAgentId);
    var emptyRawPayload = false;

    Future<AppResult<CadastroFilialPageResult>> executeOnce({
      required bool useSimpleBranchOptions,
    }) {
      emptyRawPayload = false;
      final request = AgentSqlExecuteRequest(
        agentId: agentId,
        requestingUserId: userId,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
        sql: useSimpleBranchOptions
            ? CadastroFilialSql.branchOptionsSimpleQuery(
                branches: selectedBranches,
                hasSelectedBranches: filter.hasSelectedBranches,
                codEmpresa: filter.codEmpresa,
                codFilial: filter.codFilial,
                searchTerm: filter.normalizedSearchTerm,
                maxRows: filter.pageSize,
              )
            : CadastroFilialSql.query(
                branches: selectedBranches,
                hasSelectedBranches: filter.hasSelectedBranches,
                codEmpresa: filter.codEmpresa,
                codFilial: filter.codFilial,
                searchTerm: filter.normalizedSearchTerm,
                projection: CadastroFilialSql.projectionFor(filter),
              ),
        clientToken: clientToken,
        bridgeTimeoutMs:
            bridgeTimeoutMs ?? AppEnvironment.agentSqlBridgeTimeoutMs,
        namedParams: useSimpleBranchOptions
            ? const <String, Object?>{}
            : <String, Object?>{
                'startRow': filter.startRow,
                'endRow': filter.endRow,
              },
        executeOptions: const AgentSqlExecuteOptions(
          executionMode: AgentSqlExecutionMode.preserve,
          maxRows: AgentQueriesBoundedResultMaxRows.cadastroFilialPage,
          preferDbStreaming: false,
        ),
        useRelay: true,
        // Explicit unary: CTE page shape returns empty success on some
        // SQL Anywhere agents when DB streaming is left at the agent default.
        // ignore: avoid_redundant_argument_values
        relayMode: AgentSqlRelayMode.unary,
        skipTransportCache: true,
      );

      return AgentSqlRepositoryExecution.execute<CadastroFilialPageResult>(
        agentQueriesRepository: _agentQueriesRepository,
        request: request,
        operation: _operation,
        agentId: trimmedAgentId,
        unexpectedRowsLogMessage: 'Unexpected row shape for $_operation',
        mapExecution: (executionResult) {
          emptyRawPayload = executionResult.rows.isEmpty;
          if (useSimpleBranchOptions) {
            return _mapSimpleExecution(executionResult);
          }
          return _mapPagedExecution(
            executionResult,
            agentId: trimmedAgentId,
          );
        },
        cancelScope: cancelScope,
      );
    }

    final first = await executeOnce(useSimpleBranchOptions: false);
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
    final second = await executeOnce(useSimpleBranchOptions: false);
    if (second.isError() || !emptyRawPayload) {
      return second;
    }

    if (filter.branchOptionsProjection) {
      AppLogger.info(
        'Falling back to simple Filial SELECT for $_operation',
        context: <String, Object?>{
          'operation': _operation,
          'agentId': trimmedAgentId,
        },
      );
      final fallback = await executeOnce(useSimpleBranchOptions: true);
      if (fallback.isError() || !emptyRawPayload) {
        return fallback;
      }
      AppLogger.warning(
        'Simple Filial SELECT also returned empty payload for $_operation',
        context: <String, Object?>{
          'operation': _operation,
          'agentId': trimmedAgentId,
        },
      );
    }

    return _emptyPayloadFailure(trimmedAgentId);
  }

  AppResult<CadastroFilialPageResult> _emptyPayloadFailure(String agentId) {
    return Failure<CadastroFilialPageResult, AppFailure>(
      UnknownFailure(
        message:
            'Cadastro filial execute returned empty payload '
            '(missing TotalCount sentinel)',
        userMessage:
            AgentSqlRepositoryExecution.defaultUnexpectedRowsUserMessage,
        context: <String, Object?>{
          'operation': _operation,
          'agentId': agentId,
        },
      ),
    );
  }

  CadastroFilialPageResult _mapPagedExecution(
    AgentSqlExecutionResult executionResult, {
    required String agentId,
  }) {
    if (executionResult.rows.isEmpty) {
      return const CadastroFilialPageResult(
        items: <CadastroFilialRow>[],
        totalCount: 0,
      );
    }

    final totalCount = AgentQueriesSqlRowMapReader.readRequiredInt(
      executionResult.rows.first,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('TotalCount'),
    );
    final items = executionResult.rows
        .where(_rowHasBranchKey)
        .map((row) => CadastroFilialRowModel.fromMap(row).toEntity())
        .toList(growable: false);

    if (totalCount == 0 && items.isEmpty) {
      AppLogger.info(
        'Cadastro filial TotalCount=0 sentinel (empty Filial table)',
        context: <String, Object?>{
          'operation': _operation,
          'agentId': agentId,
        },
      );
    }

    return CadastroFilialPageResult(items: items, totalCount: totalCount);
  }

  CadastroFilialPageResult _mapSimpleExecution(
    AgentSqlExecutionResult executionResult,
  ) {
    if (executionResult.rows.isEmpty) {
      return const CadastroFilialPageResult(
        items: <CadastroFilialRow>[],
        totalCount: 0,
      );
    }

    final items = executionResult.rows
        .where(_rowHasBranchKey)
        .map((row) => CadastroFilialRowModel.fromMap(row).toEntity())
        .toList(growable: false);
    return CadastroFilialPageResult(items: items, totalCount: items.length);
  }

  static bool _rowHasBranchKey(Map<String, dynamic> row) {
    final raw = AgentQueriesSqlRowMapReader.lookupFirst(
      row,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodEmpresa'),
    );
    return raw != null;
  }
}
