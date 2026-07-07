# Server adjustments — `plug_server` performance plan

This folder collects the server-side changes the Colmeia client cannot apply
unilaterally to close the REST↔Socket performance gap on cross-agent /
relay workloads. Each item links to a focused spec, the affected code on
both sides, and a validation plan.

The client side of the gap is already addressed in
[`socket_channel_performance_review.md`](../Features/socket/socket_channel_performance_review.md)
and the pre-warm shipped in
[`relay_conversation_pre_warmer.dart`](../../lib/core/socket/relay/relay_conversation_pre_warmer.dart).
Remaining client items are micro-optimizations below 5% impact; the
meaningful wins live here.

## ⚠ Pending hub work (read this first)

As of 2026-07 the relay unary fast-path defect (item 3) is **resolved** on the
hub side; Colmeia enables `SOCKET_RELAY_FAST_PATH_ENABLED=true` in bundled
`default.env`. Remaining items below need hub ops confirmation or server-side
design decisions.

| signal | required action | owner | doc |
| --- | --- | --- | --- |
| **Relay `RELAY_REQUEST_TIMEOUT` at hub default 15s** — envelope `relay:rpc.request` has no per-request timeout field (unlike REST `timeoutMs`). Colmeia SQL tiers expect 120–240s; hub may cut off before the client timer. Simple SQL also failed via socket in E2E while REST succeeded. | Confirm production `SOCKET_RELAY_REQUEST_TIMEOUT_MS`, sticky sessions, and whether per-request timeout on relay is planned or hub timeout should be raised for aggregation SQL. | `plug_server` | [`relay_request_timeout_vs_client_sql_tiers.md`](relay_request_timeout_vs_client_sql_tiers.md) |
| `agents:command` to an offline target agent hangs instead of fast-failing (relay returns `NOT_FOUND` immediately, `agents:command` waits). Client workaround in place via relay routing default; no urgent action. | Hub-side `agents:command` should mirror relay's fast-fail when the target socket is not connected. | `plug_server` | [`agents_command_cross_agent_hang.md`](agents_command_cross_agent_hang.md) |
| `SOCKET_RELAY_BATCH_ENABLED` defaulted to `false` on every hub env. Client coordinator is wired but never exercised end-to-end with real payload. | Flip `SOCKET_RELAY_BATCH_ENABLED=true` in a non-production env and notify Colmeia so we can run the comparator with the flag on. | `plug_server` ops | [`relay_rpc_batch_protocol.md`](relay_rpc_batch_protocol.md) |
| `SOCKET_REQUEST_SERVER_TIMINGS_ENABLED` opt-in works in steady state but adoption metrics on the hub side need a dashboard slice so Colmeia can confirm hub is attaching `serverTimings` correctly. | Add `plug_socket_relay_server_timings_opt_in_total` to the standard relay dashboard (Prometheus counter already emitted). | `plug_server` ops | [`server_side_phase_diagnostics.md`](server_side_phase_diagnostics.md) |

When any of the items above land, the only Colmeia change required is
flipping the matching env flag (`SOCKET_RELAY_BATCH_ENABLED`,
`SOCKET_REQUEST_SERVER_TIMINGS_ENABLED`) or adjusting timeout policy —
no code change for items already wired. Fast-path adoption is complete in
`default.env`. See [`DELIVERED.md`](DELIVERED.md).

## Context (measured)

E2E suite under socket vs REST, single run with relay enabled (default):

| scope                              | REST    | Socket+relay | delta             |
| ---------------------------------- | ------: | -----------: | ----------------- |
| Full suite (`scope=suite`)         | 79.74s  | 95.93s       | +16.19s (+20.3%)  |
| 36 E2E files (sum, `scope=files`)  | 218.35s | 230.79s      | +12.44s (+5.7%)   |
| Worst case: `agent_query_across_agents_repositories` | 10.85s | 16.54s | +5.70s (+52.5%) |
| Best case: `agent_sql_bridge`      | 7.96s   | 5.62s        | −2.34s (−29.4%)   |

Source of variance: relay protocol has 3 socket hops per RPC
(`rpc.request → rpc.accepted → rpc.response`) versus 1 HTTP hop on REST.
Under `mergeAll` fan-out across N agents this multiplies. Socket wins on
single-agent unary SQL where one persistent WebSocket beats repeated TLS
setup; it loses on fan-out because batching is unavailable on relay and
`agents:command` is unusable for the cross-agent pattern (see below).

## Priority matrix

| #   | Item                                                      | Impact      | Effort  | Status (2026-07) | Client adoption | Spec |
| --- | --------------------------------------------------------- | ----------- | ------- | -------------------- | --------------- | ---- |
| 1   | Relay JSON-RPC batch (`relay:rpc.request.batch`)           | **high**    | medium  | v1 shipped on hub, gated `SOCKET_RELAY_BATCH_ENABLED` (default `false`) | **Wired**: `RelayCommandDispatcherImpl.sendBatch` + `RelayBatchCommandCoordinator` + DI gated by `SOCKET_RELAY_BATCH_ENABLED`. Colmeia default `true`; confirm hub env. | [`relay_rpc_batch_protocol.md`](relay_rpc_batch_protocol.md) |
| 2   | Fix `agents:command` hang under cross-agent fan-out        | **high**    | unknown | Client audit PASSED (coordinator groups by `agentId`); likely hub-side: no fast-fail when target agent is offline. | **No code change needed**. Defensive test pinned in `agent_command_batch_coordinator_test.dart`. Production fallback at `injector_agent_queries.dart:348-354`. | [`agents_command_cross_agent_hang.md`](agents_command_cross_agent_hang.md) |
| 3   | Relay unary fast-path (skip `rpc.accepted` round-trip)     | medium-high | low     | **Resolved** — hub echoes client JSON-RPC `id` (Option B + ADR 0009). | **Enabled**: `SOCKET_RELAY_FAST_PATH_ENABLED=true` in `default.env`. | [`relay_unary_fast_path.md`](relay_unary_fast_path.md) |
| 4   | Per-phase server-side timing in responses / metrics        | medium      | low     | Shipped on hub as `requestServerTimings: true` opt-in (relay + `agents:command` + REST). | **Wired**: enable via `SOCKET_REQUEST_SERVER_TIMINGS_ENABLED` (staging/E2E). | [`server_side_phase_diagnostics.md`](server_side_phase_diagnostics.md) |
| 5   | Relay request timeout vs client SQL tiers (15s hub cap)    | **high**    | medium  | Open — no per-request timeout on `relay:rpc.request` envelope. | Client passes `bridgeTimeoutMs` 120–240s; hub `SOCKET_RELAY_REQUEST_TIMEOUT_MS` default **15s** may win. E2E: REST OK, socket `RELAY_REQUEST_TIMEOUT`. | [`relay_request_timeout_vs_client_sql_tiers.md`](relay_request_timeout_vs_client_sql_tiers.md) |

**For consumption guidance** — request envelope shapes, response parsing,
adoption phasing, and validation — see
[`DELIVERED.md`](DELIVERED.md).

Items 1 and 2 together would let cross-agent fan-out either batch on relay
or fall back to the already-implemented `AgentCommandBatchCoordinator` on
`agents:command`. Item 3 (fast-path) is enabled in Colmeia defaults. Item 5
(timeout parity) is the main open gap for heavy SQL over relay. Item 4
fundaments latency investigation.

## Smoke validation matrix (2026-05-28, fast-path pre-fix)

Historical smoke before hub `body.id` echo fix. After **2026-07** Colmeia
defaults `SOCKET_RELAY_FAST_PATH_ENABLED=true`; re-run
`agent_sql_bridge_e2e_test.dart` on each hub rollout.

E2E worst-case (`agent_query_across_agents_repositories_e2e_test.dart`,
socket+relay, single run):

| flag                                       | wall-clock | vs baseline | notes |
| ------------------------------------------ | ---------: | ----------: | --- |
| (none — default)                           |     11.5 s |           — | baseline |
| `SOCKET_REQUEST_SERVER_TIMINGS_ENABLED`    |     21.8 s |       +90 % | within E2E variance, hub returns `serverTimings` |
| `SOCKET_RELAY_BATCH_ENABLED`               |     21.4 s |       +86 % | within E2E variance, 1-item batches on this stub |
| `SOCKET_RELAY_FAST_PATH_ENABLED` (pre-fix) |    245.0 s |    **+2030 %** | **historical** — hub overwrote JSON-RPC `id`; fixed on hub |

Per-RPC smoke (`agent_sql_bridge_e2e_test.dart`):

| flag                                       | wall-clock | vs baseline | notes |
| ------------------------------------------ | ---------: | ----------: | --- |
| (none — default)                           |      7.0 s |           — | baseline |
| `SOCKET_RELAY_FAST_PATH_ENABLED` (pre-fix) |    278.4 s |    **+3877 %** | **historical** — see `relay_unary_fast_path.md` |

## Where this gap shows up in production

- First load of an across-agent dashboard after login (e.g. payments
  resumo, daily totals) — every `mergeAll` wave pays the relay multi-hop
  for every agent target.
- Mobile builds with multiple approved agents — each agent in the first
  wave costs one `relay:conversation.start` round-trip (the
  [`RelayConversationPreWarmer`](../../lib/core/socket/relay/relay_conversation_pre_warmer.dart)
  shipped in May/2026 hides this only after the socket reaches
  `connected`).

## What the client already does

Already wired and active by default; **no extra knobs needed on the hub
side beyond the four items above**:

- `CoalescingAgentQueriesRepository` — collapses identical inflight SQL.
- `CachingAgentQueriesRepository` — TTL cache (5s default).
- `AdaptiveTimeoutAgentQueriesRepository` — EWMA-driven request timeout.
- `RetryingAgentQueriesRepository` — backoff + jitter on transient
  failures.
- `PerAgentConcurrencyGate` — mirrors hub's `SOCKET_REST_AGENT_MAX_INFLIGHT`.
- `AgentCommandBatchCoordinator` — 8 ms window, max 32 RPCs/emit on
  `agents:command` (idle today: relay default routes around it).
- `RelayConversationPreWarmer` — opens conversations after first
  `connected` transition so first wave does not pay `conversation.start`.
- Async PayloadFrame codec with isolate offload over configurable
  thresholds.

## How to track impact

Use `tool/compare_e2e_transports.py` against an unchanged suite:

```powershell
python tool/compare_e2e_transports.py --scope suite --transport both --runs 5
```

Track median (not single-run) of the suite and the per-file worst case
(`agent_query_across_agents_repositories_e2e_test.dart`). Capture before
each hub change and after stabilization. A meaningful win shows up as a
narrowing delta in **both** the suite total and the worst-case file
without regressing the single-agent best case.
