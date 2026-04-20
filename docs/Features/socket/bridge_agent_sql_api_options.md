# Agent bridge — SQL API options (reference)

This note summarizes how the **plug_server** REST/socket bridge exposes SQL execution modes relevant to Colmeia agent queries. The **normative** specification lives in the plug_server repository:

- `plug_server/docs/api_rest_bridge.md`
- Relay/socket context: `plug_server/docs/socket_relay_protocol.md`, `plug_server/docs/socket_client_sdk.md`

For a broader map of all plug_server docs relevant to Colmeia (business rules, scaling, performance), see **`docs/plug_server_docs_index_for_colmeia.md`**.

HTTP and socket consumer commands share the same internal pipeline (`executeAgentCommand` → agent dispatch).

---

## `sql.execute` — `options` (excerpt)

| Field | Role |
| ----- | ---- |
| `timeout_ms` | Agent-side SQL timeout (1..300000 ms). |
| `max_rows` | Cap on returned rows (negotiated with agent capabilities). |
| `page` / `page_size` | Offset pagination (1-based page; requires both). |
| `cursor` | Keyset continuation token (exclusive with `page` / `page_size`). |
| `execution_mode` | `managed` (default, allows rewrite for pagination) or `preserve` (SQL sent as-is; **not** combinable with pagination options). |
| `preserve_sql` | Legacy boolean alias for `execution_mode: preserve`. |
| `multi_result` | Return **multiple result sets** from **one** SQL string; **not** combinable with pagination or named `params`. |

**Pagination rules (contract):** with `page`+`page_size` or `cursor`, SQL must include an explicit **`ORDER BY`** (stable ordering for offset/keyset).

**Body-level pagination:** `POST` body may include `pagination: { page, pageSize }` or `pagination: { cursor }`, which overrides `command.params.options` when both define pagination.

---

## `multi_result` (multiple result sets in a single `sql.execute`)

- Set `options.multi_result: true`.
- Use one SQL batch with several statements (e.g. `SELECT ...; SELECT COUNT(*) ...`).
- **Incompatible with:** named `params`, `page`/`page_size`, and `cursor`.
- Response shape (when active) includes fields such as: `multi_result`, `result_set_count`, `item_count`, `result_sets[]`, and `items[]` (per result set).

Use this when the database/driver returns multiple grids for one round-trip—not for running unrelated business queries (prefer batch below).

---

## `sql.executeBatch` (sequential multi-command)

- Method: `sql.executeBatch`.
- `params.commands[]`: each entry has `sql`, optional `params`, optional `execution_order`.
- `params.options`: `timeout_ms`, `max_rows` (per command), `transaction` (single transaction wrapping commands).
- Response: `items[]` per command (`index`, `ok`, `rows`, `row_count`, `error`, …), plus `total_commands`, `successful_commands`, `failed_commands`.

This is the **semantic** batch API on the agent (ordered SQL list), distinct from JSON-RPC batching (below).

---

## Native JSON-RPC batch (`command` as array)

- `command` may be an **array** of up to **32** JSON-RPC requests (not only `sql.execute`).
- Rules for `id`, notifications (`id: null`), HTTP 200 vs 202, and socket `agents:command_response` are defined in `api_rest_bridge.md` (section *Batch JSON-RPC nativo*).
- Optional `pagination` on the body applies only to a **single** `sql.execute` command, not to the whole array.

This is **several RPC calls in one POST**, not the same as `multi_result`.

---

## Quick comparison

| Mechanism | What it does |
| --------- | ------------ |
| `multi_result` | One `sql.execute`, multiple **result sets** from one SQL text. |
| `sql.executeBatch` | Multiple **SQL commands** in order; structured `items[]` results. |
| JSON-RPC batch array | Up to 32 independent RPC requests in one bridge command. |
| Pagination (`page`/`cursor`) | Chunks **one** query’s rows; requires `ORDER BY`; conflicts with `preserve` + pagination and with `multi_result`. |

---

## Colmeia usage note

See also **`docs/plug_server_docs_index_for_colmeia.md`** (REST vs socket, relay limits, when to batch).

Colmeia report repos usually call **`sql.execute`** with **`execution_mode: preserve`** and named parameters (`project_agent_sql.mdc`). Bounded aggregate queries may set **`max_rows`** via `AgentQueriesBoundedResultMaxRows` as a safety cap. Anything needing **`multi_result`**, **`sql.executeBatch`**, or JSON-RPC batching must be designed against the plug_server schema and agent policy.
