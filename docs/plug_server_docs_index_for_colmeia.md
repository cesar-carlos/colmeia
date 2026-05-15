# plug_server docs index for Colmeia

This file is a short routing map for Colmeia work. The normative contract stays
in the sibling `plug_server` repository under `docs/` and shared source
constants.

## Primary references

| plug_server document | Use in Colmeia |
| --- | --- |
| `docs/api_rest_bridge.md` | REST bridge shape, `agents:command`, `sql.execute`, `sql.executeBatch`, pagination, timeouts, JSON-RPC ids, and REST materialization behavior. |
| `docs/socket_client_sdk.md` | Consumer Socket.IO guide for `/consumers`, handshake, event names, frame compression, rate-limit hints, and examples. |
| `docs/socket_relay_protocol.md` | Relay protocol: conversations, `relay:rpc.request`, `relay:rpc.stream.pull`, PayloadFrame envelope, validation, and streaming semantics. |
| `docs/client_agent_business_rules.md` | Client/agent access authorization, `client_token`, revocation behavior, and per-event authorization. |
| `docs/configuration.md` | Socket/relay env vars, rate limits, inflight gates, and payload frame defaults. |
| `docs/observability.md` | Metrics and logs for bridge latency, socket rooms, relay queues, and troubleshooting. |
| `docs/nginx_production.md` | Reverse proxy and WebSocket deployment settings. |

## Socket contract used by Colmeia

- Consumer clients connect to namespace `/consumers` with JWT in Socket.IO
  handshake `auth.token`.
- `connection:ready` is the application readiness signal. Colmeia defaults to
  `payload_frame_only`; raw JSON is compatibility-only, requires an explicit
  `SOCKET_CONNECTION_READY_COMPAT_MODE=compat` or `raw_json_only` override, and
  is planned for removal after 2026-09-30.
- `agents:command` uses the same body shape as `POST /api/v1/agents/commands`.
  It can receive `agents:command_stream_*` from the hub, but Colmeia does not
  pull that legacy stream path.
- Progressive streaming in Colmeia is relay-only: use `relay:conversation.start`,
  `relay:rpc.request`, and credit flow through `relay:rpc.stream.pull`.
- In Colmeia app code, `useRelay: true` chooses relay transport and
  `relayMode: streaming` opts a `sql.execute` call into progressive relay
  streaming. The default relay mode is unary.
- Colmeia defaults `sql.execute` and `sql.executeBatch` to
  `api_version: "2.10"` (`plug-jsonrpc-profile/2.10`). Per-request overrides
  remain available for legacy agents.
- Large report/chart queries use relay streaming plus
  `options.prefer_db_streaming: true`. Lookup/options queries stay relay unary.
- Overview read-only `sql.executeBatch` calls use
  `options.max_parallel_read_only_batch_items: 4` by default. Local builds can
  tune this with `AGENT_SQL_OVERVIEW_BATCH_MAX_PARALLEL_READ_ONLY_ITEMS`.
- SQL result cache TTL defaults to 3000 ms and is tunable through
  `AGENT_SQL_CACHE_TTL_MS`; use the E2E comparator suite mode to validate
  changes against REST and socket instead of assuming higher TTL is faster.
- Collected relay streaming allows up to 4 concurrent `sql.execute` streams per
  agent by default. Tune with `AGENT_SQL_RELAY_STREAMING_MAX_CONCURRENT_PER_AGENT`;
  set `1` to recover the previous serial behavior.
- `SOCKET_WARM_UP_AFTER_LOGIN=true` preconnects `/consumers` after login so the
  first socket SQL call does not pay the handshake cost.
- Relay accepts one correlatable JSON-RPC request per `relay:rpc.request`; do
  not send JSON-RPC batch arrays or notifications (`id: null`) through relay.
- `client:agent.profile.updated` is treated as PayloadFrame-only by default.
  Raw JSON maps are accepted only when Colmeia is explicitly running in
  `SOCKET_PROFILE_UPDATED_LEGACY_RAW_JSON_ENABLED=true` migration mode.

## PayloadFrame defaults

- `schemaVersion`: `1.0`
- `enc`: `json`
- `cmp`: `none` or `gzip`
- `contentType`: `application/json`
- Max compressed and decoded payload: 10 MiB
- Auto gzip threshold: 4096 bytes
- Max gzip inflation ratio: 10x
- Unknown root keys and unknown `signature` keys are invalid.
- `meta.outbound_compression` is currently not a runtime performance tuning
  knob; rely on PayloadFrame gzip policy and SQL options above.

## Legacy removal plan

After 2026-09-30, once the target hub fleet no longer emits raw JSON:

1. Remove `compat` and `raw_json_only` support for `connection:ready`.
2. Remove `SOCKET_PROFILE_UPDATED_LEGACY_RAW_JSON_ENABLED` and the raw JSON
   fallback in `ClientAgentProfileUpdatedListener`.
3. Remove docs/examples that mention raw JSON as an executable path; keep only
   a changelog note if needed.

## Maintenance checklist

When plug_server changes socket or bridge behavior:

1. Check `docs/socket_client_sdk.md`, `docs/socket_relay_protocol.md`, and
   `docs/api_rest_bridge.md`.
2. Check shared constants in `src/shared/constants/agent_transport_contract.ts`.
3. Update Colmeia code, tests, and this summary together.
4. Keep `docs/bridge_agent_sql_api_options.md` aligned for SQL-specific fields.
