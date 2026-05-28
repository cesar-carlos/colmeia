# Relay unary fast-path (skip `rpc.accepted` for unary SQL)

> **Document audience.** This page is for the **`plug_server` hub team**.
> The Colmeia client is wired and ready; we hit one defect on the hub
> side that blocks rollout. Sections 1–3 are the actionable bug report.
> Sections 4+ keep the original proposal and design as historical
> record.

## 1. Hub team — action checklist

**Bug priority:** high — blocks adoption of an already-shipped opt-in.
**Where to fix:** the `relay:rpc.response` builder on the fast-path branch
(skip `relay:rpc.accepted` path, see `socket_relay_protocol.md`
"Relay unary fast-path").

- [ ] **Echo the client JSON-RPC `id` in the fast-path response body.**
      The hub currently writes its own server-assigned UUID into
      `body.id`; it must instead carry the same `id` value that arrived
      in the inbound `relay:rpc.request` PayloadFrame (the JSON-RPC
      `id` is the client's correlation token; the hub's internal
      `requestId` is the wire-level correlator and stays on the
      envelope).
- [ ] Add a hub-side contract test: send a `relay:rpc.request` with
      `fastPath: true` and a known `id`; assert the matching
      `relay:rpc.response` envelope has `requestId != id` (server's
      UUID) **and** the decoded body has `id` equal to the client's id.
      This is the regression guard.
- [ ] Update `docs/socket_relay_protocol.md` "Relay unary fast-path"
      to reaffirm JSON-RPC 2.0 §5 compliance for fast-path responses
      (the existing `DELIVERED.md` client snippet already assumes this
      behaviour — it just hasn't been honoured in code).
- [ ] Bump a metric `plug_socket_relay_fast_path_id_echo_total` (or
      similar) so we can observe in production that the fix landed.
- [ ] When the fix is in a non-production env, ping the Colmeia client
      side: nothing on the client changes besides flipping
      `SOCKET_RELAY_FAST_PATH_ENABLED=true` in the chosen env file —
      see §3 below.

## 2. Empirical evidence

### What the wire shows today

Colmeia sends:

```json
{
  "jsonrpc": "2.0",
  "method": "sql.execute",
  "id": "e8c25c55-b080-4f3b-a883-a09eed9d0e36",
  "params": { ... }
}
```

with PayloadFrame envelope `requestId: "e8c25c55-..."` (same client id
mirrored for observability).

Hub answers on `relay:rpc.response` with:

```text
envelope.requestId  = 2711c443-9ebc-4ca3-88c7-24175bd4af68   ← hub-assigned UUID
decoded body.id     = 2711c443-9ebc-4ca3-88c7-24175bd4af68   ← SAME hub UUID (defect)
client pending id   = e8c25c55-b080-4f3b-a883-a09eed9d0e36   ← original
```

Expected per JSON-RPC 2.0 §5 ("Response object MUST contain the same
`id` as the Request object's `id`") **and** per the hub team's own
integration example in [`DELIVERED.md`](DELIVERED.md) lines 110–119:

```text
envelope.requestId  = 2711c443-9ebc-4ca3-88c7-24175bd4af68   ← hub-assigned UUID
decoded body.id     = e8c25c55-b080-4f3b-a883-a09eed9d0e36   ← echoed client id
```

### How to reproduce

Colmeia repo, real hub:

```powershell
# Baseline (fast-path off) — 7 s, no failures
flutter test test/integration/e2e/agent_sql_bridge_e2e_test.dart `
  --tags e2e --concurrency=1 `
  --dart-define=AGENT_BRIDGE_TRANSPORT=socket `
  --dart-define=E2E_DISABLE_RELAY_DISPATCH=false

# Fast-path on — 278 s, every SQL retries 3× before surviving via cache
flutter test test/integration/e2e/agent_sql_bridge_e2e_test.dart `
  --tags e2e --concurrency=1 `
  --dart-define=AGENT_BRIDGE_TRANSPORT=socket `
  --dart-define=E2E_DISABLE_RELAY_DISPATCH=false `
  --dart-define=SOCKET_RELAY_FAST_PATH_ENABLED=true
```

Excerpt (with temporary client-side instrumentation enabled during
diagnosis):

```text
00:00 Agent SQL bridge (e2e) executeSql loads Cliente rows on the legacy bridge
01:46 +1: ...executeSql loads Cliente with body page pagination
  agent_sql_bridge_pagination failure: type=NetworkFailure
  message=A consulta demorou mais do que o esperado. Tente novamente.
03:31 +2: ...executeSqlBatch runs multiple SQL commands in one bridge call
  agent_sql_bridge_execute_batch failure: type=NetworkFailure
  message=A consulta demorou mais do que o esperado. Tente novamente.
04:32 +3: All tests passed!
FAST_WITHFLAG=278.36s
```

### Why this matters for both ends

The hub team's own integration snippet in
[`DELIVERED.md`](DELIVERED.md) lines 110–119 is:

```dart
void _onResponseFrame(PayloadFrame frame) {
  final hubRequestId = frame.envelope.requestId;
  final clientRequestId = _clientIdFromJsonRpcId(frame.data);

  if (hubRequestId != null && clientRequestId != null) {
    _clientIdByRequestId.putIfAbsent(hubRequestId, () => clientRequestId);
  }

  final pending = _pendingByClientId.remove(clientRequestId);
  pending?.completer.complete(frame.data);
}
```

The Colmeia implementation followed exactly this contract
(`_pendingFromSyncDecodedBody` in
[`lib/core/socket/relay/relay_command_dispatcher_impl.dart`](../../lib/core/socket/relay/relay_command_dispatcher_impl.dart)).
The defect is on the producer side: `frame.data.id` carries the hub's
UUID instead of the client's `id`, so the lookup misses on every
fast-path response and the dispatcher drops the frame.

## 3. Client adoption — after the hub fix lands

**No client code change is required.** The wiring already implements
the contract the hub team specified. Once the hub fix is deployed in a
target environment, the Colmeia operator flips a single env knob:

### Local / dev / E2E build

`assets/env/local.env` (gitignored):

```env
SOCKET_RELAY_FAST_PATH_ENABLED=true
```

### CI / non-production

`--dart-define=SOCKET_RELAY_FAST_PATH_ENABLED=true` on `flutter test` /
`flutter build`.

### Production rollout (after the same env knob is enabled hub-side)

Set `SOCKET_RELAY_FAST_PATH_ENABLED=true` in the production env
override (`assets/env/default.env` if rolling broadly, or a build-time
`--dart-define` for canary cohorts).

### What you should observe after flipping the flag

| signal | expected change |
| --- | --- |
| Hub Prometheus: `plug_socket_relay_fast_path_honored_total / plug_socket_relay_fast_path_requested_total` | ≥ 80 % in steady state (dedup / error edges keep the legacy `accepted` path) |
| Hub Prometheus: `plug_socket_relay_fast_path_stream_inadvertent_total` | ≈ 0 (Colmeia bypasses streaming, see [`relay_command_dispatcher_impl.dart`](../../lib/core/socket/relay/relay_command_dispatcher_impl.dart) — `allowFastPath: true` on `sendUnary` only) |
| Colmeia E2E `agent_sql_bridge_e2e_test.dart` | wall-clock ≤ baseline (7 s typical) — no retries |
| Colmeia `SocketChannelMetrics.relayRequestToAcceptedMs` | sample count near zero for unary on fast-path (only streaming + dedup edges contribute) |
| Colmeia `SocketChannelMetrics.relayDispatchMsByKey` p50 / p95 for unary `sql.execute` | drop by ≈ 1 RTT compared to baseline |

### What we will roll back to if the win does not materialise

Flip the env knob back to `false` (or remove it — `false` is the
default in [`env_keys.dart`](../../lib/core/config/env_keys.dart)).
There is no other code path or migration to undo.

## 4. Original proposal (history)

> Filed before the hub shipped fast-path. Preserved here for context.
> The canonical contract is in
> [`plug_server/docs/socket_relay_protocol.md`](../../../plug_database/plug_server/docs/socket_relay_protocol.md)
> ("Relay unary fast-path"). **Priority:** medium-high.
> **Companion study on the hub side:**
> `plug_server/docs/relay_fastpath_study.md` (per
> `docs/Features/socket/socket_channel_performance_review.md`).

### Problem

Today each relay RPC traverses 3 events on the wire:

```text
client          hub                    agent
  │   rpc.request   →                    │
  │  ← rpc.accepted (server ack)         │
  │                  request forwarded   →
  │                  ← response forwarded
  │  ← rpc.response                       │
```

The `rpc.accepted` step is mostly an artifact of the streaming pattern
(client uses it to wait for the server-side handle before honoring
window credits / cancellation). For **unary** SQL it is dead weight: the
client only needs the final `rpc.response`.

Compare with `agents:command`:

```text
client          hub                    agent
  │   agents:command          →           │
  │                  request forwarded    →
  │                  ← response forwarded
  │  ← agents:command_response             │
```

One client-side round-trip; the hub's internal hand-off is invisible.

### Measured impact

Each saved hop on the relay path removes one tick from p50 latency per
RPC. With `mergeAll` waves of 8 agents on the first across-agent
dashboard load, the saving compounds (e.g. ~8 × per-hop latency on the
first wave; subsequent waves reuse the conversation).

### Proposed hub spec

Two non-exclusive options. Either alone is a win; both together are
ideal.

### Option A — opt-in via request flag

Add `meta.fastPath: true` (or equivalent) on `relay:rpc.request`. When
present, the hub:

- Skips `relay:rpc.accepted` emission.
- Delivers `relay:rpc.response` (or `relay:rpc.complete`) as soon as the
  agent answers.
- On internal hub-side failure before the agent answers, emits an
  `app:error` or `relay:rpc.response` with the same `clientRequestId`
  and a documented error code (e.g. `relay_fastpath_aborted`).

Backwards compatible: clients without the flag keep getting the
three-event flow.

### Option B — coalesce `accepted` + `response` into the response event

Make `relay:rpc.response` carry the `requestId` field that `rpc.accepted`
normally provides, and emit `accepted` only if the agent supplies any
out-of-band progress before answering (streaming case). Saves a hop
without any client opt-in, at the cost of a `socket_relay_protocol.md`
breaking note (clients that listen on `rpc.accepted` for unary RPCs are
not advised, but auditing existing consumers is unavoidable).

### Client readiness

The client already correlates by `clientRequestId` and `requestId`
together:

```80:88:lib/core/socket/relay/relay_command_dispatcher_impl.dart
  /// id) is filled in when `relay:rpc.accepted` arrives so subsequent
  /// `response` / `complete` events can be routed by either id — the hub
  /// uses `requestId` for downstream events.
  final Map<String, _PendingRelay> _pendingByClientId = ...

  /// Populated only after `relay:rpc.accepted`.
  final Map<String, String> _clientIdByRequestId = ...
```

For option A, the client work is minimal:

- Emit `meta.fastPath: true` on unary `sendUnary` paths (gated by a new
  client flag, e.g. `SOCKET_RELAY_FAST_PATH_ENABLED`).
- Treat missing `rpc.accepted` as expected when the flag was set.
- Keep `clientRequestId` → `requestId` mapping populated from
  `rpc.response.requestId` instead of `rpc.accepted.requestId` when the
  shortcut applies.

For option B, the client must learn to populate the `clientId` ↔
`requestId` map from `rpc.response` directly — already a small change.

Streaming RPCs (`relayMode: streaming`) MUST keep the three-event flow:
the window/credit handshake needs `rpc.accepted` to anchor the
`requestId` for `rpc.stream.pull`.

### Acceptance criteria

- For unary `sql.execute` over relay with the fast-path enabled, the
  wire shows two events instead of three.
- Streaming `sql.execute` continues to use the existing three-event
  flow.
- p50/p95 of relay unary RPC latency drops by approximately one
  RTT on a comparable load test (the hub can measure this through its
  existing `socket_relay_protocol` metrics — see
  [`server_side_phase_diagnostics.md`](server_side_phase_diagnostics.md)).

### Hub-side risks to address before shipping

1. **Cancellation semantics.** Today `relay:rpc.cancel` carries
   `requestId`. If the client never sees `rpc.accepted`, it must fall
   back to `clientRequestId` for cancellation, or the hub must accept
   either id. Document explicitly.
2. **Error during hand-off.** If the agent never receives the
   forwarded request (network drop hub↔agent), the fast-path client
   waits without any signal. Hub MUST emit a synthetic error
   `rpc.response.error` with the configured timeout.
3. **Mixed conversations.** Same conversation handling unary fast-path
   and streaming concurrently must keep correlation isolated.

### How to validate the win

```powershell
# Baseline
python tool/compare_e2e_transports.py --scope suite --transport socket --runs 5

# Fast-path on
python tool/compare_e2e_transports.py --scope suite --transport socket --runs 5 \
  --dart-define=SOCKET_RELAY_FAST_PATH_ENABLED=true
```

Expected: every cross-agent file improves by approximately the
per-hop RTT × number of relay RPCs issued by the test. Single-agent
files improve proportionally to the number of relay RPCs.

### References

- Client three-event flow:
  `lib/core/socket/relay/relay_command_dispatcher_impl.dart` (see
  `_onAccepted`, `_onResponseFrame`, `_onCompleteFrame`)
- Hub-side study reference (sibling repo):
  `plug_server/docs/relay_fastpath_study.md`
- Client performance review:
  `docs/Features/socket/socket_channel_performance_review.md`
