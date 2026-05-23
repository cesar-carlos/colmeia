# sql.cancel — Colmeia contract map (streaming vs unary)

This document closes roadmap phase 2A for the **Colmeia client**. Hub and
agent semantics remain authoritative in `plug_server/docs/api_rest_bridge.md`
and `plug_server/docs/socket_relay_protocol.md`.

## Transport paths

| Path | Client cancel behaviour | Hub / agent |
| --- | --- | --- |
| Relay unary (`relay:rpc.request`) | Fail-fast via `RelayCommandDispatcher.cancel` — pending completers reject locally; hub may still finish work | No guaranteed agent-side abort for unary |
| Relay streaming | Fail-fast + `trackStreamingSql` → best-effort `sql.cancel` on `agents:command` when scope is abandoned | Hub honours `sql.cancel` for open `stream_id` when agent supports it |
| Legacy `agents:command` unary | Fail-fast via `SocketCommandDispatcher.cancel` | Client-side only unless hub forwards cancel (not assumed) |
| Legacy streaming (if used) | Same as relay streaming row | Same |

## Colmeia wiring

- `AgentQueriesCancelScope.cancelAll()` invokes, in order:
  1. `relayCancelHandler` → `RelayCommandDispatcher.cancel`
  2. `socketRpcCancelHandler` → `SocketCommandDispatcher.cancel`
  3. `streamingSqlCancelHandler` → `AgentSqlCancelEmitter.cancelStream` (`sql.cancel` body)
- DI: `wireAgentQueriesCancelScopeHandlers` in `injector_agent_queries.dart`
- Streaming ids are registered when the first relay chunk exposes `stream_id`
  (`relay_streaming_agent_queries_remote_datasource.dart`).

## Expectations for product / QA

- **Navigation away from a streaming SQL screen** should stop UI waiters immediately
  and emit `sql.cancel` when a stream id was captured.
- **Unary dashboard loads** must not assume the agent stops SQL — only that the
  client no longer waits on the response.
- Batch coordinator bypasses coalescing for `sql.cancel` (latency-critical).

## Open hub work (cross-repo)

- Document unary `sql.cancel` as explicitly unsupported or best-effort in
  `plug_server` if product requires agent abort for long-running unary queries.
- Contract tests in plug_agente for `stream_id` cancellation paths.
