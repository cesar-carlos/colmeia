# Hub: accept `timeoutMs` on the `relay:rpc.request` envelope

> **Audience:** `plug_server`  
> **Status:** **resolved** — hub schema and timer honour envelope `timeoutMs`
> (validated in `plug_server` around commit/support rollout; Colmeia already
> sends the field)  
> **Priority:** medium (REST parity; long SQL on relay)

## Current state

The hub accepts optional `timeoutMs` on `relay:rpc.request` and
`relay:rpc.request.batch` envelopes. The relay route timer uses
`computeBridgeWaitTimeoutMs(command, timeoutMs ?? SOCKET_RELAY_REQUEST_TIMEOUT_MS)`,
matching REST / `agents:command` parity.

Colmeia sends `timeoutMs` = `bridgeTimeoutMs` on unary, streaming, and batch
relay emits. The consumer dispatcher timer remains independent.

**Validation note:** behaviour was confirmed in `plug_server` (Zod schema +
`rpc_bridge_dispatch_relay.ts` timer wiring) during the commit/support window
that closed this handoff. Re-run the acceptance checks below when upgrading
hub builds.

## Original problem (historical)

On **2026-07-22** the relay envelope schema did **not** declare `timeoutMs`.
Unknown fields were stripped and the wait was always
`SOCKET_RELAY_REQUEST_TIMEOUT_MS` (`rpc_bridge_dispatch_relay.ts`). SQL longer
than the env default failed with `RELAY_REQUEST_TIMEOUT` even when the client
sent a higher `bridgeTimeoutMs`.

## Original request (historical)

1. Add to `relay:rpc.request` and `relay:rpc.request.batch` envelopes:

```ts
timeoutMs: z.number().int().positive().max(360_000).optional()
```

(ceiling aligned with REST: `AGENT_TIMEOUT_MS_LIMIT + 60000`).

2. Propagate to the route timer:

```text
effective = computeBridgeWaitTimeoutMs(command, timeoutMs ?? SOCKET_RELAY_REQUEST_TIMEOUT_MS)
```

3. On batch, the same envelope `timeoutMs` applies to each item (or document
   per-item max if preferred).

4. Document in `docs/socket/socket_relay_protocol.md` and
   `docs/socket/socket_client_sdk.md` (envelope opt-in section).

5. On timeout: keep `error.data.code = RELAY_REQUEST_TIMEOUT` + log
   `relay_request_timeout` with `conversationId` / `requestId` /
   `clientRequestId`.

## Acceptance criteria

1. Envelope with `timeoutMs: 60000` makes the hub wait ~60s (not the env
   default) before `RELAY_REQUEST_TIMEOUT`.
2. Without `timeoutMs`, behaviour falls back to the env default.
3. Socket docs and Zod schema reject invalid values with
   `VALIDATION_ERROR` / `BAD_REQUEST` on `relay:rpc.accepted`.

## References

- Schema: `src/presentation/socket/consumers/relay_rpc_request.handler.ts`
- Batch: `src/presentation/socket/consumers/relay_rpc_request_batch.handler.ts`
- Timer: `src/presentation/socket/hub/relay/rpc_bridge_dispatch_relay.ts`
- REST parity: `computeBridgeWaitTimeoutMs` in `command_transformers.ts`
- Related smoke: [`relay_request_timeout_socket_smoke_2026_07_22.md`](./relay_request_timeout_socket_smoke_2026_07_22.md)
