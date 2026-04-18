import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_bridge_pagination.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';

/// Semantic input for a single `sql.execute` call through the bridge.
///
/// The hub/runtime enforces a small cap on **distinct** named parameters per
/// execute (see [bridgeMaxNamedParameterCount]); [validationError] rejects
/// larger maps so failures are local instead of bridge `invalid_params`.
///
/// Overview/resumo queries that need more bound values than this cap allow
/// should keep [namedParams] within the cap and apply extra filters as typed
/// SQL literals (validated integers or escaped strings), not as extra named
/// parameters — see `ResumoParcelasSqlDimensionFilters` and
/// `ResumoVendasDiariasPorVendedorSql` for the established pattern.
class AgentSqlExecuteRequest {
  const AgentSqlExecuteRequest({
    required this.agentId,
    required this.sql,
    this.namedParams = const <String, Object?>{},
    this.clientToken,
    this.requestingUserId,
    this.hubPresenceOnlineAgentIdsSnapshot,
    this.hubConnectedFromApprovedCatalogRow,
    this.bridgeTimeoutMs,
    this.pagination,
    this.executeOptions,
    this.useRelay = false,
  });

  final String agentId;
  final String sql;
  final Map<String, Object?> namedParams;
  final String? clientToken;

  /// When non-null and non-empty, the gated `AgentQueriesRepository` may
  /// enforce hub presence before `sql.execute`.
  final String? requestingUserId;

  /// When non-null, SQL eligibility uses this set instead of calling
  /// `ClientAgentsRepository.loadOnlineAgentIds` again (same wave as target
  /// resolution). `null` means load presence from the repository (optionally
  /// via a short TTL cache in the default checker). An empty set still means a
  /// real snapshot with no online agents.
  final Set<String>? hubPresenceOnlineAgentIdsSnapshot;

  /// Reserved for eligibility: explicit hub flag from the fast approved-agent
  /// catalog row (`loadApprovedAgents` with `includeOnlineStatus: false`).
  /// When null, eligibility falls back to snapshot / cache only.
  final bool? hubConnectedFromApprovedCatalogRow;

  /// HTTP bridge wait timeout (`timeoutMs` in the request body).
  final int? bridgeTimeoutMs;

  /// HTTP body pagination injected by the hub into `params.options`.
  final AgentSqlBridgePagination? pagination;

  /// Agent-side execution flags under `params.options`.
  final AgentSqlExecuteOptions? executeOptions;

  /// Routing hint for the data layer (PR-L+): when `true`, the
  /// `HybridAgentQueriesRemoteDataSource` dispatches this request through the
  /// **relay channel** (`relay:rpc.request` over a `RelayConversation`)
  /// instead of the unitary `agents:command` event. Used for queries that
  /// either return very large result sets or that benefit from the `relay`
  /// rate-limit pool (separate from the shared `agents:command`/REST quota).
  ///
  /// This flag never reaches the bridge body — it is consumed by the
  /// datasource selector and stripped before serialization. Defaults to
  /// `false` so existing call sites remain on the legacy channel.
  ///
  /// Effective only when `SOCKET_RELAY_ENABLED=true` and
  /// `AGENT_BRIDGE_TRANSPORT=socket`. With other configurations the hybrid
  /// datasource falls back to its base channel and logs the bypass for
  /// observability.
  final bool useRelay;

  String get trimmedAgentId => agentId.trim();
  String get trimmedSql => sql.trim();
  String? get trimmedClientToken => clientToken?.trim();
  String? get trimmedRequestingUserId => requestingUserId?.trim();

  String? validationError() {
    if (trimmedAgentId.isEmpty) {
      return 'agentId must not be empty';
    }
    if (trimmedSql.isEmpty) {
      return 'sql must not be empty';
    }

    final timeout = bridgeTimeoutMs;
    if (timeout != null && timeout < 1) {
      return 'bridgeTimeoutMs must be >= 1';
    }

    final token = trimmedClientToken;
    if (clientToken != null && (token == null || token.isEmpty)) {
      return 'clientToken must be null or non-empty';
    }

    final rid = trimmedRequestingUserId;
    if (requestingUserId != null && (rid == null || rid.isEmpty)) {
      return 'requestingUserId must be null or non-empty when provided';
    }

    final pagePagination = pagination;
    if (pagePagination is AgentSqlPagePagination) {
      if (pagePagination.page < 1) {
        return 'pagination.page must be >= 1';
      }
      if (pagePagination.pageSize < 1) {
        return 'pagination.pageSize must be >= 1';
      }
    }
    if (pagePagination is AgentSqlCursorPagination) {
      if (pagePagination.cursor.trim().isEmpty) {
        return 'pagination.cursor must be non-empty';
      }
    }

    final optionsError = executeOptions?.validationError();
    if (optionsError != null) {
      return optionsError;
    }
    if (pagination != null &&
        executeOptions?.executionMode == AgentSqlExecutionMode.preserve) {
      return 'pagination cannot be combined with executionMode.preserve';
    }

    if (namedParams.length > bridgeMaxNamedParameterCount) {
      return 'namedParams must contain at most $bridgeMaxNamedParameterCount '
          'entries (Agent SQL bridge limit)';
    }

    return null;
  }

  /// Current Agent SQL bridge limit for `namedParams` size.
  static const int bridgeMaxNamedParameterCount = 5;
}
