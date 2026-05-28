# Relay JSON-RPC batch (`relay:rpc.request.batch`)

> **Status:** **v1 shipped on the hub** (2026-05-28). Gated by
> `SOCKET_RELAY_BATCH_ENABLED=true` (default `false`). The event
> `relay:rpc.request.batch` is now accepted; per-item correlation flows in
> a single `relay:rpc.batch_accepted` envelope; per-item responses
> continue on the existing `relay:rpc.response`. See
> [`plug_server/docs/socket_relay_protocol.md`](../../../plug_database/plug_server/docs/socket_relay_protocol.md)
> ("Relay JSON-RPC batch") for the canonical contract and
> [`plug_server/docs/adrs/0008-relay-batch-protocol.md`](../../../plug_database/plug_server/docs/adrs/0008-relay-batch-protocol.md)
> for the decision record and **v1 limitations** (`requestServerTimings`/
> `fastPath` accepted at envelope schema but NOT propagated per-item;
> internal per-item PayloadFrame re-encode for v1). See
> [`DELIVERED.md`](DELIVERED.md) for the integration guide on the client
> side; flip `SOCKET_RELAY_BATCH_ENABLED` on the client after the hub
> rollout. **Priority:** high.
> **Client readiness:** flag and guard already wired.
> **Companion draft on the client repo:** [`docs/Features/socket/relay_batch_future_spec.md`](../Features/socket/relay_batch_future_spec.md).

## Problem

Today, every relay RPC pays a 3-hop protocol round-trip
(`relay:rpc.request → relay:rpc.accepted → relay:rpc.response/complete`)
plus one PayloadFrame encode/decode pair. When
`AgentQueryExecutor.mergeAll` fans out across N agents, that overhead
multiplies linearly.

REST and `agents:command` already accept a JSON-RPC batch array (up to 32
RPCs per emit); relay does not. Quoting Colmeia's API summary
(`docs/bridge_agent_sql_api_options.md`, line 102):

> `JSON-RPC command: []` — Up to 32 independent RPC objects in one REST
> body. **Not used for overview batch; relay intentionally accepts a
> single correlatable RPC per frame.**

Result: socket-default builds cannot leverage either the hub-side
JSON-RPC batch **or** the client-side `AgentCommandBatchCoordinator`
(which empacotes 32 RPCs / 8 ms but only over `agents:command`).

## Measured impact

`agent_query_across_agents_repositories_e2e_test.dart` is +52.5% slower on
socket+relay vs REST in a single run. The dominant component is per-RPC
relay protocol overhead; collapsing N RPCs into 1 emit would cut
wall-clock by approximately N − 1 round-trips per wave.

## Client readiness

Already in place, waiting for the hub:

- Env flag: `SOCKET_RELAY_BATCH_ENABLED`, default `false`.
- Guard: `RelayBatchProtocolGuard.assertBatchNotRequested(itemCount:)`
  rejects multi-item batch attempts with `RelayRequestRejected` /
  `relay_batch_not_supported` when the flag is off.
- Client batch coordinator design (`AgentCommandBatchCoordinator`)
  already implements the windowing + correlation pattern for
  `agents:command`; the same windowing can be redirected to relay.

Files to extend on the client after the hub ships:

- `lib/core/socket/relay/relay_command_dispatcher_impl.dart`
- `lib/core/socket/relay/relay_batch_protocol_guard.dart`
- `lib/core/di/injector_socket.dart` (DI for a relay-batch coordinator,
  mirroring `AgentCommandBatchCoordinator`).

## Proposed hub spec

### 1. New event (preferred) or extended `relay:rpc.request`

Preferred: dedicated event so single-RPC clients are not forced to
re-encode their payload.

```text
event: relay:rpc.request.batch
payload (PayloadFrame): {
  conversationId: string,
  batchId: string,           // server- or client-generated, optional
  items: [
    {
      clientRequestId: string,
      command: JsonRpcRequest // same shape as today's single rpc.request
    },
    ...
  ],
  meta: { ... }              // same envelope fields as rpc.request
}
```

Hard cap on `items.length`: **32**, matching `agents:command` batch
limit and the existing client coordinator. Batches above cap return a
synchronous `relay:rpc.response` with one `error.code = batch_too_large`
per item, or a single `app:error` rejection — pick whichever is cheaper
to validate, but document the chosen mode in `socket_relay_protocol.md`.

### 2. Per-item correlation

Each `clientRequestId` MUST be answered independently on
`relay:rpc.response` (and `relay:rpc.complete` for streaming items, if
mixed batches are supported). No global batch reply — clients must be
able to consume results as they land.

### 3. Backpressure

Each batch item counts as 1 against the per-agent inflight gate (current
`SOCKET_RELAY_*` caps). The hub MUST NOT collapse the batch into a single
gate slot, otherwise large batches starve other tenants.

### 4. Partial failure

Each item resolves independently. A failure on item *k* does not abort
the rest; clients reconcile per `clientRequestId`. This matches existing
`agents:command` batch semantics.

### 5. Mixed unary + streaming (optional, v2)

For v1, recommend restricting batch items to **unary** RPCs (no
`prefer_db_streaming`, no relay streaming). Streaming items would require
window/credit coordination per item and complicate flow control. Defer
to a v2 spec once unary batch is validated.

### 6. Signing & compression

PayloadFrame envelope rules unchanged. The signer/HMAC operates over the
**whole batch frame**, not per item, mirroring how the codec already
treats `rpc.request`.

## Acceptance criteria

- Hub accepts `relay:rpc.request.batch` with 1–32 items and answers each
  with one `relay:rpc.response`.
- Per-agent gate slots counted per item.
- Batch frames over 32 items rejected with a well-defined error code.
- `socket_relay_protocol.md` and `bridge_agent_sql_api_options.md`
  updated to describe the batch envelope.
- E2E suite on the Colmeia side passes with `SOCKET_RELAY_BATCH_ENABLED=true`.

## How to validate the win

After hub ships, on the Colmeia client:

```powershell
# Baseline (current default)
python tool/compare_e2e_transports.py --scope suite --transport socket --runs 5

# With relay batch on
python tool/compare_e2e_transports.py --scope suite --transport socket --runs 5 \
  --dart-define=SOCKET_RELAY_BATCH_ENABLED=true
```

Expected: cross-agent files
(`agent_query_across_agents_repositories_e2e_test.dart`,
`load_resumo_*_across_agents_e2e_test.dart`) collapse to ≤ REST baseline.
Single-agent files remain unchanged.

## References

- Client guard: `lib/core/socket/relay/relay_batch_protocol_guard.dart`
- Client batch coordinator (the pattern to mirror for relay):
  `lib/core/socket/agent_command_batch_coordinator.dart`
- Current single-RPC contract:
  `plug_server/docs/socket_relay_protocol.md`
- Existing `agents:command` batch reference:
  `plug_server/docs/api_rest_bridge.md`
