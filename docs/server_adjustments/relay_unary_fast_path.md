# Relay unary fast-path (skip `rpc.accepted` for unary SQL)

> **Status:** **DELIVERED** on the hub as opt-in `fastPath: true` on the
> `relay:rpc.request` envelope (2026-05-28). See
> [`DELIVERED.md`](DELIVERED.md) for the integration guide, exact wire
> shape, fallback rules (dedup / error edges), and validation method.
> **The proposal below is preserved as historical record** of the original
> request; the canonical contract is in
> [`plug_server/docs/socket_relay_protocol.md`](../../../plug_database/plug_server/docs/socket_relay_protocol.md)
> ("Relay unary fast-path"). **Priority:** medium-high.
> **Companion study on the hub side:**
> `plug_server/docs/relay_fastpath_study.md` (per
> `docs/Features/socket/socket_channel_performance_review.md`).

## Problem

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

## Measured impact

Each saved hop on the relay path removes one tick from p50 latency per
RPC. With `mergeAll` waves of 8 agents on the first across-agent
dashboard load, the saving compounds (e.g. ~8 × per-hop latency on the
first wave; subsequent waves reuse the conversation).

## Proposed hub spec

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

## Client readiness

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

## Acceptance criteria

- For unary `sql.execute` over relay with the fast-path enabled, the
  wire shows two events instead of three.
- Streaming `sql.execute` continues to use the existing three-event
  flow.
- p50/p95 of relay unary RPC latency drops by approximately one
  RTT on a comparable load test (the hub can measure this through its
  existing `socket_relay_protocol` metrics — see
  [`server_side_phase_diagnostics.md`](server_side_phase_diagnostics.md)).

## Hub-side risks to address before shipping

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

## How to validate the win

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

## References

- Client three-event flow:
  `lib/core/socket/relay/relay_command_dispatcher_impl.dart` (see
  `_onAccepted`, `_onResponseFrame`, `_onCompleteFrame`)
- Hub-side study reference (sibling repo):
  `plug_server/docs/relay_fastpath_study.md`
- Client performance review:
  `docs/Features/socket/socket_channel_performance_review.md`
