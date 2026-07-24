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
| `docs/limits/limites_acesso_e_quotas.md` | Access limits, quotas, rate-limit buckets, and fair-share rules that cap REST, `agents:command`, and relay throughput. |
| `docs/performance_hub_agent.md` | Hub/agent performance tuning: Socket.IO transport, relay buffer caps, inflight gates, and staging smoke env hints referenced from Colmeia rollout checklists. |
| `docs/adrs/0008-relay-batch-protocol.md` | ADR for relay JSON-RPC batch (`relay:rpc.request.batch`, v1 shipped **2026-05-28**). |
| `docs/adrs/0009-relay-unary-fast-path.md` | ADR for relay unary fast-path (`fastPath` opt-in; hub echoes client JSON-RPC `id` on fast-path responses — see Colmeia [`docs/server_adjustments/relay_unary_fast_path.md`](server_adjustments/relay_unary_fast_path.md)). |
| `docs/adrs/0010-request-server-timings.md` | ADR for per-phase `requestServerTimings` on relay, `agents:command`, and REST. |
| `docs/plug_agente/03_performance_roadmap.md` | Agent-side performance roadmap and expectations for bridge SQL, streaming, and batch semantics. |
| Colmeia [`docs/bridge_agent_sql_api_options.md`](bridge_agent_sql_api_options.md) | Colmeia-facing bridge SQL summary: `sql.execute` / `sql.executeBatch`, choosing `multi_result` vs semantic batch vs JSON-RPC batch arrays, overview read-only parallelism (`max_parallel_read_only_batch_items`). Payload examples: `plug_server/docs/snippets/agent_command_performance_options.ts`. |
| Colmeia [`docs/Features/socket/socket_channel_performance_review.md`](Features/socket/socket_channel_performance_review.md) | Client socket/relay performance notes: coalescing, batch, gates, temporary REST latch, obtain single-flight, pool=`1`. |
| Colmeia [`docs/Features/socket/socket_production_rollout_runbook.md`](Features/socket/socket_production_rollout_runbook.md) | Rollout smoke + troubleshooting (temp REST latch, relay fast-path). |

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
- REST-only: Colmeia caps concurrent `POST /api/v1/agents/commands` per agent id
  at 8 by default (`AGENT_SQL_REST_MAX_INFLIGHT_PER_AGENT`); set `0` to disable
  client-side limiting.
- `SOCKET_WARM_UP_AFTER_LOGIN=true` preconnects `/consumers` after login so the
  first socket SQL call does not pay the handshake cost.
- Relay unary uses one correlatable JSON-RPC command per `relay:rpc.request`.
  Multi-RPC relay batching uses `relay:rpc.request.batch` when both hub and
  client enable `SOCKET_RELAY_BATCH_ENABLED` (hub v1 shipped **2026-05-28**;
  `true` in bundled `default.env`). Do not send JSON-RPC notifications
  (`id: null`) through relay.
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

## Colmeia ↔ hub feature flags

These flags must be enabled on **both** the hub deployment and the Colmeia
build (via `assets/env/local.env`, `default.env`, or `--dart-define`). Colmeia
code is already wired; flipping a client flag before the hub accepts the
contract causes rejections or retries. See
[`docs/server_adjustments/DELIVERED.md`](server_adjustments/DELIVERED.md) for
envelope shapes and validation.

| Flag | Hub / client contract | Colmeia default | Rollout notes |
| --- | --- | --- | --- |
| `SOCKET_RELAY_BATCH_ENABLED` | `relay:rpc.request.batch` — multiple JSON-RPC commands per relay emit (ADR 0008). | `true` in bundled `default.env` | Hub v1 shipped **2026-05-28**; E2E validated before production default. Override `false` for A/B. Distinct from `SOCKET_BATCH_ENABLED` (see [`bridge_agent_sql_api_options.md`](bridge_agent_sql_api_options.md)). |
| `SOCKET_RELAY_FAST_PATH_ENABLED` | Relay unary skips `relay:rpc.accepted` when `fastPath: true` (ADR 0009). | `true` in bundled `default.env` | Hub fix shipped **2026-05** (Option B) + ADR 0009 **2026-06-24**. Roll back to `false` if a hub still returns hub UUID in `body.id` (see [`server_adjustments/relay_unary_fast_path.md`](server_adjustments/relay_unary_fast_path.md)). |
| `SOCKET_REQUEST_SERVER_TIMINGS_ENABLED` | Appends `serverTimings` phase snapshot to relay, `agents:command`, and REST responses (ADR 0010). | `false` | Safe for E2E and diagnostic builds (~120 B per response). Enable when correlating client metrics with hub queue/SQL phases. |

Related client-only socket tuning (no hub mirror flag): `SOCKET_BATCH_ENABLED`
coalesces multiple JSON-RPC objects into one `agents:command` emit — not relay.

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
5. For REST-only fleets, validate `AGENT_SQL_REST_MAX_INFLIGHT_PER_AGENT`
   against hub rate limits and `503` / negotiation warm-up behavior (see
   `RetryingAgentQueriesRepository` cooperative retries).

## Colmeia — socket production rollout checklist

Use this as a gate before changing Colmeia production
`AGENT_BRIDGE_TRANSPORT` from `rest` to `socket` (dedicated PR; do not mix with
unrelated perf tuning):

1. **E2E:** `flutter test test/integration/e2e/ --concurrency=1` green for the
   socket profile (see `.github/workflows/flutter_e2e.yml` and
   `tool/compare_e2e_transports.py`).
2. **Hub / edge:** Sticky sessions for Socket.IO (nginx upstream or
   `X-Hub-Instance-Id`); `SOCKET_CONSUMER_ROLES` and relay prerequisites per
   `docs/configuration.md` and `docs/nginx_production.md` in plug_server.
3. **Staging:** Flip transport in staging env; watch `503`, relay timeouts,
   and `namespace forbidden`; compare REST vs socket wall-clock where useful.
4. **Production:** Flip `default.env` only after sign-off; keep
   `RestInflightAgentQueriesRepository` for REST and REST fallback paths.

Optional after stable rollout: `SOCKET_BATCH_ENABLED` (`agents:command` only),
`SOCKET_RELAY_BATCH_ENABLED` (relay batch, hub shipped 2026-05-28), and
relay/stream tuning documented in `docs/bridge_agent_sql_api_options.md`.

## Staging validation checklist (relay batch)

Production `assets/env/default.env` sets `SOCKET_RELAY_BATCH_ENABLED=true`.
Use this checklist when re-validating hub rollouts or local overrides:

1. **Hub staging:** `SOCKET_RELAY_BATCH_ENABLED=true` on the hub deployment
   (v1 shipped **2026-05-28**); `SOCKET_CONSUMER_ROLES` includes `client`;
   sticky Socket.IO sessions per `docs/nginx_production.md` in plug_server.
2. **Colmeia staging:** merge `assets/env/staging.env` into
   `assets/env/local.env` or pass
   `--dart-define=SOCKET_RELAY_BATCH_ENABLED=true` (see
   `assets/env/.env.example`).
3. **E2E comparator:** run with batch off, then on (`--concurrency=1`):
   `overview_batch_loader_e2e_test.dart`,
   `load_sales_live_map_use_case_e2e_test.dart`,
   `agent_queries_socket_relay_smoke_e2e_test.dart`, and
   `agent_query_across_agents_repositories_e2e_test.dart` (worst-case fan-out).
4. **Fast-path:** `SOCKET_RELAY_FAST_PATH_ENABLED=true` is the bundled default
   (hub echoes client JSON-RPC `id` per ADR 0009 — see
   [`server_adjustments/relay_unary_fast_path.md`](server_adjustments/relay_unary_fast_path.md)).
   Roll back to `false` only on hubs that still return a hub UUID in `body.id`.
5. **Optional:** `SOCKET_REQUEST_SERVER_TIMINGS_ENABLED=true` on hub + client
   for phase correlation during staging only.
6. **Sign-off:** no new `relay_batch_not_supported` / `RATE_LIMITED` spikes;
   wall-clock within expected variance vs batch-off baseline
   ([`server_adjustments/README.md`](server_adjustments/README.md) smoke matrix).
