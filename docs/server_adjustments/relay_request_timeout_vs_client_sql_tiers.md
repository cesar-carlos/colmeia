# Relay request timeout vs Colmeia SQL bridge tiers

> **Document audience.** This page is for the **`plug_server` hub team** and ops.
> The Colmeia client cannot close this gap unilaterally: the relay envelope
> has no per-request timeout field, while REST accepts `timeoutMs` per call.

## 1. Summary

| Layer | Per-request timeout | Typical value (Colmeia) |
| --- | --- | --- |
| REST `POST /agents/commands` | `timeoutMs` in body | 120000–240000 ms by SQL tier |
| Relay `relay:rpc.request` | **None** — hub uses `SOCKET_RELAY_REQUEST_TIMEOUT_MS` only | Hub default **15000 ms** (documented) |
| Colmeia client timer (relay datasource) | `bridgeTimeoutMs + 5000` | 125000–245000 ms for repository SQL |

Heavy aggregation SQL configured for 2–4 minutes on the client may be cut off
by the hub relay timer at **15 seconds** before the agent finishes. Simple SQL
(`SELECT TOP 10 ... FROM Municipio`) also failed via socket in E2E while the
same flow succeeded via REST in ~17 s, which suggests **infra or dispatch**
issues (sticky session, agent presence, relay path) in addition to the
structural timeout gap.

## 2. Observed symptoms (Colmeia E2E, 2026-07)

**Environment**

- Hub: `https://plug-server.se7esistemassinop.com.br/api/v1`
- Agent: `3183a9f2-429b-46d6-a339-3580e5e5cb31`
- Transport default: `AGENT_BRIDGE_TRANSPORT=socket`
- Login/bearer: OK (`bearer=true` in E2E bootstrap)

**Single test (isolated)**

```powershell
flutter test test/integration/e2e/agent_sql_bridge_e2e_test.dart `
  --concurrency=1 `
  --plain-name "executeSql loads Municipio rows on the legacy bridge" `
  --reporter expanded
```

| Transport | Result | Wall-clock |
| --- | --- | --- |
| socket (default) | **FAIL** — `RELAY_REQUEST_TIMEOUT` | ~15 s |
| REST (`--dart-define=AGENT_BRIDGE_TRANSPORT=rest`) | **PASS** | ~17 s |

**Error shape (socket)**

```text
RpcFailure: Timed out waiting for agent response
rpcCode: -32000
response: { code: RELAY_REQUEST_TIMEOUT, conversation_id: <uuid> }
```

**Full suite** (`flutter test`, all E2E included): 3158 passed, 76 failed — all
failures in `test/integration/e2e/*`, predominantly `RELAY_REQUEST_TIMEOUT`
or 5-minute test timeouts waiting for relay responses.

## 3. Protocol gap (REST vs relay)

Per `plug_server/docs/api/api_rest_bridge.md` and
`socket_relay_protocol.md`, the relay envelope is:

```json
{
  "conversationId": "...",
  "frame": "<PayloadFrame with JSON-RPC command>",
  "payloadFrameCompression": "default",
  "requestServerTimings": false,
  "fastPath": true
}
```

There is **no** `timeoutMs` (or equivalent) on this envelope. Hub arms
`SOCKET_RELAY_REQUEST_TIMEOUT_MS` after dispatch to the agent; on expiry it
emits `relay:rpc.response` with:

```json
{
  "error": {
    "code": -32000,
    "message": "Timed out waiting for agent response",
    "data": { "code": "RELAY_REQUEST_TIMEOUT", "conversation_id": "..." }
  }
}
```

Colmeia repository tiers (`assets/env/default.env` comments, `app_environment.dart`):

| Tier | `bridgeTimeoutMs` | Client relay timer (`+ 5000 ms`) |
| --- | ---: | ---: |
| standard | 120000 | 125000 |
| medium | 180000 | 185000 |
| long | 240000 | 245000 |

The client timer does not extend the hub's 15 s relay wait.

## 4. Conversation IDs for hub log correlation

| conversation_id | Context |
| --- | --- |
| `5c5eb4c2-846d-41c2-b024-7cdc4e2c796e` | Isolated `agent_sql_bridge_execute` |
| `825a7ed0-2476-4eec-b4fb-b6938014e89b` | Socket relay sql.execute smoke |
| `382f4809-916f-47d9-9d5d-944c47a31278` | agent_sql_bridge (execute, pagination, batch) |
| `45e47ea2-179e-4977-881c-83493d9c8e0d` | Overview main batch |
| `a2874895-f252-4daa-ae2a-033e177a9d58` | Overview repository |
| `58cf40c0-2d38-49a8-9499-8f7c7d48c104` | Sales live map batch loader |

## 5. Questions for hub / ops

1. What is the **effective** `SOCKET_RELAY_REQUEST_TIMEOUT_MS` on the
   production hub used by Colmeia? Is it still **15000 ms**?
2. Is a **per-request timeout** on `relay:rpc.request` planned (parity with REST
   `timeoutMs`)? If not, what value should ops use for aggregation SQL up to
   **240 s**?
3. Is **`SOCKET_RELAY_BATCH_ENABLED=true`** on that hub? Colmeia bundled
   default is `true` since 2026-05-28 hub v1.
4. Are **sticky sessions** configured for `/socket.io` (nginx +
   `X-Hub-Instance-Id`)? Relay state is process-local; multi-replica without
   affinity breaks dispatch.
5. For agent `3183a9f2-429b-46d6-a339-3580e5e5cb31`, was the agent socket
   **online and registered** on `/agents` during the failing test window?
6. Does **`connection:ready`** on `/consumers` expose negotiated extensions
   (`clientRequestIdEcho`, `agentPhaseTimings`, `healthPiggyback`) to clients,
   and in what JSON shape?

## 6. Recommended hub actions

| Priority | Action |
| --- | --- |
| High | Confirm or raise `SOCKET_RELAY_REQUEST_TIMEOUT_MS` for SQL workloads, **or** add optional per-request timeout on `relay:rpc.request`. |
| High | Verify sticky session + single-replica relay path for failing `conversation_id`s in logs. |
| Medium | Confirm `SOCKET_RELAY_BATCH_ENABLED` matches Colmeia default. |
| Medium | Expose relay timeout and queue metrics on standard dashboard (`plug_socket_relay_request_timeouts_total`, queue rejections). |

## 7. Colmeia follow-up (conditional)

If the hub keeps a **fixed 15 s** relay cap with no per-request override:

- Consider routing **medium/long** tier SQL via REST (honours `timeoutMs`) while
  keeping unary fast-path relay for light queries — policy change in
  `injector_agent_queries.dart`, not in this document.

No client code change is proposed here until hub answers §5.

## 8. References

- Hub: `plug_server/docs/socket_relay_protocol.md` (relay timeout, envelope)
- Hub: `plug_server/docs/api/api_rest_bridge.md` (REST `timeoutMs`)
- Colmeia: `lib/features/agent_queries/data/datasources/relay_agent_queries_remote_datasource.dart` (`bridgeTimeoutMs + 5000`)
- Colmeia: `assets/env/default.env` (SQL bridge tier comments)
- Related: [`relay_unary_fast_path.md`](relay_unary_fast_path.md) (resolved; separate issue)
