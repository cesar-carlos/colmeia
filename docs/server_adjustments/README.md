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

| #   | Item                                                      | Impact      | Effort  | Hub status (2026-05-28) | Spec |
| --- | --------------------------------------------------------- | ----------- | ------- | ----------------------- | ---- |
| 1   | Relay JSON-RPC batch (`relay:rpc.request.batch`)           | **high**    | medium  | **v1 shipped** as `relay:rpc.request.batch` (gated `SOCKET_RELAY_BATCH_ENABLED=true`; v1 limitations documented in hub `docs/adrs/0008-relay-batch-protocol.md`) | [`relay_rpc_batch_protocol.md`](relay_rpc_batch_protocol.md) |
| 2   | Fix `agents:command` hang under cross-agent fan-out        | **high**    | unknown | **Not a hub defect** (1 agentId per envelope is the contract — see hub `docs/api_rest_bridge.md`). Client repro still requested. | [`agents_command_cross_agent_hang.md`](agents_command_cross_agent_hang.md) |
| 3   | Relay unary fast-path (skip `rpc.accepted` round-trip)     | medium-high | low     | **Shipped** as `fastPath: true` opt-in | [`relay_unary_fast_path.md`](relay_unary_fast_path.md) |
| 4   | Per-phase server-side timing in responses / metrics        | medium      | low     | **Shipped** as `requestServerTimings: true` opt-in (relay + `agents:command` + REST) | [`server_side_phase_diagnostics.md`](server_side_phase_diagnostics.md) |

**For consumption guidance** — request envelope shapes, response parsing,
adoption phasing, and validation — see
[`DELIVERED.md`](DELIVERED.md).

Items 1 and 2 together would let cross-agent fan-out either batch on relay
or fall back to the already-implemented `AgentCommandBatchCoordinator` on
`agents:command`. Either path unblocks the bulk of the gap. Item 3 helps
in any case. Item 4 fundaments any future change.

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
