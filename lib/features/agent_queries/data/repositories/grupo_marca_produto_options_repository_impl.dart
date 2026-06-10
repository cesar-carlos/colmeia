import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_batch_item_rows_mapper.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_read_only_batch_options.dart';
import 'package:colmeia/features/agent_queries/data/models/grupo_produto_option_model.dart';
import 'package:colmeia/features/agent_queries/data/models/marca_produto_option_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/grupo_produto_options_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/marca_produto_options_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/grupo_marca_produto_options_batch.dart';
import 'package:colmeia/features/agent_queries/domain/entities/grupo_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/marca_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/grupo_marca_produto_options_repository.dart';
import 'package:result_dart/result_dart.dart';

class GrupoMarcaProdutoOptionsRepositoryImpl
    implements GrupoMarcaProdutoOptionsRepository {
  GrupoMarcaProdutoOptionsRepositoryImpl(this._agentQueriesRepository);

  static const int _defaultPageSize = 20;
  static const int _maxPageSize = 500;
  static const int _maxRowsPageBuffer = 25;
  static const int _minSqlTimeoutMs = 5000;
  static const String _batchOperation = 'loadGrupoMarcaProdutoOptionsBatch';
  static const int _batchIndexGrupo = 0;
  static const int _batchIndexMarca = 1;

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<GrupoMarcaProdutoOptionsBatch>> loadGrupoAndMarcaOptions({
    required String userId,
    required String agentId,
    int page = 1,
    int pageSize = _defaultPageSize,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    if (page < 1) {
      return AgentSqlRepositoryExecution.invalidFilters<
        GrupoMarcaProdutoOptionsBatch
      >(
        message: 'page must be >= 1',
        operation: _batchOperation,
        agentId: agentId.trim(),
      );
    }
    if (pageSize < 1) {
      return AgentSqlRepositoryExecution.invalidFilters<
        GrupoMarcaProdutoOptionsBatch
      >(
        message: 'pageSize must be >= 1',
        operation: _batchOperation,
        agentId: agentId.trim(),
      );
    }
    if (pageSize > _maxPageSize) {
      return AgentSqlRepositoryExecution.invalidFilters<
        GrupoMarcaProdutoOptionsBatch
      >(
        message: 'pageSize must be <= $_maxPageSize',
        operation: _batchOperation,
        agentId: agentId.trim(),
      );
    }

    final startRow = ((page - 1) * pageSize) + 1;
    final endRow = startRow + pageSize - 1;
    final sqlMaxRowsCap = (pageSize + _maxRowsPageBuffer).clamp(
      _maxRowsPageBuffer + 1,
      AgentQueriesBoundedResultMaxRows.grupoProdutoOptions,
    );
    final effectiveBridgeMs =
        bridgeTimeoutMs ?? AppEnvironment.agentSqlBridgeTimeoutMs;
    final effectiveSqlMs = (effectiveBridgeMs * 0.9).round().clamp(
      _minSqlTimeoutMs,
      effectiveBridgeMs,
    );

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
        maxRows: sqlMaxRowsCap,
      ),
      commands: <AgentSqlExecuteBatchCommand>[
        AgentSqlExecuteBatchCommand(
          sql: GrupoProdutoOptionsSql.pagedQuery,
          namedParams: <String, Object?>{
            'startRow': startRow,
            'endRow': endRow,
            'nomeGrupoProduto': null,
          },
          executionOrder: _batchIndexGrupo,
        ),
        AgentSqlExecuteBatchCommand(
          sql: MarcaProdutoOptionsSql.pagedQuery,
          namedParams: <String, Object?>{
            'startRow': startRow,
            'endRow': endRow,
            'nomeMarca': null,
          },
          executionOrder: _batchIndexMarca,
        ),
      ],
    );

    final batchResult = await _agentQueriesRepository.executeSqlBatch(
      request,
      cancelScope: cancelScope,
    );
    return batchResult.fold(
      _mapBatch,
      Failure<GrupoMarcaProdutoOptionsBatch, AppFailure>.new,
    );
  }

  AppResult<GrupoMarcaProdutoOptionsBatch> _mapBatch(
    AgentSqlBatchExecutionResult execution,
  ) {
    final byIndex = <int, AgentSqlBatchExecutionItem>{
      for (final item in execution.items) item.index: item,
    };

    final grupoMapped =
        AgentSqlBatchItemRowsMapper.mapRowsForIndex<GrupoProdutoOption>(
          byIndex,
          _batchIndexGrupo,
          (row) => GrupoProdutoOptionModel.fromMap(row).toEntity(),
          operation: _batchOperation,
        );
    if (grupoMapped.failure != null) {
      return Failure<GrupoMarcaProdutoOptionsBatch, AppFailure>(
        grupoMapped.failure!,
      );
    }

    final marcaMapped =
        AgentSqlBatchItemRowsMapper.mapRowsForIndex<MarcaProdutoOption>(
          byIndex,
          _batchIndexMarca,
          (row) => MarcaProdutoOptionModel.fromMap(row).toEntity(),
          operation: _batchOperation,
        );
    if (marcaMapped.failure != null) {
      return Failure<GrupoMarcaProdutoOptionsBatch, AppFailure>(
        marcaMapped.failure!,
      );
    }

    return Success<GrupoMarcaProdutoOptionsBatch, AppFailure>(
      GrupoMarcaProdutoOptionsBatch(
        grupoOptions: grupoMapped.rows,
        marcaOptions: marcaMapped.rows,
      ),
    );
  }
}
