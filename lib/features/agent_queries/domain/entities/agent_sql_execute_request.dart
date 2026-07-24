import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching_agent_queries_repository.dart'
    show CachingAgentQueriesRepository;
import 'package:colmeia/features/agent_queries/domain/entities/agent_outbound_compression.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart'
    show AgentQueryLoadPolicy;
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_bridge_limits.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_bridge_pagination.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';

/// Default `api_version` advertised by Colmeia.
///
/// Aligned with the current hub profile `plug-jsonrpc-profile/2.10`.
/// Forward-compatible: the bridge silently ignores the field on agents that
/// do not check it. Pass an explicit value for legacy agents.
///
/// Bump to `2.11` / `2.11.2` only after hub contract tests and staging smoke
/// confirm the target profile rejects or accepts the new semantics Colmeia relies
/// on (relay batch, `max_parallel_read_only_batch_items`, profile validation).
const String kColmeiaAgentApiVersion = '2.10';

/// Semantic input for a single `sql.execute` call through the bridge.
///
/// The hub/runtime enforces a UTF-8 JSON byte cap on [namedParams] (see
/// [AgentSqlBridgeLimits.namedParamsJsonMaxUtf8Bytes]); [validationError]
/// rejects oversized maps so failures are local instead of bridge
/// `invalid_params`.
///
/// Overview/resumo queries that need many filter values should keep
/// [namedParams] within the cap and apply extra filters as typed SQL literals
/// (validated integers or escaped strings), not as extra named parameters —
/// see `ResumoParcelasSqlDimensionFilters` and
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
    this.relayMode = AgentSqlRelayMode.unary,
    this.apiVersion = kColmeiaAgentApiVersion,
    this.outboundCompression,
    this.payloadFrameCompression,
    this.skipTransportCache = false,
    this.transportRpcId,
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

  /// Selects how a relay `sql.execute` request crosses the relay channel.
  ///
  /// Ignored unless [useRelay] is `true`. Unary is the default because most
  /// repository queries expect one JSON-RPC response and do not benefit from
  /// chunk backpressure. Use streaming only for queries that should opt into
  /// `relay:rpc.chunk` / `relay:rpc.complete` collection.
  final AgentSqlRelayMode relayMode;

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

  /// When true, [CachingAgentQueriesRepository] does not return a cached SQL
  /// result (used with business-layer [AgentQueryLoadPolicy.forceRefresh]).
  final bool skipTransportCache;

  /// Stable JSON-RPC / relay `clientRequestId` for the logical operation.
  ///
  /// Set by the retrying agent-queries repository decorator so retries reuse
  /// the same wire id and the hub can dedupe post-timeout replays. Callers
  /// should leave this `null`; transport layers generate a fresh id when absent.
  final String? transportRpcId;

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
    if (timeout != null && timeout > AgentSqlBridgeLimits.bridgeTimeoutMsMax) {
      return 'bridgeTimeoutMs must be <= '
          '${AgentSqlBridgeLimits.bridgeTimeoutMsMax}';
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
      if (pagePagination.pageSize > AgentSqlBridgeLimits.pageSizeMax) {
        return 'pagination.pageSize must be <= '
            '${AgentSqlBridgeLimits.pageSizeMax}';
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

    final namedParamsError =
        AgentSqlBridgeLimits.namedParamsUtf8JsonSizeError(namedParams);
    if (namedParamsError != null) {
      return namedParamsError;
    }

    return null;
  }

  AgentSqlExecuteRequest copyWith({
    String? agentId,
    String? sql,
    Map<String, Object?>? namedParams,
    String? clientToken,
    String? requestingUserId,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    int? bridgeTimeoutMs,
    AgentSqlBridgePagination? pagination,
    AgentSqlExecuteOptions? executeOptions,
    bool? useRelay,
    AgentSqlRelayMode? relayMode,
    String? apiVersion,
    AgentOutboundCompression? outboundCompression,
    RelayPayloadFrameCompression? payloadFrameCompression,
    bool? skipTransportCache,
    String? transportRpcId,
  }) {
    return AgentSqlExecuteRequest(
      agentId: agentId ?? this.agentId,
      sql: sql ?? this.sql,
      namedParams: namedParams ?? this.namedParams,
      clientToken: clientToken ?? this.clientToken,
      requestingUserId: requestingUserId ?? this.requestingUserId,
      hubPresenceOnlineAgentIdsSnapshot:
          hubPresenceOnlineAgentIdsSnapshot ??
          this.hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow:
          hubConnectedFromApprovedCatalogRow ??
          this.hubConnectedFromApprovedCatalogRow,
      bridgeTimeoutMs: bridgeTimeoutMs ?? this.bridgeTimeoutMs,
      pagination: pagination ?? this.pagination,
      executeOptions: executeOptions ?? this.executeOptions,
      useRelay: useRelay ?? this.useRelay,
      relayMode: relayMode ?? this.relayMode,
      apiVersion: apiVersion ?? this.apiVersion,
      outboundCompression: outboundCompression ?? this.outboundCompression,
      payloadFrameCompression:
          payloadFrameCompression ?? this.payloadFrameCompression,
      skipTransportCache: skipTransportCache ?? this.skipTransportCache,
      transportRpcId: transportRpcId ?? this.transportRpcId,
    );
  }
}

enum AgentSqlRelayMode {
  unary,
  streaming,
}
