/// Compile-time (`--dart-define`) and dotenv key names used by
/// `AppEnvironment`.
abstract final class EnvKeys {
  static const String apiBaseUrl = 'API_BASE_URL';
  static const String useFakeBackend = 'USE_FAKE_BACKEND';
  static const String sentryDsn = 'SENTRY_DSN';
  static const String sentryDebug = 'SENTRY_DEBUG';
  static const String sentryTracesSampleRate = 'SENTRY_TRACES_SAMPLE_RATE';
  static const String autoUpdateFeedUrl = 'AUTO_UPDATE_FEED_URL';

  /// Agent UUID for integration / e2e tests that call the real SQL bridge.
  static const String e2eAgentId = 'E2E_AGENT_ID';

  /// Per-agent bridge token (JSON-RPC `client_token`), not the API JWT.
  static const String e2eClientToken = 'E2E_CLIENT_TOKEN';

  /// Client-auth email for e2e (`POST /client-auth/login`).
  static const String e2eClientEmail = 'E2E_CLIENT_EMAIL';

  /// Client-auth password for e2e (use only test accounts; prefer dart-define).
  static const String e2eClientPassword = 'E2E_CLIENT_PASSWORD';

  /// When true, VM E2E skips registering relay dispatchers on top of the
  /// consumer socket so `HybridAgentQueriesRemoteDataSource` bypasses relay
  /// for every `useRelay: true` request (base `agents:command` / REST only).
  static const String e2eDisableRelayDispatch = 'E2E_DISABLE_RELAY_DISPATCH';

  /// Maximum in-memory successful SQL query results kept before LRU eviction.
  static const String agentSqlCacheMaxSize = 'AGENT_SQL_CACHE_MAX_SIZE';

  /// TTL in milliseconds for the short in-memory SQL result cache.
  static const String agentSqlCacheTtlMs = 'AGENT_SQL_CACHE_TTL_MS';

  /// Optional bridge hint for overview read-only `sql.executeBatch`
  /// parallelism. Positive integer; the agent keeps the final safety cap.
  static const String agentSqlOverviewBatchMaxParallelReadOnlyItems =
      'AGENT_SQL_OVERVIEW_BATCH_MAX_PARALLEL_READ_ONLY_ITEMS';

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

  /// Optional cap on how many `PerAgentConcurrencyGate.acquire` calls may
  /// wait in the per-agent queue when in-flight work is at ceiling. `0`
  /// (default) means unlimited waiters (legacy behaviour). Set a positive
  /// value to bound memory under burst load.
  static const String socketMaxInflightWaitersPerAgent =
      'SOCKET_MAX_INFLIGHT_WAITERS_PER_AGENT';

  /// Max time (ms) a caller may wait in the per-agent gate queue for a
  /// slot. `0` (default) means no limit (legacy behaviour).
  static const String socketMaxInflightAcquireWaitMs =
      'SOCKET_MAX_INFLIGHT_ACQUIRE_WAIT_MS';

  /// Max rows buffered by `BridgeShapedSqlExecuteCollector` when
  /// materialising relay streaming into a unary map. `0` = unlimited
  /// (default). Set a positive cap to avoid OOM on huge result sets.
  static const String socketStreamSqlCollectorMaxBufferedRows =
      'SOCKET_STREAM_SQL_COLLECTOR_MAX_BUFFERED_ROWS';

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

  /// Optional relay datasource switch. `AGENT_BRIDGE_TRANSPORT=socket` also
  /// enables relay automatically so socket builds get the complete bridge
  /// stack with one parameter.
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

  /// Optional realtime presence switch. Socket bridge transport also enables
  /// it automatically so catalog hints follow the selected realtime channel.
  static const String socketPresenceListenerEnabled =
      'SOCKET_PRESENCE_LISTENER_ENABLED';

  /// Migration-only override for older hubs that still emit
  /// `client:agent.profile.updated` as a raw JSON map instead of PayloadFrame.
  /// Default `false`.
  static const String socketProfileUpdatedLegacyRawJsonEnabled =
      'SOCKET_PROFILE_UPDATED_LEGACY_RAW_JSON_ENABLED';

  // ----- Socket channel (PR-K: PayloadFrame + connection:ready) -----

  /// Selects how the consumer socket interprets `connection:ready`:
  ///
  /// - `payload_frame_only` (default): strict - fail when the envelope is not
  ///   a PayloadFrame.
  /// - `compat`: try PayloadFrame first, fall back to legacy raw JSON. Use
  ///   only as a migration override for older hubs.
  /// - `raw_json_only`: legacy strict mode used by the older PR-A decoder
  ///   and by tests against forked hubs.
  static const String socketConnectionReadyCompatMode =
      'SOCKET_CONNECTION_READY_COMPAT_MODE';

  /// Shared HMAC-SHA256 key used to sign outbound `PayloadFrame`
  /// envelopes. Must match `PAYLOAD_SIGNING_KEY` configured on the hub.
  /// Empty (default) → frames are emitted unsigned, which the hub
  /// also accepts when itself unconfigured.
  static const String socketPayloadSigningKey = 'SOCKET_PAYLOAD_SIGNING_KEY';

  /// Optional `signature.key_id` propagated alongside outbound HMACs.
  /// Required by the hub when `PAYLOAD_SIGNING_KEY_ID` is configured
  /// upstream — frames missing the id (or with a divergent one) are
  /// rejected with `-32001` `invalid_signature`.
  static const String socketPayloadSigningKeyId =
      'SOCKET_PAYLOAD_SIGNING_KEY_ID';

  /// When `true` and a signing key is configured, inbound frames
  /// MUST carry a valid `signature` — unsigned frames are rejected
  /// with `signature_required`. Defence in depth against MITM on
  /// transport layers below TLS. Default `false` (current hub
  /// emits signed frames only when `PAYLOAD_SIGN_OUTBOUND=true`).
  static const String socketPayloadRequireSignature =
      'SOCKET_PAYLOAD_REQUIRE_SIGNATURE';

  /// When `false`, `PayloadFrameCodec` never uses worker isolates for gzip
  /// encode/decode or large `jsonDecode` (everything stays on the UI
  /// isolate). Default `true`.
  static const String socketPayloadWorkerIsolatesEnabled =
      'SOCKET_PAYLOAD_WORKER_ISOLATES_ENABLED';

  /// Minimum compressed gzip size (bytes) before inbound gzip inflation may
  /// run on a worker isolate. Default matches
  /// `PayloadFrameCodec.defaultGzipDecodeIsolateThresholdBytes` (16 KiB).
  static const String socketPayloadGzipDecodeIsolateThresholdBytes =
      'SOCKET_PAYLOAD_GZIP_DECODE_ISOLATE_THRESHOLD_BYTES';

  /// Minimum raw JSON UTF-8 size (bytes) before outbound `gzip.encode` may
  /// run on a worker isolate. Default 65536.
  static const String socketPayloadGzipEncodeIsolateThresholdBytes =
      'SOCKET_PAYLOAD_GZIP_ENCODE_ISOLATE_THRESHOLD_BYTES';

  /// Minimum materialised JSON UTF-8 size (bytes) before `jsonDecode` may
  /// run on a worker isolate. Default 262144 (256 KiB).
  static const String socketPayloadJsonDecodeIsolateThresholdBytes =
      'SOCKET_PAYLOAD_JSON_DECODE_ISOLATE_THRESHOLD_BYTES';
}

/// Asset paths for bundled env files (`loadAppDotenv`).
abstract final class EnvAssetPaths {
  static const String bundledDefault = 'assets/env/default.env';
  static const String bundledLocal = 'assets/env/local.env';
}
