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
  static const String _operation = 'loadGrupoProdutoOptions';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<List<GrupoProdutoOption>>> loadAll({
    required String userId,
    required String agentId,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) async {
    final request = AgentSqlExecuteRequest(
      agentId: agentId,
      requestingUserId: userId,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      sql: GrupoProdutoOptionsSql.query,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs ?? _defaultBridgeTimeoutMs,
      executeOptions: const AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.preserve,
        maxRows: AgentQueriesBoundedResultMaxRows.grupoProdutoOptions,
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
}
