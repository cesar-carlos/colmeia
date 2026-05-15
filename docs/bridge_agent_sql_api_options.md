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
  `relay:rpc.request`.
- Do not send relay notifications (`id: null`); relay requires correlation.

## `sql.execute`

`command.method` is `sql.execute`. `params` contains:

- `sql`: normalized one-line SQL string. Colmeia must remove multiline
  whitespace before sending.
- `params`: named SQL parameters, if any.
- `client_token`: required when the agent enforces client-token policy.
- `options`: execution options.

Common `options`:

- `timeout_ms`: bridge/agent timeout in milliseconds.
- `max_rows`: result guardrail for bounded reports.
- `page`, `page_size`, `cursor`: pagination fields when applicable.
- `execution_mode`: agent-specific execution behavior.
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
- `max_parallel_read_only_batch_items`

Batch item failures are domain results. Bridge/RPC failures still map to
transport or repository failures.

## `payloadFrameCompression`

This field is a bridge policy passed through REST, `agents:command`, or relay
envelopes. It controls how the hub re-encodes frames toward the agent; it does
not change Colmeia's consumer-to-hub PayloadFrame contract.

Allowed values:

- `default`: auto gzip above 4096 bytes only when smaller and within 10x
  inflation guard.
- `none`: never gzip hub-to-agent frames.
- `always`: prefer gzip when eligible, still respecting the 10x guard.

## Socket behavior in Colmeia

- `AGENT_BRIDGE_TRANSPORT=socket` selects socket for agent query transport.
- Streaming-heavy SQL should use relay (`useRelay: true`).
- Colmeia treats `stream_id` from legacy `agents:command_response` as
  `SocketDispatchLegacyStreamingUnsupported`; it does not pull
  `agents:command_stream_*` and does not fallback to REST for that condition.
