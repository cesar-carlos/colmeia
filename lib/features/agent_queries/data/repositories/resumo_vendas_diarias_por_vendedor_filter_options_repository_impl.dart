import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_vendas_diarias_por_vendedor_text_option_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_vendas_diarias_por_vendedor_vendedor_option_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_vendas_diarias_por_vendedor_bairro_options_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_vendas_diarias_por_vendedor_municipio_options_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_vendas_diarias_por_vendedor_vendedor_options_sql.dart';
import 'package:colmeia/features/agent_queries/data/resumo_vendas_diarias_suggestion_sql_params.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
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
      return Failure<List<T>, AppFailure>(
        ValidationFailure(
          message: rangeError,
          userMessage: 'Os filtros da consulta sao invalidos.',
          context: <String, Object?>{
            'operation': operation,
            'agentId': agentId.trim(),
          },
        ),
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

    final result = await _agentQueriesRepository.executeSql(request);
    return result.fold(
      (executionResult) {
        try {
          final mapped = mapRows(executionResult.rows);
          return Success<List<T>, AppFailure>(mapped);
        } on FormatException catch (error, stackTrace) {
          AppLogger.error(
            'Unexpected row shape for $operation',
            context: <String, Object?>{
              'operation': operation,
              'agentId': agentId.trim(),
            },
            error: error,
            stackTrace: stackTrace,
          );
          return Failure<List<T>, AppFailure>(
            UnknownFailure(
              message: error.message,
              userMessage:
                  'Resposta do agente estava em formato inesperado. '
                  'Tente novamente.',
              cause: error,
              stackTrace: stackTrace,
              context: <String, Object?>{
                'operation': operation,
                'agentId': agentId.trim(),
              },
            ),
          );
        }
      },
      Failure<List<T>, AppFailure>.new,
    );
  }
}
