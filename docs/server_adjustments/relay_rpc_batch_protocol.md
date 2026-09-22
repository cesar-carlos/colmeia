# Relay JSON-RPC batch — Colmeia ↔ hub alignment

> This is a client integration note, not the hub specification. The normative
> protocol remains `plug_server/docs/socket/socket_relay_protocol.md` and ADR 0008 in
> the hub repository.

## Current state

`relay:rpc.request.batch` shipped in hub v1 on 2026-05-28. Colmeia sends it
through `RelayBatchCommandCoordinator` and
`RelayCommandDispatcherImpl.sendBatch` when `SOCKET_RELAY_BATCH_ENABLED` is
enabled.

The bundled client environment enables the client-side flag; the code fallback
is `false` for unknown environments. The hub advertises the effective batch
configuration at `connection:ready.relay.batch`. When that capability is
disabled, Colmeia bypasses automatic envelopes and uses relay unary. Legacy
hubs that omit it remain compatible through a session-local fallback after
`RELAY_BATCH_DISABLED`. With the local flag off,
`RelayBatchProtocolGuard` rejects an explicit multi-item batch before it is
emitted. Unary relay remains available regardless of the flag.

## Client-visible contract

- A batch carries at most the lower of the protocol cap (32), the local gate,
  and `connection:ready.relay.batch.maxItems`, and is correlated by each
  original client request ID. A late `BATCH_TOO_LARGE.details.maxItems` is
  learned and retried once in smaller chunks.
- Colmeia automatically batches only eligible unary requests for the same
  agent. It accepts both direct relay JSON-RPC bodies and legacy bridge
  envelopes during eligibility inspection.
- Streaming requests, `prefer_db_streaming`, `sql.executeBatch`, `sql.cancel`,
  and `multi_result` bypass automatic batching. They retain their specialised
  semantics and must not be delayed behind a batch window.
- A partial item failure is isolated to that item. A batch-level transport or
  protocol failure fails the pending batch items.
- On a `RATE_LIMITED` rejection that provides a positive `availableSlots`, the
  client splits the batch once into chunks of that size. Further rejection is
  returned to the caller.

Hub batch v2 propagates envelope-level `requestServerTimings` and `fastPath`
to every item. Colmeia emits `fastPath` for eligible unary batches when its
local client opt-in is enabled; streaming-capable items always bypass batching.

## Operational constraints

- Relay conversations require sticky sessions. All batch requests for an open
  conversation must return to the replica that owns it.
- Relay batch is a unary optimisation. It does not replace agent-level
  `sql.executeBatch`, JSON-RPC `agents:command` batch, or relay streaming.
- `sql.cancel` is intentionally sent outside automatic batching. It is still
  best-effort and only applies to a known streaming `stream_id`; see
  [`../Features/socket/sql_cancel_contract_colmeia_map.md`](../Features/socket/sql_cancel_contract_colmeia_map.md).
- `fastPath` remains a separate compatibility concern: the hub must preserve
  the client JSON-RPC ID for concurrent relay requests.

## Rollout checks

1. Confirm `connection:ready.relay.batch` advertises the expected `enabled`
   and `maxItems` values and that sticky relay conversations are configured.
2. Enable `SOCKET_RELAY_BATCH_ENABLED` in staging and compare unary relay
   latency, batch emissions, bypass reasons, and rate-limit rejections against
   the baseline.
3. Verify that streaming SQL continues to use `relay:rpc.stream.pull` rather
   than entering a batch envelope.
4. For an older hub that omits capability advertisement, verify that a
   `RELAY_BATCH_DISABLED` response latches automatic batching to unary for the
   session. Relay unary and the existing REST fallback remain valid rollback
   paths.

## References

- [Colmeia relay batch note](../Features/socket/relay_batch_future_spec.md)
- [Colmeia SQL transport summary](../bridge_agent_sql_api_options.md)
- `plug_server/docs/socket/socket_relay_protocol.md`
- `plug_server/docs/adrs/0008-relay-batch-protocol.md`
