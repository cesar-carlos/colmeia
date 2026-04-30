import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/models/marca_produto_option_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/marca_produto_options_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/marca_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/marca_produto_options_repository.dart';
import 'package:result_dart/result_dart.dart';

class MarcaProdutoOptionsRepositoryImpl
    implements MarcaProdutoOptionsRepository {
  MarcaProdutoOptionsRepositoryImpl(this._agentQueriesRepository);

  static const int _defaultBridgeTimeoutMs = 120000;
  static const String _operation = 'loadMarcaProdutoOptions';

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<List<MarcaProdutoOption>>> loadAll({
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
      sql: MarcaProdutoOptionsSql.query,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs ?? _defaultBridgeTimeoutMs,
      executeOptions: const AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.preserve,
        maxRows: AgentQueriesBoundedResultMaxRows.marcaProdutoOptions,
      ),
      useRelay: true,
    );

    final result = await _agentQueriesRepository.executeSql(request);
    return result.fold(
      (executionResult) {
        try {
          final mapped = executionResult.rows
              .map((row) => MarcaProdutoOptionModel.fromMap(row).toEntity())
              .toList(growable: false);
          return Success<List<MarcaProdutoOption>, AppFailure>(mapped);
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
          return Failure<List<MarcaProdutoOption>, AppFailure>(
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
      Failure<List<MarcaProdutoOption>, AppFailure>.new,
    );
  }
}
