# plug_server documentation — map for Colmeia

Colmeia integrates with the Plug hub (`plug_server`) and agents (`plug_agente`) for SQL reports and multi-agent orchestration. This note maps **plug_server/docs** so we know where to look without duplicating the full spec.

**Canonical navigation** inside plug_server (from `docs/README.md`):

1. `client_agent_business_rules.md` — ownership, Client→Agent approval, auth
2. `api_rest_bridge.md` — REST + legacy `agents:*` contract
3. `socket_relay_protocol.md` — relay `relay:*` on `/consumers`
4. `configuration.md` + `src/shared/config/env.ts` — env defaults

OpenAPI: `GET /docs` and `GET /docs.json` on the hub.

---

## High-value documents for Colmeia

| plug_server doc                          | Why it matters for Colmeia                                                                                                                                                                                                                           |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`api_rest_bridge.md`**                 | `POST /api/v1/agents/commands`, `sql.execute` / `sql.executeBatch`, pagination, `multi_result`, `execution_mode` / `preserve`, timeouts, body limits, error RPC catalog, REST stream **materialization** (single JSON), overload / 503 behaviour.    |
| **`socket_relay_protocol.md`**           | Relay supports the same RPC methods as the bridge validator; **no JSON-RPC batch array** on relay — one request per `relay:rpc.request`. Notifications with `id: null` are **not** accepted on relay. `PayloadFrame`, gzip, `relay:rpc.stream.pull`. |
| **`socket_client_sdk.md`**               | Minimal consumer guide; points to `api_rest_bridge` for method catalog; `agents:command` body (`command` object **or** batch up to 32, `pagination` only for single `sql.execute`).                                                                  |
| **`client_agent_business_rules.md`**     | **Client** principal, `client_token`, access requests, approval, revocation, `client:agent.profile.updated` push — aligns with Colmeia client-agent flows and E2E assumptions.                                                                       |
| **`PROJECT_OVERVIEW.md`**                | Roles (hub / agent / consumer / client), channels REST vs `/consumers`, when to prefer Socket over REST for large or streaming workloads.                                                                                                            |
| **`communication_sync_plug_agente.md`**  | Alignment checklist with **plug_agente** (schemas, OpenRPC, `execution_mode`, capabilities, contract tests `npm run test:contract`). Use when upgrading agent or hub versions.                                                                       |
| **`configuration.md`**                   | Env vars: REST stream materialization window, audit batching, Socket buffers, `PAYLOAD_FRAME_*`, agent protocol ready grace — useful for ops and performance tuning.                                                                                 |
| **`performance_hub_agent.md`**           | Presets and guidance: REST materialization cost, relay throughput, when HTTP is a bottleneck; links to benchmark doc.                                                                                                                                |
| **`scaling_and_roadmap.md`**             | **Multi-instance** caveats (in-memory correlation per process), no progressive REST streaming yet, future Redis/OTel — relevant if Colmeia scales hub horizontally.                                                                                  |
| **`observability.md`**                   | Metrics, logging, contract tests — for debugging bridge/agent issues from Colmeia.                                                                                                                                                                   |
| **`user_status.md`**                     | `User` / `Client` **blocked** behaviour on HTTP and Socket (handshake / revalidation) — relevant if Colmeia handles auth errors after connect.                                                                                                       |
| **`migracao_plug_agente_namespaces.md`** | Namespace migration notes if touching `/agents` vs legacy paths.                                                                                                                                                                                     |
| **`nginx_production.md`**                | Reverse proxy, body sizes, WebSocket — deployment reference.                                                                                                                                                                                         |

---

## plug_agente (sibling repo)

plug_server points to **plug_agente** for normative wire format:

- `plug_agente/docs/communication/socket_communication_standard.md`
- `plug_agente/docs/communication/schemas/`
- `plug_agente/docs/communication/openrpc.json`

Colmeia’s SQL payload rules live in `.cursor/rules/project_agent_sql.mdc`; they must stay consistent with whatever the agent validates (policies, `preserve`, named params).

---

## Practical rules of thumb

- **Large result sets or low latency:** prefer **Socket** (relay or `agents:*`); REST aggregates `stream_id` into one response and can hit materialization limits (**503** — see `api_rest_bridge.md` / `performance_hub_agent.md`).
- **Multiple unrelated SQL calls:** use **HTTP** JSON-RPC **batch** (array `command`, max 32) or **`sql.executeBatch`** — not **`multi_result`**. Field-level comparison table: `docs/bridge_agent_sql_api_options.md`.
- **Relay:** one correlated RPC per `relay:rpc.request`; validate payload size limits (same UTF-8 caps as REST for `sql` / `params`).
- **Client token + policy:** `client_token.getPolicy` is documented in `api_rest_bridge.md`; required when the agent enables client-token authorization.

---

## Maintenance

When the hub contract changes, update:

1. This index (if new docs or behaviour affect Colmeia).
2. `docs/bridge_agent_sql_api_options.md` (SQL-specific options).
3. Colmeia code and `.cursor/rules` only after verifying plug_server + plug_agente sources of truth.
