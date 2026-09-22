# Relay JSON-RPC batch

> This file retains its historic name for existing links. Relay batch is no
> longer a future proposal: hub v1 shipped `relay:rpc.request.batch` on
> 2026-05-28 (ADR 0008), and Colmeia implements the client coordinator.

The hub contract in `plug_server/docs/socket/socket_relay_protocol.md` remains
authoritative. This page records the Colmeia-side routing and rollout rules.

## Availability and configuration

- `SOCKET_RELAY_BATCH_ENABLED=true` enables automatic relay batching. The
  bundled `default.env` enables it; the code fallback is `false` so unknown
  environments remain conservative.
- The effective hub capability is announced by
  `connection:ready.relay.batch.{enabled,maxItems}`. Colmeia bypasses to unary
  when `enabled` is false and limits automatic envelopes to the announced cap.
  A legacy hub that omits the field remains supported through the
  `RELAY_BATCH_DISABLED` unary fallback.
- `RelayBatchProtocolGuard` rejects an explicit multi-item batch when the flag
  is off with `relay_batch_not_supported`. A unary relay request remains valid.
- Hub batch capacity is configurable up to 32 items. Colmeia also caps an
  automatic batch by the announced hub cap and the configured per-agent
  inflight limit when either is lower.
- `requestServerTimings` and `fastPath` propagate to every batch item. The
  client emits `fastPath` for eligible batches only when its local opt-in is
  enabled; the hub still emits one batch acknowledgement.

## Client routing

`RelayBatchCommandCoordinator` collects eligible `sendUnary` calls for the
same agent in a short window (currently 8 ms) and submits one
`relay:rpc.request.batch` through `RelayCommandDispatcherImpl.sendBatch`.
Routing accepts both the direct JSON-RPC body used by relay SQL and the legacy
bridge envelope with `command`, so the eligibility decision is based on the
real RPC method and parameters.

The following requests deliberately bypass automatic relay batching:

- `sendStreaming` and any `prefer_db_streaming` request;
- `sql.executeBatch`, because it is already a semantic agent batch;
- `sql.cancel`, because it is latency-sensitive;
- `multi_result`, because it is multi-statement; and
- unrecognised RPC body shapes.

An explicit `sendBatch` is passed directly to the dispatcher because the caller
already owns the grouping.

## Failure, cancellation, and limits

- Responses are correlated to their original client request IDs. Partial item
  failures do not fail unrelated items.
- When the hub reports `RATE_LIMITED` with a positive `availableSlots` value,
  or `BATCH_TOO_LARGE` with `details.maxItems`, the coordinator splits the
  logical batch once into chunks of that size. A second rejection, zero slots,
  or another transport error is propagated.
- Cancelling an item while it is queued removes that local item before emission.
  Dispatcher cancellation remains the authoritative path once an item has been
  handed to the relay layer.
- Relay batch is unary-only in v1. A streaming query must retain its own pull,
  cancellation, and SQL `stream_id` lifecycle; see
  [`sql_cancel_contract_colmeia_map.md`](sql_cancel_contract_colmeia_map.md).

## Rollout checklist

1. Confirm the target hub supports ADR 0008 and sticky sessions for relay
   conversations.
2. Enable `SOCKET_RELAY_BATCH_ENABLED` in staging and compare socket metrics:
   relay batch emissions, bypass reasons, rate-limit rejections, and request
   latency against the unary baseline.
3. Keep the feature off for a hub that does not support the event; unary relay
   and REST fallback remain available.
4. Treat `fastPath` as a separate hub compatibility decision. It must preserve
   the client JSON-RPC ID for concurrent relay requests.

## References

- [Colmeia SQL transport summary](../../bridge_agent_sql_api_options.md)
- [SQL cancellation map](sql_cancel_contract_colmeia_map.md)
- [Hub alignment notes](../../server_adjustments/relay_rpc_batch_protocol.md)
- `plug_server/docs/adrs/0008-relay-batch-protocol.md`
