# Bridge Agent SQL API options

This is the Colmeia-facing summary for SQL bridge payloads. The normative
contract lives in `plug_server/docs/api_rest_bridge.md`.

## Shared command envelope

REST `POST /api/v1/agents/commands` and socket `agents:command` use the same
top-level body:

```json
{
  "agentId": "agent-id",
  "command": {
    "jsonrpc": "2.0",
    "method": "sql.execute",
    "id": "client-rpc-id",
    "api_version": "2.10",
    "params": {}
  },
  "timeoutMs": 30000,
  "pagination": null,
  "payloadFrameCompression": "default"
}
```

- `agentId` is required.
- `command` can be a single JSON-RPC object on REST/`agents:command`.
- REST/`agents:command` may support JSON-RPC batch arrays; relay does not.
- Relay sends one JSON-RPC command inside the PayloadFrame for
  `relay:rpc.request`. Do not wrap it in the REST top-level body; the decoded
  frame starts at `{ "jsonrpc": "2.0", "method": "...", "id": ..., "params": ... }`.
- Do not send relay notifications (`id: null`); relay requires correlation.
- Relay responses are forwarded as JSON-RPC (`result` or `error`) inside
  `relay:rpc.response`; Colmeia adapts that response to the local bridge
  envelope before invoking `AgentSqlBridgeResponse`.
- In Colmeia, `useRelay: true` selects the relay transport. `relayMode`
  selects unary vs streaming for `sql.execute`; the default is unary.
- Colmeia defaults to `api_version: "2.10"` for `sql.execute` and
  `sql.executeBatch`. Override per request only for a known legacy agent.

## `sql.execute`

`command.method` is `sql.execute`. `params` contains:

- `sql`: normalized one-line SQL string. Colmeia must remove multiline
  whitespace before sending.
- `params`: named SQL parameters, if any.
- `client_token`: required when the agent enforces client-token policy.
- `options`: execution options.

Common `options`:

- `timeout_ms`: bridge/agent timeout in milliseconds.
- `max_rows`: result guardrail for bounded reports. The cadastro filial
  catalog uses the same cap as `CadastroFilialFilter.maxPageSize` (500) per
  `sql.execute` so `loadAll` across agents paginates in larger chunks.
- `page`, `page_size`, `cursor`: pagination fields when applicable.
- `execution_mode`: agent-specific execution behavior.
- `prefer_db_streaming`: bridge hint for DB-side streaming when the agent
  supports it; Colmeia enables it on large report/chart relay streaming
  queries.
- `multi_result`: only when the agent method explicitly supports it.

Top-level `pagination` belongs to REST/`agents:command` single `sql.execute`;
relay does not use the top-level REST pagination envelope.

## `sql.executeBatch`

`command.method` is `sql.executeBatch`. `params` contains:

- `commands`: ordered list of SQL commands.
- `commands[].sql`: normalized one-line SQL string.
- `commands[].params`: named SQL parameters, if any.
- `commands[].execution_order`: when required by the caller.
- `client_token`: required when policy is enabled.
- `options`: batch-level controls.

Common batch `options`:

- `timeout_ms`
- `max_rows`
- `transaction`
- `max_parallel_read_only_batch_items`: positive integer. Colmeia starts
  overview read-only batches at `4`; the agent keeps the final safety cap.

Batch item failures are domain results. Bridge/RPC failures still map to
transport or repository failures.

Repository audit (REST): overview and filter-options paths already use
`sql.executeBatch` where independent read-only statements share one round-trip.
Remaining `AgentSqlRepositoryExecution.execute` call sites are single-query
loads or relay streaming screens where batching does not apply without a
product change.

## Choosing batch vs `multi_result` vs JSON-RPC batch

| Mechanism | What it does | Colmeia overview |
|-----------|--------------|------------------|
| `sql.executeBatch` | Multiple `commands[]`, each with its own `params`; optional `max_parallel_read_only_batch_items` for read-only parallelism (see `plug_server/docs/snippets/agent_command_performance_options.ts`). | Main batch runs **forma pagamento** + **per-user** resumo (`OverviewBatchLoader`); section batch runs monthly/weekday/daily/etc. Filter-options and moving-average screens batch independent `sql.execute` calls where the hub allows read-only batching. |
| `multi_result` | Single `sql.execute`, one SQL string with multiple statements; **cannot** be combined with named `params` or pagination (`plug_server/docs/api_rest_bridge.md`). | **Not used** for overview (all resumo queries use `:named` binds). |
| JSON-RPC `command: []` | Up to 32 independent RPC objects in one REST body. | Not used for overview batch; relay intentionally accepts a single correlatable RPC per frame. |

## `payloadFrameCompression`

This field is a bridge policy passed through REST/`agents:command` bodies or
the `relay:rpc.request` envelope. It controls how the hub re-encodes frames
toward the agent; it does not change Colmeia's consumer-to-hub PayloadFrame
contract.

Allowed values:

- `default`: auto gzip above 4096 bytes only when smaller and within 10x
  inflation guard.
- `none`: never gzip hub-to-agent frames.
- `always`: prefer gzip when eligible, still respecting the 10x guard.

## Socket behavior in Colmeia

- `AGENT_BRIDGE_TRANSPORT=socket` selects socket for agent query transport.
- Relay SQL should set `useRelay: true`; streaming-heavy SQL must also set
  `relayMode: streaming`. Plain `useRelay: true` uses relay unary by default.
- Rollout policy: large report/chart queries use relay streaming with
  `options.prefer_db_streaming: true`; lookup/options queries stay relay unary
  to avoid streaming overhead on small payloads.
- Overview read-only `sql.executeBatch` calls set
  `options.max_parallel_read_only_batch_items: 4`.
- Local performance knobs:
  - `AGENT_SQL_CACHE_TTL_MS` defaults to `3000`; use `0` to effectively
    disable cross-call reuse while preserving coalescing and the repository
    chain shape.
  - `AGENT_SQL_OVERVIEW_BATCH_MAX_PARALLEL_READ_ONLY_ITEMS` defaults to `4`;
    raise cautiously when the target agent and database have spare read
    capacity.
  - `AGENT_SQL_RELAY_STREAMING_MAX_CONCURRENT_PER_AGENT` defaults to `4`;
    reduce to `1` for fragile hubs/DBs, and validate changes with the E2E
    comparator before increasing further.
  - `AGENT_SQL_REST_MAX_INFLIGHT_PER_AGENT` defaults to `8` on REST (per-agent
    cap on concurrent `POST .../agents/commands`); set `0` to disable.
- **SQL cache counters (diagnostics):** `CachingAgentQueriesRepository` exposes
  `cacheHits`, `cacheMisses`, `batchCacheHits`, `batchCacheMisses`, and
  `cacheSize` for tests and ad-hoc inspection. Production observability should
  pair those with `MetricsAgentQueriesRepository` timings and hub-side rate
  limits rather than expecting a separate in-app export job.
- `meta.outbound_compression` is not the primary tuning knob today; the
  current server runtime documents it as a no-op for response compression.
- Colmeia treats `stream_id` from legacy `agents:command_response` as
  `SocketDispatchLegacyStreamingUnsupported`; it does not pull
  `agents:command_stream_*` and does not fallback to REST for that condition.

## Measuring REST vs socket

Use `tool/compare_e2e_transports.py` for repeatable local measurements. Per-file
mode isolates slow tests; suite mode measures the full stack with one Flutter
test process and better captures socket session reuse:

```powershell
python tool/compare_e2e_transports.py --scope suite --timeout-seconds 180
```
