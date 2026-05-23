# Relay JSON-RPC batch — future protocol (hub-first)

Roadmap phase 4. **Not implemented on the hub today.**

## Current state

- `relay:rpc.request` accepts **one** JSON-RPC object per frame.
- Batch arrays up to 32 RPCs are supported on **`agents:command`** and REST
  bridge only (`docs/plug_server_docs_index_for_colmeia.md`).

## Colmeia client guard

When `SOCKET_RELAY_BATCH_ENABLED=false` (default), `RelayBatchProtocolGuard`
rejects client attempts to send multi-item relay batches with
`RelayRequestRejected` / `relay_batch_not_supported`.

Enable the flag only after hub + agent implement the spec below.

## Proposed hub spec (draft)

1. New optional field on `relay:rpc.request` or a dedicated event
   `relay:rpc.request.batch` with `items: [{ client_request_id, command }]`.
2. Hard cap (e.g. 32) matching `agents:command` batch limits.
3. Per-item correlation on `relay:rpc.response` / stream events.
4. Backpressure: batch size counted against per-agent concurrency gate.
5. Partial failure: each item succeeds or fails independently.

## Client follow-up after hub ships

- Extend `RelayCommandDispatcherImpl` with opt-in batch emit.
- Feature-flag rollout via `SOCKET_RELAY_BATCH_ENABLED`.
- E2E suite with mixed unary + streaming items.
