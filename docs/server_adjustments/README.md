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

As of 2026-05-28 the client side of items 1–4 is fully wired. There is
**one open hub defect** holding back the rollout of item 3 (relay
unary fast-path) — every other item is either rolled out or unblocked
on the hub flipping its own env knob.

| signal | required action | owner | doc |
| --- | --- | --- | --- |
| **Hub fast-path responses overwrite the JSON-RPC `id` with the server UUID instead of echoing the client `id`** — every fast-path response is unroutable on the client side, retries 3× and survives via cache (7 s → 278 s smoke result). | Hub-side fix in the fast-path response builder; client requires zero code change after the fix, just flipping `SOCKET_RELAY_FAST_PATH_ENABLED=true`. | `plug_server` | [`relay_unary_fast_path.md` §1 "Hub team — action checklist"](relay_unary_fast_path.md) |
| `agents:command` to an offline target agent hangs instead of fast-failing (relay returns `NOT_FOUND` immediately, `agents:command` waits). Client workaround in place via relay routing default; no urgent action. | Hub-side `agents:command` should mirror relay's fast-fail when the target socket is not connected. | `plug_server` | [`agents_command_cross_agent_hang.md`](agents_command_cross_agent_hang.md) |
| `SOCKET_RELAY_BATCH_ENABLED` defaulted to `false` on every hub env. Client coordinator is wired but never exercised end-to-end with real payload. | Flip `SOCKET_RELAY_BATCH_ENABLED=true` in a non-production env and notify Colmeia so we can run the comparator with the flag on. | `plug_server` ops | [`relay_rpc_batch_protocol.md`](relay_rpc_batch_protocol.md) |
| `SOCKET_REQUEST_SERVER_TIMINGS_ENABLED` opt-in works in steady state but adoption metrics on the hub side need a dashboard slice so Colmeia can confirm hub is attaching `serverTimings` correctly. | Add `plug_socket_relay_server_timings_opt_in_total` to the standard relay dashboard (Prometheus counter already emitted). | `plug_server` ops | [`server_side_phase_diagnostics.md`](server_side_phase_diagnostics.md) |

When any of the items above land, the only Colmeia change required is
flipping the matching env flag (`SOCKET_RELAY_FAST_PATH_ENABLED`,
`SOCKET_RELAY_BATCH_ENABLED`, `SOCKET_REQUEST_SERVER_TIMINGS_ENABLED`) —
no code or build change. The wiring already implements the contract the
hub team specified in [`DELIVERED.md`](DELIVERED.md).

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

| #   | Item                                                      | Impact      | Effort  | Status (2026-05-28) | Client adoption | Spec |
| --- | --------------------------------------------------------- | ----------- | ------- | -------------------- | --------------- | ---- |
| 1   | Relay JSON-RPC batch (`relay:rpc.request.batch`)           | **high**    | medium  | v1 shipped on hub, gated `SOCKET_RELAY_BATCH_ENABLED` (default `false`) | **Wired**: `RelayCommandDispatcherImpl.sendBatch` + `RelayBatchCommandCoordinator` + DI gated by `SOCKET_RELAY_BATCH_ENABLED`. Smoke E2E: 21.4 s (within variance vs 11.5 s baseline). Flip when hub env enables the flag. | [`relay_rpc_batch_protocol.md`](relay_rpc_batch_protocol.md) |
| 2   | Fix `agents:command` hang under cross-agent fan-out        | **high**    | unknown | Client audit PASSED (coordinator groups by `agentId`); likely hub-side: no fast-fail when target agent is offline. | **No code change needed**. Defensive test pinned in `agent_command_batch_coordinator_test.dart` (`never mixes commands from different agents in one envelope`). Production fallback at `injector_agent_queries.dart:348-354` continues to route around the issue. | [`agents_command_cross_agent_hang.md`](agents_command_cross_agent_hang.md) |
| 3   | Relay unary fast-path (skip `rpc.accepted` round-trip)     | medium-high | low     | Shipped on hub as `fastPath: true` opt-in **but defective** — JSON-RPC `id` is overwritten with the hub UUID instead of echoing the client `id` (defect documented in [`relay_unary_fast_path.md`](relay_unary_fast_path.md)). | **Wired but DISABLED**. `SOCKET_RELAY_FAST_PATH_ENABLED` MUST remain `false` until the hub fix ships — smoke E2E showed 7 s → 278 s (40× slowdown, every SQL retries 3×) because responses can't be routed back to pendings. | [`relay_unary_fast_path.md`](relay_unary_fast_path.md) |
| 4   | Per-phase server-side timing in responses / metrics        | medium      | low     | Shipped on hub as `requestServerTimings: true` opt-in (relay + `agents:command` + REST). | **Wired**: `ServerTimings.tryParse*` + `SocketChannelMetrics.recordServerTimings` + per-phase histograms + emit on all 3 dispatchers via `SOCKET_REQUEST_SERVER_TIMINGS_ENABLED`. Smoke E2E: 21.8 s (within variance). Safe to enable in E2E and diagnostic builds. | [`server_side_phase_diagnostics.md`](server_side_phase_diagnostics.md) |

**For consumption guidance** — request envelope shapes, response parsing,
adoption phasing, and validation — see
[`DELIVERED.md`](DELIVERED.md).

Items 1 and 2 together would let cross-agent fan-out either batch on relay
or fall back to the already-implemented `AgentCommandBatchCoordinator` on
`agents:command`. Either path unblocks the bulk of the gap. Item 3 helps
in any case (once the hub defect is fixed). Item 4 fundaments any future change.

## Smoke validation matrix (2026-05-28)

E2E worst-case (`agent_query_across_agents_repositories_e2e_test.dart`,
socket+relay, single run):

| flag                                       | wall-clock | vs baseline | notes |
| ------------------------------------------ | ---------: | ----------: | --- |
| (none — default)                           |     11.5 s |           — | baseline |
| `SOCKET_REQUEST_SERVER_TIMINGS_ENABLED`    |     21.8 s |       +90 % | within E2E variance, hub returns `serverTimings` |
| `SOCKET_RELAY_BATCH_ENABLED`               |     21.4 s |       +86 % | within E2E variance, 1-item batches on this stub |
| `SOCKET_RELAY_FAST_PATH_ENABLED`           |    245.0 s |    **+2030 %** | **defective**, hub overwrites JSON-RPC `id` — keep `false` |

Per-RPC smoke (`agent_sql_bridge_e2e_test.dart`):

| flag                                       | wall-clock | vs baseline | notes |
| ------------------------------------------ | ---------: | ----------: | --- |
| (none — default)                           |      7.0 s |           — | baseline |
| `SOCKET_RELAY_FAST_PATH_ENABLED`           |    278.4 s |    **+3877 %** | every SQL retries 3× before survival; see `relay_unary_fast_path.md` for repro |

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
