/// Compile-time (`--dart-define`) and dotenv key names used by
/// `AppEnvironment`.
abstract final class EnvKeys {
  static const String apiBaseUrl = 'API_BASE_URL';
  static const String useFakeBackend = 'USE_FAKE_BACKEND';
  static const String sentryDsn = 'SENTRY_DSN';
  static const String sentryDebug = 'SENTRY_DEBUG';
  static const String sentryTracesSampleRate = 'SENTRY_TRACES_SAMPLE_RATE';

  /// Agent UUID for integration / e2e tests that call the real SQL bridge.
  static const String e2eAgentId = 'E2E_AGENT_ID';

  /// Per-agent bridge token (JSON-RPC `client_token`), not the API JWT.
  static const String e2eClientToken = 'E2E_CLIENT_TOKEN';

  /// Client-auth email for e2e (`POST /client-auth/login`).
  static const String e2eClientEmail = 'E2E_CLIENT_EMAIL';

  /// Client-auth password for e2e (use only test accounts; prefer dart-define).
  static const String e2eClientPassword = 'E2E_CLIENT_PASSWORD';

  // ----- Socket channel (PR-A: infraestrutura de conexão) -----

  /// `rest` (default) | `socket`. Selects the agent commands transport.
  /// See `docs/Features/socket_consumer_channel_plan.md` §7.
  static const String agentBridgeTransport = 'AGENT_BRIDGE_TRANSPORT';

  /// Override for the socket namespace (default `/consumers`). Only set in
  /// tests against forked hubs.
  static const String socketNamespace = 'SOCKET_NAMESPACE';

  /// Max reconnect attempts for the consumer socket controlled-backoff loop.
  static const String socketReconnectAttempts = 'SOCKET_RECONNECT_ATTEMPTS';

  /// Initial backoff delay (ms) for reconnect attempts (full-jitter applied).
  static const String socketReconnectInitialDelayMs =
      'SOCKET_RECONNECT_INITIAL_DELAY_MS';

  /// Max backoff delay ceiling (ms) for reconnect attempts.
  static const String socketReconnectMaxDelayMs =
      'SOCKET_RECONNECT_MAX_DELAY_MS';

  /// Default per-request timeout (ms) when the caller does not specify one.
  static const String socketRequestTimeoutMs = 'SOCKET_REQUEST_TIMEOUT_MS';

  /// Wait time (ms) for `connection:ready` before retry.
  static const String socketHandshakeTimeoutMs = 'SOCKET_HANDSHAKE_TIMEOUT_MS';

  /// When true and `AGENT_BRIDGE_TRANSPORT=socket`, the app fires
  /// `ConsumerSocketConnection.connect()` after a successful login so the
  /// first SQL query does not pay the handshake cost. Defaults to true on
  /// socket builds; ignored on REST.
  static const String socketWarmUpAfterLogin = 'SOCKET_WARM_UP_AFTER_LOGIN';

  /// Per-agent in-flight `agents:command` ceiling enforced by
  /// `PerAgentConcurrencyGate`. Conservative mirror of the hub's
  /// `SOCKET_REST_AGENT_MAX_INFLIGHT` (default 32 server-side; we use 8
  /// client-side). Set 0 to disable the gate (dispatcher fires without
  /// waiting).
  static const String socketMaxInflightPerAgent =
      'SOCKET_MAX_INFLIGHT_PER_AGENT';

  /// Kill switch for in-flight request coalescing inside the dispatcher.
  /// When `true` (default), two concurrent `sendAgentsCommand` calls with
  /// the same canonical body share the same `Future` and produce a single
  /// emit on the wire. Set `false` to force-fire every call.
  static const String socketCoalescingEnabled = 'SOCKET_COALESCING_ENABLED';

  /// Enables `AgentLatencyOracle`-driven adaptive timeouts. When `true`,
  /// the dispatcher consults the oracle for a per `(agentId, method)`
  /// recommended timeout when the caller did not pass one explicitly.
  /// Default `false`: opt-in until baseline metrics confirm the upside
  /// (review §5.3, P2).
  static const String socketTimeoutAdaptiveEnabled =
      'SOCKET_TIMEOUT_ADAPTIVE_ENABLED';

  /// Master switch for `AgentCommandBatchCoordinator`. When `true`, the
  /// agent-queries datasource is wired through the batching coordinator
  /// (review §5.2 / PR-I). Default `false` (opt-in).
  static const String socketBatchEnabled = 'SOCKET_BATCH_ENABLED';

  /// Coalescing window (ms) used by the batch coordinator: requests
  /// arriving within this window for the same agent are flushed in one
  /// `agents:command` emit. Default 8 ms.
  static const String socketBatchWindowMs = 'SOCKET_BATCH_WINDOW_MS';

  /// Maximum RPCs per batch. Hard-capped server-side at 32; values above
  /// that are clamped down. Default 32.
  static const String socketBatchMaxSize = 'SOCKET_BATCH_MAX_SIZE';

  /// Minimum RPCs needed to actually emit a batch. With `1` the coordinator
  /// always emits as `command: [x]` (simpler, default); with `2`+, single
  /// pending requests fall back to a unitary `agents:command` payload.
  static const String socketBatchMinSize = 'SOCKET_BATCH_MIN_SIZE';

  // ----- Socket channel (PR-L: relay) -----

  /// Master switch for the relay datasource. When `true`, the agent-queries
  /// DI registers the relay-aware datasource alongside the unitary
  /// `agents:command` sender. Default `false` (opt-in until baseline
  /// metrics validate the upside for large queries).
  static const String socketRelayEnabled = 'SOCKET_RELAY_ENABLED';

  /// Per-request relay timeout (ms). Default 30000 — must be larger than the
  /// JSON-RPC bridge timeout so the hub can answer through `relay:rpc.complete`
  /// before the client gives up.
  static const String socketRelayRequestTimeoutMs =
      'SOCKET_RELAY_REQUEST_TIMEOUT_MS';

  /// Time (ms) the dispatcher waits for `relay:conversation.started`. The
  /// hub typically answers in one round-trip; default 10000 for safety.
  static const String socketRelayConversationStartTimeoutMs =
      'SOCKET_RELAY_CONVERSATION_START_TIMEOUT_MS';

  /// Time (ms) the dispatcher waits for `relay:conversation.ended` after
  /// emitting `relay:conversation.end`. Default 5000; hitting the timeout
  /// is logged but does not fail the close.
  static const String socketRelayConversationEndTimeoutMs =
      'SOCKET_RELAY_CONVERSATION_END_TIMEOUT_MS';

  /// `payloadFrameCompression` strategy forwarded to the hub on every
  /// `relay:rpc.request` envelope. Accepted values: `default`, `none`,
  /// `always`. Default `default` (auto: gzip when JSON shrinks).
  static const String socketRelayPayloadFrameCompression =
      'SOCKET_RELAY_PAYLOAD_FRAME_COMPRESSION';

  /// Initial chunk window size granted via `relay:rpc.stream.pull` when the
  /// hub accepts a streaming request (PR-L+ part 2). Higher values reduce
  /// the number of pull round-trips at the cost of more RAM in flight on
  /// the consumer side. Default 32 — matches the example in
  /// `socket_client_sdk.md`.
  static const String socketRelayStreamInitialWindow =
      'SOCKET_RELAY_STREAM_INITIAL_WINDOW';

  /// Threshold at which the dispatcher refills the streaming window back
  /// to `SOCKET_RELAY_STREAM_INITIAL_WINDOW`. Lower values mean fewer
  /// pulls (and more risk of starving the hub buffer); higher values mean
  /// more frequent pulls. Default 16 (half of the initial window).
  static const String socketRelayStreamRefillThreshold =
      'SOCKET_RELAY_STREAM_REFILL_THRESHOLD';

  // ----- Socket presence (PR-M: client:agent.profile.updated) -----

  /// Master switch for the realtime presence stack. When `true` the DI
  /// registers `SocketAgentPresenceStream` (Camadas 1+2 do plano §19) and
  /// the `ObserveAgentPresenceUseCase`. Default `false` (opt-in until the
  /// `ClientAgentsController` integration ships).
  static const String socketPresenceListenerEnabled =
      'SOCKET_PRESENCE_LISTENER_ENABLED';

  // ----- Socket channel (PR-K: PayloadFrame + connection:ready) -----

  /// Selects how the consumer socket interprets `connection:ready`:
  ///
  /// - `compat` (default): try PayloadFrame first, fall back to legacy raw
  ///   JSON. Required during the migration window declared by the hub
  ///   (`raw_json` removal planned for after `2026-09-30`).
  /// - `payload_frame_only`: strict — fail when the envelope is not a
  ///   PayloadFrame.
  /// - `raw_json_only`: legacy strict mode used by the older PR-A decoder
  ///   and by tests against forked hubs.
  static const String socketConnectionReadyCompatMode =
      'SOCKET_CONNECTION_READY_COMPAT_MODE';
}

/// Asset paths for bundled env files (`loadAppDotenv`).
abstract final class EnvAssetPaths {
  static const String bundledDefault = 'assets/env/default.env';
  static const String bundledLocal = 'assets/env/local.env';
}
