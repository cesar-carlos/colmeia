# `agents:command` cross-agent hang

> **Status (revised by hub team, 2026-05-28):** **not reproducible as a
> hub defect**. The hub's `agents:command` correlation map is keyed on
> the JSON-RPC `id` globally, not on `(socketId, agentId)`. Two parallel
> events from the same consumer to different agents do not collide.
> The likely root cause is **client-side**:
> `AgentCommandBatchCoordinator` may be packing commands targeted at
> DIFFERENT agents into a single envelope, where the hub will dispatch
> the whole batch to the single `agentId` declared in the envelope. The
> hub now documents this contract explicitly in
> [`plug_server/docs/api_rest_bridge.md`](../../../plug_database/plug_server/docs/api_rest_bridge.md)
> ("Limite de um agentId por envelope"). Client action: audit the
> coordinator's grouping, or provide a minimal repro (1 socket, 2 distinct
> `agents:command` events, NOT 1 batch) with hub logs. See
> [`DELIVERED.md`](DELIVERED.md) for details. **Priority:** high
> (until repro confirms otherwise).
> **Workaround:** Colmeia routes every SQL through relay on socket
> transport, intentionally bypassing `agents:command`.

## Symptom

When `AGENT_BRIDGE_TRANSPORT=socket` and the relay path is disabled
(forcing the client to use `agents:command` directly), the very first
SQL call inside a cross-agent `mergeAll` wave never resolves. The hub
neither replies with `agents:command_response` nor with
`app:error`; the call hangs until the per-request timeout (default
30s) or the test framework timeout, whichever fires first.

## Workaround in the Colmeia client

The decision lives at:

```351:354:lib/core/di/injector_agent_queries.dart
final base = switch (AppEnvironment.agentBridgeTransport) {
  AgentBridgeTransport.socket => relayFallback ?? legacySocketBase(),
  AgentBridgeTransport.rest => rest,
};
```

```348:350:lib/core/di/injector_agent_queries.dart
// When relay is available on socket transport, route all SQL
// (including `useRelay: false`) through relay unary instead of
// `agents:command`, which hangs when the hub does not respond.
```

In practice this means socket builds **never** exercise the
`AgentCommandBatchCoordinator` for cross-agent fan-out, even though the
coordinator is wired and `SOCKET_BATCH_ENABLED=true` is the default.

## Repro

```powershell
flutter test test/integration/e2e/agent_query_across_agents_repositories_e2e_test.dart \
  --tags e2e --concurrency=1 \
  --dart-define=AGENT_BRIDGE_TRANSPORT=socket \
  --dart-define=E2E_DISABLE_RELAY_DISPATCH=true
```

Setting `E2E_DISABLE_RELAY_DISPATCH=true` causes `injector_socket.dart`
to skip the relay manager registration, so `injector_agent_queries.dart`
falls back to `legacySocketBase()` (= direct `agents:command`).

Observed on `2026-05-27`:

```text
00:00 +0: loading agent_query_across_agents_repositories_e2e_test.dart
00:00 +0: Across-agent repository coverage (setUpAll)
00:01 +0: Across-agent repository coverage load payment-method resumo variants through mergeAll
[ stuck at the first sub-test for > 5 minutes; killed manually ]
```

For comparison, the same test under socket+relay completes in ~10 s and
under REST in ~8 s.

## Why this matters

Fixing the hang would let the client default route through
`agents:command` for cross-agent fan-out where appropriate, immediately
unlocking the already-implemented `AgentCommandBatchCoordinator`:

- 8 ms batch window
- Up to 32 RPCs per emit
- Single correlated `agents:command_response` round-trip per batch
- Per-agent gate respected via `PerAgentConcurrencyGate`

That alone would likely close the cross-agent gap without needing the
relay batch protocol from
[`relay_rpc_batch_protocol.md`](relay_rpc_batch_protocol.md) — although
the two are complementary and shipping both is the cleanest outcome.

## Hypotheses to investigate hub-side

(Order is suggestion; pick whatever the hub team can reach fastest.)

1. **Correlation map keyed on the wrong tuple.** If the hub correlates
   responses by `(socketId, agentId)` instead of `(socketId, rpcId)`, a
   parallel wave to N agents may collide and only one resolves.
2. **Queue head-of-line block** when multiple inflight `agents:command`
   target different agents but share a queue partition.
3. **Per-process correlation** (mentioned in
   `plug_server/docs/scaling_and_roadmap.md`) interacting badly with
   sticky sessions when the load balancer routes the second leg to a
   different worker.
4. **Backpressure / overload-gate** silently dropping the request when
   inflight crosses some internal threshold (no `app:error`, no log).
5. **Missing event listener installation** for `agents:command_response`
   on certain code paths — would explain "no response, no error".

## Acceptance criteria

- Same test as the repro succeeds under
  `AGENT_BRIDGE_TRANSPORT=socket` + `E2E_DISABLE_RELAY_DISPATCH=true`
  within the per-test timeout.
- Wall-clock comparable to or better than REST and relay variants.
- Hub log includes the per-request id, agent id, and response time for
  every `agents:command` (see also
  [`server_side_phase_diagnostics.md`](server_side_phase_diagnostics.md)).

## How to validate the win

```powershell
# After hub fix, A/B with relay disabled to exercise agents:command:
python tool/compare_e2e_transports.py --scope files --transport socket --runs 5 \
  --dart-define=E2E_DISABLE_RELAY_DISPATCH=true
```

Expected: cross-agent E2E files match or beat REST. Single-agent files
unchanged. If the fix is confirmed, the `relayFallback ?? legacySocketBase()`
selector in the client can be revisited so unary cross-agent SQL routes
through `agents:command` + batch coordinator while large/streaming
queries stay on relay.

## References

- Client default fallback selector: `lib/core/di/injector_agent_queries.dart:348-354`
- Client batch coordinator (target of this fix):
  `lib/core/socket/agent_command_batch_coordinator.dart`
- Hub contract: `plug_server/docs/api_rest_bridge.md`,
  `plug_server/docs/socket_relay_protocol.md`
