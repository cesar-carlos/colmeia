# Relay JSON-RPC batch — future protocol (hub-first)

Roadmap phase 4. **Not implemented on the hub today.**

## Current state (shipped)

- Hub v1: `relay:rpc.request.batch` (ADR 0008, **2026-05-28**).
- Colmeia: `RelayBatchCommandCoordinator` + `RelayBatchProtocolGuard`; production
  default `SOCKET_RELAY_BATCH_ENABLED=true` in `assets/env/default.env`.

## Colmeia client guard

When `SOCKET_RELAY_BATCH_ENABLED=false`, `RelayBatchProtocolGuard` rejects
multi-item relay batches with `RelayRequestRejected` / `relay_batch_not_supported`.
Unary relay (`itemCount <= 1`) is always allowed.

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
