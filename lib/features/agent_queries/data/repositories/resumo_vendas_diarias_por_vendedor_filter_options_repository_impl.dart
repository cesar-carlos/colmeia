import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_batch_item_rows_mapper.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_read_only_batch_options.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_vendas_diarias_por_vendedor_text_option_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_vendas_diarias_por_vendedor_vendedor_option_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_vendas_diarias_por_vendedor_bairro_options_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_vendas_diarias_por_vendedor_municipio_options_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_vendas_diarias_por_vendedor_vendedor_options_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/data/resumo_vendas_diarias_suggestion_sql_params.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_filter_options_batch.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_text_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_vendedor_option.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_filter_options_repository.dart';
import 'package:result_dart/result_dart.dart';

class ResumoVendasDiariasPorVendedorFilterOptionsRepositoryImpl
    implements ResumoVendasDiariasPorVendedorFilterOptionsRepository {
  ResumoVendasDiariasPorVendedorFilterOptionsRepositoryImpl(
    this._agentQueriesRepository,
  );

  static const int _defaultBridgeTimeoutMs = 120000;
  static const int _minSqlTimeoutMs = 5000;
  static const int _defaultSqlTimeoutCapMs = 108000;
  static const String _batchOperation =
      'loadResumoVendasDiariasPorVendedorFilterOptionsBatch';
  static const int _batchIndexVendedor = 0;
  static const int _batchIndexBairro = 1;
  static const int _batchIndexMunicipio = 2;

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<List<ResumoVendasDiariasPorVendedorVendedorOption>>>
  loadVendedorOptions({
    required String userId,
    required String agentId,
    required DateTime dataVendaInicio,
    required DateTime dataVendaFim,
    String? searchTerm,
    int limit = ResumoVendasDiariasSuggestionSqlParams.defaultLimit,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) {
    return _execute(
      userId: userId,
      operation: 'loadResumoVendasDiariasPorVendedorVendedorOptions',
      agentId: agentId,
      sql: ResumoVendasDiariasPorVendedorVendedorOptionsSql.query,
      dataVendaInicio: dataVendaInicio,
      dataVendaFim: dataVendaFim,
      searchTerm: searchTerm,
      limit: limit,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      mapRows: (rows) => rows
          .map(
            (row) => ResumoVendasDiariasPorVendedorVendedorOptionModel.fromMap(
              row,
            ).toEntity(),
          )
          .toList(growable: false),
      // The vendedor catalog query reads from Vendedor directly — no date range
      // needed. Override params to send only limit + searchPattern.
      namedParamsOverride: _vendedorSuggestionNamedParams(
        searchTerm: searchTerm,
        limit: limit,
      ),
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
    );
  }

  @override
  Future<AppResult<List<ResumoVendasDiariasPorVendedorTextOption>>>
  loadBairroOptions({
    required String userId,
    required String agentId,
    required DateTime dataVendaInicio,
    required DateTime dataVendaFim,
    String? searchTerm,
    int limit = ResumoVendasDiariasSuggestionSqlParams.defaultLimit,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) {
    return _execute(
      userId: userId,
      operation: 'loadResumoVendasDiariasPorVendedorBairroOptions',
      agentId: agentId,
      sql: ResumoVendasDiariasPorVendedorBairroOptionsSql.query,
      dataVendaInicio: dataVendaInicio,
      dataVendaFim: dataVendaFim,
      searchTerm: searchTerm,
      limit: limit,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      mapRows: (rows) => rows
          .map(
            (row) =>
                ResumoVendasDiariasPorVendedorTextOptionModel.fromBairroMap(
                  row,
                ).toEntity(),
          )
          .toList(growable: false),
      namedParamsOverride: _bairroSuggestionNamedParams(
        searchTerm: searchTerm,
        limit: limit,
      ),
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
    );
  }

  @override
  Future<AppResult<List<ResumoVendasDiariasPorVendedorTextOption>>>
  loadMunicipioOptions({
    required String userId,
    required String agentId,
    required DateTime dataVendaInicio,
    required DateTime dataVendaFim,
    String? searchTerm,
    int limit = ResumoVendasDiariasSuggestionSqlParams.defaultLimit,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) {
    return _execute(
      userId: userId,
      operation: 'loadResumoVendasDiariasPorVendedorMunicipioOptions',
      agentId: agentId,
      sql: ResumoVendasDiariasPorVendedorMunicipioOptionsSql.query,
      dataVendaInicio: dataVendaInicio,
      dataVendaFim: dataVendaFim,
      searchTerm: searchTerm,
      limit: limit,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      mapRows: (rows) => rows
          .map(
            (row) =>
                ResumoVendasDiariasPorVendedorTextOptionModel.fromMunicipioMap(
                  row,
                ).toEntity(),
          )
          .toList(growable: false),
      namedParamsOverride: _municipioSuggestionNamedParams(
        searchTerm: searchTerm,
        limit: limit,
      ),
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
    );
  }

  @override
  Future<AppResult<ResumoVendasDiariasPorVendedorFilterOptionsPerAgentBatch>>
  loadAllFilterOptions({
    required String userId,
    required String agentId,
    required DateTime dataVendaInicio,
    required DateTime dataVendaFim,
    String? searchTerm,
    int limit = ResumoVendasDiariasSuggestionSqlParams.defaultLimit,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) async {
    final rangeError = ResumoVendasDiariasSuggestionSqlParams.validateDateRange(
      dataVendaInicio: dataVendaInicio,
      dataVendaFim: dataVendaFim,
    );
    if (rangeError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<
        ResumoVendasDiariasPorVendedorFilterOptionsPerAgentBatch
      >(
        message: rangeError,
        operation: _batchOperation,
        agentId: agentId.trim(),
      );
    }

    final effectiveLimit = ResumoVendasDiariasSuggestionSqlParams.clampLimit(
      limit,
    );
    final effectiveBridgeMs = bridgeTimeoutMs ?? _defaultBridgeTimeoutMs;
    final effectiveSqlMs = (effectiveBridgeMs * 0.9).round().clamp(
      _minSqlTimeoutMs,
      _defaultSqlTimeoutCapMs,
    );
    const maxRows =
        AgentQueriesBoundedResultMaxRows.vendasDiariasSuggestionOptions;

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
        maxRows: maxRows,
      ),
      commands: <AgentSqlExecuteBatchCommand>[
        AgentSqlExecuteBatchCommand(
          sql: ResumoVendasDiariasPorVendedorVendedorOptionsSql.query,
          namedParams: _vendedorSuggestionNamedParams(
            searchTerm: searchTerm,
            limit: effectiveLimit,
          ),
          executionOrder: _batchIndexVendedor,
        ),
        AgentSqlExecuteBatchCommand(
          sql: ResumoVendasDiariasPorVendedorBairroOptionsSql.query,
          namedParams: _bairroSuggestionNamedParams(
            searchTerm: searchTerm,
            limit: effectiveLimit,
          ),
          executionOrder: _batchIndexBairro,
        ),
        AgentSqlExecuteBatchCommand(
          sql: ResumoVendasDiariasPorVendedorMunicipioOptionsSql.query,
          namedParams: _municipioSuggestionNamedParams(
            searchTerm: searchTerm,
            limit: effectiveLimit,
          ),
          executionOrder: _batchIndexMunicipio,
        ),
      ],
    );

    final batchResult = await _agentQueriesRepository.executeSqlBatch(request);
    return batchResult.fold(
      (execution) => _mapFilterOptionsBatch(
        execution,
        agentId: agentId.trim(),
      ),
      Failure<
            ResumoVendasDiariasPorVendedorFilterOptionsPerAgentBatch,
            AppFailure
          >
          .new,
    );
  }

  AppResult<ResumoVendasDiariasPorVendedorFilterOptionsPerAgentBatch>
  _mapFilterOptionsBatch(
    AgentSqlBatchExecutionResult execution, {
    required String agentId,
  }) {
    final byIndex = <int, AgentSqlBatchExecutionItem>{
      for (final item in execution.items) item.index: item,
    };

    final vendedorMapped =
        AgentSqlBatchItemRowsMapper.mapRowsForIndex<
          ResumoVendasDiariasPorVendedorVendedorOption
        >(
          byIndex,
          _batchIndexVendedor,
          (row) => ResumoVendasDiariasPorVendedorVendedorOptionModel.fromMap(
            row,
          ).toEntity(),
          operation: _batchOperation,
        );
    if (vendedorMapped.failure != null) {
      return Failure<
        ResumoVendasDiariasPorVendedorFilterOptionsPerAgentBatch,
        AppFailure
      >(vendedorMapped.failure!);
    }

    final bairroMapped =
        AgentSqlBatchItemRowsMapper.mapRowsForIndex<
          ResumoVendasDiariasPorVendedorTextOption
        >(
          byIndex,
          _batchIndexBairro,
          (row) => ResumoVendasDiariasPorVendedorTextOptionModel.fromBairroMap(
            row,
          ).toEntity(),
          operation: _batchOperation,
        );
    if (bairroMapped.failure != null) {
      return Failure<
        ResumoVendasDiariasPorVendedorFilterOptionsPerAgentBatch,
        AppFailure
      >(bairroMapped.failure!);
    }

    final municipioMapped =
        AgentSqlBatchItemRowsMapper.mapRowsForIndex<
          ResumoVendasDiariasPorVendedorTextOption
        >(
          byIndex,
          _batchIndexMunicipio,
          (row) =>
              ResumoVendasDiariasPorVendedorTextOptionModel.fromMunicipioMap(
                row,
              ).toEntity(),
          operation: _batchOperation,
        );
    if (municipioMapped.failure != null) {
      return Failure<
        ResumoVendasDiariasPorVendedorFilterOptionsPerAgentBatch,
        AppFailure
      >(municipioMapped.failure!);
    }

    return Success<
      ResumoVendasDiariasPorVendedorFilterOptionsPerAgentBatch,
      AppFailure
    >(
      ResumoVendasDiariasPorVendedorFilterOptionsPerAgentBatch(
        vendedorOptions: vendedorMapped.rows,
        bairroOptions: bairroMapped.rows,
        municipioOptions: municipioMapped.rows,
      ),
    );
  }

  Map<String, Object?> _vendedorSuggestionNamedParams({
    required String? searchTerm,
    required int limit,
  }) {
    final effectiveLimit = ResumoVendasDiariasSuggestionSqlParams.clampLimit(
      limit,
    );
    return <String, Object?>{
      'searchPattern':
          ResumoVendasDiariasSuggestionSqlParams.buildPrefixSearchPattern(
            searchTerm,
          ),
      'limit': effectiveLimit,
    };
  }

  Map<String, Object?> _bairroSuggestionNamedParams({
    required String? searchTerm,
    required int limit,
  }) {
    final effectiveLimit = ResumoVendasDiariasSuggestionSqlParams.clampLimit(
      limit,
    );
    return <String, Object?>{
      'searchPattern':
          ResumoVendasDiariasSuggestionSqlParams.buildPrefixSearchPattern(
            searchTerm,
          ),
      'limit': effectiveLimit,
    };
  }

  Map<String, Object?> _municipioSuggestionNamedParams({
    required String? searchTerm,
    required int limit,
  }) {
    final effectiveLimit = ResumoVendasDiariasSuggestionSqlParams.clampLimit(
      limit,
    );
    return <String, Object?>{
      'searchPattern':
          ResumoVendasDiariasSuggestionSqlParams.buildPrefixSearchPattern(
            searchTerm,
          ),
      'limit': effectiveLimit,
    };
  }

  Future<AppResult<List<T>>> _execute<T>({
    required String userId,
    required String operation,
    required String agentId,
    required String sql,
    required DateTime dataVendaInicio,
    required DateTime dataVendaFim,
    required String? searchTerm,
    required int limit,
    required String? clientToken,
    required int? bridgeTimeoutMs,
    required List<T> Function(List<Map<String, dynamic>> rows) mapRows,
    Map<String, Object?>? namedParamsOverride,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) async {
    final rangeError = ResumoVendasDiariasSuggestionSqlParams.validateDateRange(
      dataVendaInicio: dataVendaInicio,
      dataVendaFim: dataVendaFim,
    );
    if (rangeError != null) {
      return AgentSqlRepositoryExecution.invalidFilters<List<T>>(
        message: rangeError,
        operation: operation,
        agentId: agentId.trim(),
      );
    }

    final effectiveLimit = ResumoVendasDiariasSuggestionSqlParams.clampLimit(
      limit,
    );
    final request = AgentSqlExecuteRequest(
      agentId: agentId,
      requestingUserId: userId,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      sql: sql,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs ?? _defaultBridgeTimeoutMs,
      namedParams:
          namedParamsOverride ??
          <String, Object?>{
            'dataVendaInicio': AgentQueriesSqlLocalDate.format(dataVendaInicio),
            'dataVendaFim': AgentQueriesSqlLocalDate.format(dataVendaFim),
            'searchPattern':
                ResumoVendasDiariasSuggestionSqlParams.buildSearchPattern(
                  searchTerm,
                ),
            'limit': effectiveLimit,
          },
      executeOptions: const AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.preserve,
        maxRows:
            AgentQueriesBoundedResultMaxRows.vendasDiariasSuggestionOptions,
      ),
      useRelay: true,
    );

    return AgentSqlRepositoryExecution.execute<List<T>>(
      agentQueriesRepository: _agentQueriesRepository,
      request: request,
      operation: operation,
      agentId: agentId.trim(),
      unexpectedRowsLogMessage: 'Unexpected row shape for $operation',
      mapExecution: (executionResult) => mapRows(executionResult.rows),
    );
  }
}
