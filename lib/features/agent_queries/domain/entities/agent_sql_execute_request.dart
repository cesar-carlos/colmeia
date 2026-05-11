import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_outbound_compression.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_bridge_pagination.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';

/// Default `api_version` advertised by Colmeia. Aligned with the hub
/// `plug-jsonrpc-profile/2.8` profile (REST examples in
/// `plug_server/docs/api_rest_bridge.md` use 2.5+; the hub accepts any
/// value the underlying agent supports). Forward-compatible: the bridge
/// silently ignores the field on agents that do not check it.
const String kColmeiaAgentApiVersion = '2.5';

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
    this.apiVersion = kColmeiaAgentApiVersion,
    this.outboundCompression,
    this.payloadFrameCompression,
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
  /// Effective when the relay stack is registered. Socket transport
  /// (`AGENT_BRIDGE_TRANSPORT=socket`) implies relay availability; non-socket
  /// builds can also opt in with `SOCKET_RELAY_ENABLED=true`. With other
  /// configurations the hybrid datasource falls back to its base channel and
  /// logs the bypass for observability.
  ///
  /// With `AGENT_BRIDGE_TRANSPORT=socket`, prefer `true` for dashboard-style
  /// SQL that may stream large row sets: the legacy `agents:command` path does
  /// not implement `agents:stream_pull` / chunk events — relay matches the hub
  /// contract (`plug_server/docs/api_rest_bridge.md`).
  final bool useRelay;

  /// JSON-RPC `command.api_version`. Defaults to [kColmeiaAgentApiVersion]
  /// so every outgoing request advertises the profile we are coding
  /// against. Pass an explicit value when the call is targeting a tool
  /// known to require an older / newer version.
  final String apiVersion;

  /// Hint serialized as `meta.outbound_compression` — tells the agent
  /// which `PayloadFrame.cmp` policy to apply on the response stream.
  /// `null` means "do not send a hint" (agent decides locally). Today the
  /// hub treats this as a no-op on the runtime; we still send it so we
  /// are forward-compatible with future agent profiles.
  final AgentOutboundCompression? outboundCompression;

  /// Body-level `payloadFrameCompression` (`default` | `none` | `always`).
  /// Drives the gzip policy of the **hub → agent** frame the server
  /// re-encodes after decoding our request. `null` keeps the channel
  /// default (`auto`).
  final RelayPayloadFrameCompression? payloadFrameCompression;

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
