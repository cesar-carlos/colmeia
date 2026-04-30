import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/models/grupo_produto_option_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/grupo_produto_options_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/grupo_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/grupo_produto_options_repository.dart';
import 'package:result_dart/result_dart.dart';

class GrupoProdutoOptionsRepositoryImpl
    implements GrupoProdutoOptionsRepository {
  GrupoProdutoOptionsRepositoryImpl(this._agentQueriesRepository);

  static const int _defaultBridgeTimeoutMs = 120000;
  static const int _defaultPageSize = 20;
  static const int _maxPageSize = 500;
  static const int _maxRowsPageBuffer = 25;
  static const String _operation = 'loadGrupoProdutoOptions';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<List<GrupoProdutoOption>>> loadAll({
    required String userId,
    required String agentId,
    int page = 1,
    int pageSize = _defaultPageSize,
    String? searchTerm,
    @Deprecated('Use searchTerm instead.') String? nomeGrupoProduto,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) async {
    if (page < 1) {
      return Failure<List<GrupoProdutoOption>, AppFailure>(
        ValidationFailure(
          message: 'page must be >= 1',
          userMessage: 'Os filtros da consulta sao invalidos.',
          context: <String, Object?>{
            'operation': _operation,
            'agentId': agentId.trim(),
          },
        ),
      );
    }
    if (pageSize < 1) {
      return Failure<List<GrupoProdutoOption>, AppFailure>(
        ValidationFailure(
          message: 'pageSize must be >= 1',
          userMessage: 'Os filtros da consulta sao invalidos.',
          context: <String, Object?>{
            'operation': _operation,
            'agentId': agentId.trim(),
          },
        ),
      );
    }
    if (pageSize > _maxPageSize) {
      return Failure<List<GrupoProdutoOption>, AppFailure>(
        ValidationFailure(
          message: 'pageSize must be <= $_maxPageSize',
          userMessage: 'Os filtros da consulta sao invalidos.',
          context: <String, Object?>{
            'operation': _operation,
            'agentId': agentId.trim(),
          },
        ),
      );
    }

    final startRow = ((page - 1) * pageSize) + 1;
    final endRow = startRow + pageSize - 1;
    final resolvedSearchTerm = _resolveSearchTerm(
      searchTerm: searchTerm,
      fallback: nomeGrupoProduto,
    );
    final nomeGrupoProdutoLike = _containsLikeParam(resolvedSearchTerm);
    final sqlMaxRowsCap = (pageSize + _maxRowsPageBuffer).clamp(
      _maxRowsPageBuffer + 1,
      AgentQueriesBoundedResultMaxRows.grupoProdutoOptions,
    );

    final request = AgentSqlExecuteRequest(
      agentId: agentId,
      requestingUserId: userId,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      sql: GrupoProdutoOptionsSql.pagedQuery,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs ?? _defaultBridgeTimeoutMs,
      namedParams: <String, Object?>{
        'startRow': startRow,
        'endRow': endRow,
        'nomeGrupoProduto': nomeGrupoProdutoLike,
      },
      executeOptions: AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.preserve,
        maxRows: sqlMaxRowsCap,
      ),
      useRelay: true,
    );

    final result = await _agentQueriesRepository.executeSql(request);
    return result.fold(
      (executionResult) {
        try {
          final mapped = executionResult.rows
              .map((row) => GrupoProdutoOptionModel.fromMap(row).toEntity())
              .toList(growable: false);
          return Success<List<GrupoProdutoOption>, AppFailure>(mapped);
        } on FormatException catch (error, stackTrace) {
          AppLogger.error(
            'Unexpected row shape for $_operation',
            context: <String, Object?>{
              'operation': _operation,
              'agentId': agentId.trim(),
            },
            error: error,
            stackTrace: stackTrace,
          );
          return Failure<List<GrupoProdutoOption>, AppFailure>(
            UnknownFailure(
              message: error.message,
              userMessage:
                  'Resposta do agente estava em formato inesperado. '
                  'Tente novamente.',
              cause: error,
              stackTrace: stackTrace,
              context: <String, Object?>{
                'operation': _operation,
                'agentId': agentId.trim(),
              },
            ),
          );
        }
      },
      Failure<List<GrupoProdutoOption>, AppFailure>.new,
    );
  }

  static String? _containsLikeParam(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return '%$normalized%';
  }

  static String? _resolveSearchTerm({
    String? searchTerm,
    String? fallback,
  }) {
    // `searchTerm` is the canonical autocomplete input. Keep fallback support
    // while legacy callers still pass `nomeGrupoProduto`.
    final normalized = searchTerm?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
    return fallback;
  }
}
