# Deep investigation: socket/relay `RELAY_REQUEST_TIMEOUT` (2026-07-22)

> **Audience:** Colmeia + hub/ops  
> **Verdict (2026-07-22):** Colmeia wire path reached the hub and received a
> **hub-synthesized** timeout. The agent did **not** answer `rpc:request` on the
> relay path in time. REST to the same agent/SQL worked. This was **not** a
> missing-docs / client envelope bug blocking progress at that time.

## Current state (post documentation sync)

| Topic | Status today |
| --- | --- |
| Envelope `timeoutMs` | **Resolved on hub** — schema accepts the field and the relay timer honours it via `computeBridgeWaitTimeoutMs` (see [`relay_envelope_timeout_ms.md`](./relay_envelope_timeout_ms.md)). Colmeia has sent `timeoutMs` since the handoff; the gap on 2026-07-22 was hub-side only. |
| Unary `fastPath` / JSON-RPC `id` echo | **Resolved on hub** (ADR 0009, Option B). Colmeia default `SOCKET_RELAY_FAST_PATH_ENABLED=true` in `default.env`. Roll back only on hubs that still overwrite `body.id`. |
| Relay batch default | Colmeia bundled `SOCKET_RELAY_BATCH_ENABLED=true` (hub v1 shipped **2026-05-28**). |
| `RELAY_REQUEST_TIMEOUT` smoke on 2026-07-22 | **Historical failure** — evidence below; re-run smoke after hub/agent fixes to confirm resolution. |

The sections below preserve the **2026-07-22 investigation record** unchanged
except where a row is explicitly labelled as historical.

---

## 1. Evidence matrix (state on 2026-07-22)

| Probe | Transport | Path | Result | Wall-clock |
| --- | --- | --- | ---: | ---: |
| Full E2E suite | REST | `POST /agents/commands` | **102/102 pass** | ~2m24s |
| `agent_sql_bridge` (Municipio/Cliente) | REST | legacy bridge | **pass** | ~1s |
| Socket relay smoke (Cliente, pageSize=1) | socket | `relay:rpc.request` | **fail** `RELAY_REQUEST_TIMEOUT` | ~60s |
| Same smoke, `SOCKET_RELAY_FAST_PATH_ENABLED=false` | socket | relay | **fail** same | ~60s |
| Socket **agents:command** A/B (`useRelay: false`) | socket | `agents:command` | **fail** `NOT_FOUND` (agent not found) | **~0.6s** |

Hub identity from `GET /api/v1/health`: `X-Hub-Instance-Id: plug-4000`
(single-process deploy per nginx docs — sticky multi-replica is unlikely here).

### A/B interpretation (2026-07-22 evening)

| Path | Hub signal | Meaning |
| --- | --- | --- |
| REST | success | Agent can run SQL via HTTP bridge |
| `agents:command` | `NOT_FOUND` / agent not found | Consumer socket path does not see the agent (registry / access / dispatch) |
| relay | `RELAY_REQUEST_TIMEOUT` + `conversation_id` | Conversation **starts** (agent id resolved) but no `rpc:response` |

So both socket consumer paths were broken, **in different ways**. REST
working did not prove `/consumers` → agent socket delivery was healthy.

Colmeia now keeps Hybrid selection honest: socket **base** = `agents:command`,
relay only when `useRelay: true`.

### Latest correlation IDs (2026-07-22)

| When | IDs |
| --- | --- |
| Smoke @60s (breadcrumbs) | `conversation_id=130793fb-b2d4-41f6-aed9-0c634fe433e5`, `client_request_id=ff10fcc8-cad0-4c73-8151-1768b81c7612` |
| Smoke @60s (earlier) | `conversation_id=ff788799-19c0-4b5c-9b34-47238d1e64d3` |
| Smoke fastPath off | `conversation_id=997e94e1-2d1c-4f85-95de-5db96d3e67d6` |
| agents:command A/B | fail `NOT_FOUND` in ~564ms (no conversation) |

Agent: `3183a9f2-429b-46d6-a339-3580e5e5cb31`.

Relay breadcrumb (client outcomes stream): wire completed as
`RelayRpcSuccess` with `req=null` after ~60s — the hub **did** return a
frame; the JSON-RPC body is the timeout error. `requestId` null is
consistent with unary `fastPath` (no `accepted`).

## 2. What the failure proved (2026-07-22)

`RELAY_REQUEST_TIMEOUT` is emitted by the **hub** after
`SOCKET_RELAY_REQUEST_TIMEOUT_MS` (or, today, after the effective per-request
wait when `timeoutMs` is set) with no agent `rpc:response`
(`rpc_bridge_dispatch_relay.ts`).

Therefore, on the failing runs:

1. `/consumers` connect + JWT handshake succeeded
2. `relay:conversation.start` succeeded (timeout payload carries `conversation_id`)
3. `relay:rpc.request` was accepted into a pending route and the hub timer armed
4. Colmeia correctly decoded the timeout JSON-RPC and mapped it to `RpcFailure`
5. The agent did **not** complete the request within the hub wait

This was **downstream of Colmeia emit/decode**. Client alignment work
(PayloadFrame, fastPath guard, accepted handling, idle keepalive, docs sync)
did not change this failure mode on that date.

## 3. What we ruled out — client (state on 2026-07-22)

| Hypothesis | Status on 2026-07-22 | Current note |
| --- | --- | --- |
| Missing `prefer_db_streaming` / fastPath+streaming misuse | Ruled out — smoke uses `preferDbStreaming: false`; fail persisted with fastPath off | Still valid |
| Client not sending / not correlating response | Ruled out — hub timeout response arrived with `conversation_id` | Still valid |
| Docs out of date blocking client | Ruled out — `docs/plug_server/socket` synced; remaining gaps were hub schema (`timeoutMs`) / ops | **`timeoutMs` gap closed on hub** — see current-state table |
| Envelope `timeoutMs` extends hub wait | Ruled out **on 2026-07-22** — Zod stripped it; wait was env-only ([`relay_envelope_timeout_ms.md`](./relay_envelope_timeout_ms.md)) | **Superseded** — hub now honours envelope `timeoutMs` |
| Multi-replica sticky miss on `conversation.start` | Unlikely — would be **503** remote-hub, not 60s timeout; hub id was `plug-4000` | Still valid |

## 4. Colmeia architecture note (why “socket” always means relay)

When transport is `socket` and relay is registered
(`injector_agent_queries_transport.dart`):

- `base` datasource for socket = **relay** (not `agents:command`)
- Hybrid still routes `useRelay: true` to relay
- Result: **all Agent SQL over socket goes through relay**

Comment in injector: legacy `agents:command` was bypassed because it hung.
On 2026-07-22 relay also hung at the hub→agent hop. There was no easy A/B of
`agents:command` vs relay without a code escape hatch.

## 5. Most likely root causes — ranked (2026-07-22)

1. **Agent socket unhealthy / not really reachable from `/consumers`**
   - `agents:command` → immediate `NOT_FOUND`
   - relay `conversation.start` still binds an `agentSocketId`, emit is
     fire-and-forget, then hub waits until `RELAY_REQUEST_TIMEOUT`
2. **Hub emits `rpc:request` to a stale agent socket**; agent never replies.
3. **Agent processes but response not matched to relay route** (decode /
   requestId mismatch).
4. **Structural timeout too low for slow SQL** — did **not** explain
   simple `Cliente` smoke at **60s** while REST returned in ~1s, nor the
   agents:command `NOT_FOUND`.

## 6. What hub/ops must check (actionable)

For any of the `conversation_id`s above:

1. Log `relay_request_timeout` — confirm `agentId`, `requestId`, `clientRequestId`
2. Was `rpc:request` emitted to the agent socket? Same `HUB_INSTANCE_ID`?
3. Did the agent log receive / start SQL / finish?
4. Ack retries exhausted? (`socketAgentAck*` metrics)
5. Runtime value of `SOCKET_RELAY_REQUEST_TIMEOUT_MS` and effective per-request
   `timeoutMs` when the client sends it
6. Agent process health (CPU, DB locks) at the timestamp

## 7. What Colmeia can still do (does not replace hub fix)

- Keep sending envelope `timeoutMs` — hub contract is live
  ([`relay_envelope_timeout_ms.md`](./relay_envelope_timeout_ms.md))
- **Done:** socket base channel is `agents:command`; Hybrid selects relay
  only when `useRelay: true` (`injector_agent_queries_transport.dart`)
- **Done:** smoke A/B — relay (`useRelay: true`) vs agents:command
  (`useRelay: false`) with outcome breadcrumbs
- Escape hatch: `E2E_DISABLE_RELAY_DISPATCH=true` skips relay DI so even
  `useRelay: true` cannot open a conversation
- Do **not** treat more client protocol polish as progress on this hang

### A/B commands

```powershell
# Relay path (expect RELAY_REQUEST_TIMEOUT until hub/agent fixed)
flutter test test/integration/e2e/agent_queries_socket_relay_smoke_e2e_test.dart `
  --concurrency=1 `
  --dart-define=AGENT_BRIDGE_TRANSPORT=socket `
  --dart-define=E2E_DISABLE_RELAY_DISPATCH=false `
  --dart-define=E2E_LOG_TRANSIENT=1 `
  --name "relay path"

# agents:command path (same SQL, useRelay:false)
flutter test test/integration/e2e/agent_queries_socket_relay_smoke_e2e_test.dart `
  --concurrency=1 `
  --dart-define=AGENT_BRIDGE_TRANSPORT=socket `
  --dart-define=E2E_DISABLE_RELAY_DISPATCH=false `
  --dart-define=E2E_LOG_TRANSIENT=1 `
  --name "agents:command path"
```

## 8. Acceptance for “socket works”

1. Smoke
   `agent_queries_socket_relay_smoke_e2e_test.dart` with
   `AGENT_BRIDGE_TRANSPORT=socket` returns non-empty rows.
2. Same `conversation_id` (or new) shows agent `rpc:response` in hub logs
   before timeout.

## References

- Smoke: `test/integration/e2e/agent_queries_socket_relay_smoke_e2e_test.dart`
- Injector routing: `lib/core/di/injector_agent_queries_transport.dart`
- Hub timer: `plug_server/.../rpc_bridge_dispatch_relay.ts`
- Prior note: `docs/server_adjustments/relay_request_timeout_vs_client_sql_tiers.md`
- Contract: `docs/plug_server/socket/socket_relay_protocol.md`
