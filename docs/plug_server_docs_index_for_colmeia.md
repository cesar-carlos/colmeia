# plug_server docs index for Colmeia

This file is a short routing map for Colmeia work. The normative contract stays
in the sibling `plug_server` repository under `docs/` and shared source
constants.

## Primary references

| plug_server document | Use in Colmeia |
| --- | --- |
| `docs/api/api_rest_bridge.md` | REST bridge shape, `agents:command`, `sql.execute`, `sql.executeBatch`, pagination, timeouts, JSON-RPC ids, and REST materialization behavior. |
| `docs/socket/socket_client_sdk.md` | Consumer Socket.IO guide for `/consumers`, handshake, event names, frame compression, rate-limit hints, and examples. |
| `docs/socket/socket_relay_protocol.md` | Relay protocol: conversations, `relay:rpc.request`, `relay:rpc.stream.pull`, PayloadFrame envelope, validation, and streaming semantics. |
| `docs/client_agent_business_rules.md` | Client/agent access authorization, `client_token`, revocation behavior, and per-event authorization. |
| `docs/configuration.md` | Socket/relay env vars, rate limits, inflight gates, and payload frame defaults. |
| `docs/observability.md` | Metrics and logs for bridge latency, socket rooms, relay queues, and troubleshooting. |
| `docs/nginx_production.md` | Reverse proxy and WebSocket deployment settings. |
| `docs/limits/limites_acesso_e_quotas.md` | Access limits, quotas, rate-limit buckets, and fair-share rules that cap REST, `agents:command`, and relay throughput. |
| `docs/performance/performance_hub_agent.md` | Hub/agent performance tuning: Socket.IO transport, relay buffer caps, inflight gates, and staging smoke env hints referenced from Colmeia rollout checklists. |
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
- SQL result cache TTL defaults to 5000 ms and is tunable through
  `AGENT_SQL_CACHE_TTL_MS`; use the E2E comparator suite mode to validate
  changes against REST and socket instead of assuming higher TTL is faster.
  Catalog SQL uses 30000 ms (`AGENT_SQL_CATALOG_CACHE_TTL_MS`); explicit bypass
  and invalidation remain available.
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

1. Check `docs/socket/socket_client_sdk.md`, `docs/socket/socket_relay_protocol.md`, and
   `docs/api/api_rest_bridge.md`.
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


## Colmeia communication validation and rollout

REST remains the default. Local REST admission allows eight active calls and
16 waiters per agent, with a five-second queue wait. The local operation deadline
includes queueing, conversation setup, retries, backoff and transport fallback.
`totalTimeoutMs` is a local request policy and is never a protocol field.

`AGENT_QUERY_PROGRESSIVE_REPORTS` accepts comma-separated report IDs and is empty
by default. The typed progressive ports cover the 11 streaming summaries and
seven paged catalogs. Partial results are provisional: only an explicit complete
snapshot may be exported, and incomplete streams cannot transparently restart.
Application `watch` / `watchCatalog` entry points and the progressive presentation
controller expose this behavior; existing full-result consumers remain compatible.
An identifier enables its progressive entry point, not a new route or report screen.
The product-margin screen consumes `watchCatalog` behind its report flag, using
the original server page size and ordering. First-page rows appear while loading;
the final count is published only after validation. Paging and sharing reuse the
complete snapshot. Incomplete data is marked on the normal and fullscreen surfaces
and cannot be exported. Other screen consumers still use their complete-result
paths; their presentation integration and validation remain pending.

Strict request measurements use the existing comparison tool:
`python tool/compare_e2e_transports.py --mode requests --transport all
--warmups 5 --samples 100 --scenarios small large batch --timeout-seconds 1800
--output-json <measurement.json>`. Request latency excludes compilation and
dependency bootstrap; process wall time and bootstrap have separate records.
Supply `--baseline-json <baseline.json>` to evaluate the
completion p95 limit (+5%) and throughput floor (85%). Fallback, skipped tests,
data mismatches, errors and timeouts do not count as successful samples.

Report equivalence uses
`test/integration/e2e/agent_queries_progressive_reports_e2e_test.dart` with
`E2E_PROGRESSIVE_VALIDATION=true`. Run REST with relay dispatch disabled; run Relay
with `E2E_PROGRESSIVE_ROUTE=relay`, socket transport and relay dispatch enabled.
The test exercises every changed report against the real configured agent; failure
of the baseline is a validation failure, not a reason to approve a rollout.

Validation on 2026-10-06 measured 100 successful small-query and batch samples in
REST and Relay after five warmups, including SQL-cache bypass and cache hits.
The large-query scenario timed out, the legacy socket preparation failed, and
the initial 18 strict report checks failed on each REST/Relay route with RPC/network
failures. An additional REST product-margin check with 50-row pages reached its
ten-minute test limit: the configured E2E catalog contains 26,024 products, so
reading all 50-row pages twice exceeds that test-level timeout. Stage/page
diagnostics now report counts and elapsed time without logging report content.
The report test timeout is configurable via `E2E_PROGRESSIVE_TEST_TIMEOUT_SECONDS`
(default 1,800 seconds); production request/share deadlines are unchanged.
An additional filtered product-margin scenario (`E2E_PROGRESSIVE_MARGIN_SEARCH=MEL`,
`E2E_PROGRESSIVE_PAGE_SIZE=50`) passed strict data equivalence on REST and Relay:
1,555 rows and 31 partial batches. First emission/conclusion were approximately
3.6/127.0 seconds on REST and 3.4/98.4 seconds on Relay. These are single
equivalence runs, not performance approval. No progressive report has been approved
or enabled. A complete before/after performance baseline remains
outstanding; lower latency between transports on small queries alone is not a
rollout approval. Windows sharing loaded all 956 products and produced a 54-page
PDF with the first and last pages visually checked. The share loading state ended
and the app remained responsive; recipient delivery is not confirmed by the
Windows share API.
The subsequent Windows check found the selected branch disconnected at dispatch;
loading ended with the corresponding failure and no Dart runtime exception.
The temporary in-memory product-margin flag was cleared after that check.

Relay batching now forwards optional connection and frame-decode diagnostics.
Pending-attempt identity checks discard late async work when a retry reuses the
operation ID; draining an old stream cannot cancel the new attempt. Regression
coverage includes delayed decode on unary/streaming retries and paused-stream
cleanup. The monthly Relay equivalence check still receives an empty baseline
but times out during progressive loading after its first response. Its cause
remains under investigation and its flag stays disabled.
The corresponding REST check failed at its baseline with `replay_detected`
after a timeout/retry. The current hub contract requires distinct wire IDs on
REST and legacy `agents:command`, unlike Relay's idempotency model. Both base
datasources now generate fresh IDs for unary and batch attempts while preserving
the logical operation ID in the request for Relay selection and retries.
After this correction, the monthly REST check made three attempts and reached
its 180-second local deadline with a typed timeout and cancellation, without
`replay_detected`. It remains a failed baseline and does not approve rollout.
The final regression run passed 2,881 tests with one existing skip; static
analysis reported no issues. The Windows debug app disconnected before the last
transport changes, so another manual check of those changes remains outstanding.
