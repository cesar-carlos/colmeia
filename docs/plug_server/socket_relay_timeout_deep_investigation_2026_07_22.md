# Deep investigation: socket/relay `RELAY_REQUEST_TIMEOUT` (2026-07-22)

> **Audience:** Colmeia + hub/ops  
> **Verdict:** Colmeia wire path reaches the hub and receives a **hub-synthesized**
> timeout. The agent does **not** answer `rpc:request` on the relay path in time.
> REST to the same agent/SQL works. This is **not** a missing-docs / client
> envelope bug blocking progress anymore.

## 1. Evidence matrix (today)

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

So both socket consumer paths are broken, **in different ways**. REST
working does not prove `/consumers` → agent socket delivery is healthy.

Colmeia now keeps Hybrid selection honest: socket **base** = `agents:command`,
relay only when `useRelay: true`.

### Latest correlation IDs

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

## 2. What the failure proves

`RELAY_REQUEST_TIMEOUT` is emitted by the **hub** after
`SOCKET_RELAY_REQUEST_TIMEOUT_MS` with no agent `rpc:response`
(`rpc_bridge_dispatch_relay.ts`).

Therefore, on the failing runs:

1. `/consumers` connect + JWT handshake succeeded
2. `relay:conversation.start` succeeded (timeout payload carries `conversation_id`)
3. `relay:rpc.request` was accepted into a pending route and the hub timer armed
4. Colmeia correctly decoded the timeout JSON-RPC and mapped it to `RpcFailure`
5. The agent did **not** complete the request within the hub wait

This is **downstream of Colmeia emit/decode**. Client alignment work
(PayloadFrame, fastPath guard, accepted handling, idle keepalive, docs sync)
does not change this failure mode.

## 3. What we ruled out (client)

| Hypothesis | Status |
| --- | --- |
| Missing `prefer_db_streaming` / fastPath+streaming misuse | Ruled out — smoke uses `preferDbStreaming: false`; fail persists with fastPath off |
| Client not sending / not correlating response | Ruled out — hub timeout response arrives with `conversation_id` |
| Docs out of date blocking client | Ruled out — `docs/plug_server/socket` synced; remaining gaps are hub schema (`timeoutMs`) / ops |
| Envelope `timeoutMs` extends hub wait | Ruled out — Zod strips it; wait is env-only ([`relay_envelope_timeout_ms.md`](./relay_envelope_timeout_ms.md)) |
| Multi-replica sticky miss on `conversation.start` | Unlikely — would be **503** remote-hub, not 60s timeout; hub id is `plug-4000` |

## 4. Colmeia architecture note (why “socket” always means relay)

When transport is `socket` and relay is registered
(`injector_agent_queries_transport.dart`):

- `base` datasource for socket = **relay** (not `agents:command`)
- Hybrid still routes `useRelay: true` to relay
- Result: **all Agent SQL over socket goes through relay**

Comment in injector: legacy `agents:command` was bypassed because it hung.
Today relay also hangs at the hub→agent hop. There is no easy A/B of
`agents:command` vs relay without a code escape hatch.

## 5. Most likely root causes (ranked)

1. **Agent socket unhealthy / not really reachable from `/consumers`**
   - `agents:command` → immediate `NOT_FOUND`
   - relay `conversation.start` still binds an `agentSocketId`, emit is
     fire-and-forget, then hub waits until `RELAY_REQUEST_TIMEOUT`
2. **Hub emits `rpc:request` to a stale agent socket**; agent never replies.
3. **Agent processes but response not matched to relay route** (decode /
   requestId mismatch).
4. **Structural timeout too low for slow SQL** — does **not** explain
   simple `Cliente` smoke at **60s** while REST returns in ~1s, nor the
   agents:command `NOT_FOUND`.

## 6. What hub/ops must check (actionable)

For any of the `conversation_id`s above:

1. Log `relay_request_timeout` — confirm `agentId`, `requestId`, `clientRequestId`
2. Was `rpc:request` emitted to the agent socket? Same `HUB_INSTANCE_ID`?
3. Did the agent log receive / start SQL / finish?
4. Ack retries exhausted? (`socketAgentAck*` metrics)
5. Runtime value of `SOCKET_RELAY_REQUEST_TIMEOUT_MS`
6. Agent process health (CPU, DB locks) at the timestamp

## 7. What Colmeia can still do (does not replace hub fix)

- Keep sending envelope `timeoutMs` (forward-compat) + handoff
  [`relay_envelope_timeout_ms.md`](./relay_envelope_timeout_ms.md)
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
