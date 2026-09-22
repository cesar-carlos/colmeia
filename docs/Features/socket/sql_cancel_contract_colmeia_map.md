# SQL cancellation — Colmeia contract map

This document describes the Colmeia client behaviour. The hub and agent
semantics remain authoritative in `plug_server/docs/api_rest_bridge.md` and
`plug_server/docs/socket_relay_protocol.md`.

`sql.cancel` is a best-effort request to stop **known streaming SQL work**. It
does not turn unary RPC cancellation into a guaranteed server-side abort.

## Transport paths

| Path | Local cancellation | Remote SQL cancellation |
| --- | --- | --- |
| Relay unary (`relay:rpc.request`) | `RelayCommandDispatcher.cancel` fails the local waiter. The hub or agent can still finish the unary work. | Not available: there is no `stream_id`. |
| Relay streaming | Cancelling the subscription removes the local pending request, stops automatic pull refills, releases the local concurrency slot, and ignores late chunks. | `RelayStreamingAgentQueriesRemoteDataSource` sends best-effort `sql.cancel` when a known stream is abandoned. |
| `agents:command` unary | `SocketCommandDispatcher.cancel` fails the local waiter. | Not assumed; the legacy unary path has no client-side pull protocol. |
| Legacy `agents:command` response with `stream_id` | Rejected as `SocketDispatchLegacyStreamingUnsupported`; Colmeia does not implement legacy stream pulls. | Not attempted by this path. |

## Scope lifecycle

`AgentQueriesCancelScope` owns one logical load. It tracks relay request IDs,
legacy socket RPC IDs, REST cancellation callbacks, pre-dispatch local work,
and open streaming SQL targets.

- A streaming target is registered as soon as the dispatcher exposes a
  `stream_id`: either in `relay:rpc.stream.pull_response` or in the first
  data chunk. This avoids waiting for the first chunk before cancellation is
  possible.
- A normally completed stream is removed from the scope. A later refresh or
  navigation therefore never emits a stale `sql.cancel`.
- A subscription cancellation, collector failure, protocol failure, or buffer
  limit failure cancels that target once before the local stream terminates.
  Repeated observations of the same `(agentId, streamId)` are idempotent.
- `cancelAll()` snapshots and clears its state, then starts best-effort
  `sql.cancel` for known streams **before** releasing pre-dispatch work and
  local relay/socket/REST waiters. This reduces the race in which a replacement
  query takes a per-agent slot while the previous stream is still running.

The emitter uses a five-second timeout and logs failures at debug level. A
failed `sql.cancel` must not turn a user-initiated navigation or refresh into a
new visible error.

## Batch and queue interactions

`AgentCommandBatchCoordinator` keeps a separate local future for every logical
caller, including callers coalesced into one wire item.

- Before the batch is emitted, cancelling the last subscriber removes its item
  from the queued batch.
- After emission, cancellation rejects only that caller locally. The physical
  batch remains active so sibling items and coalesced consumers are not
  interrupted; its late response is discarded for the cancelled caller.
- `wireAgentQueriesCancelScopeHandlers` asks the coordinator to cancel first.
  It falls through to `SocketCommandDispatcher.cancel` only when the RPC was
  not coordinator-managed, preventing an inner logical ID from being mistaken
  for the batch envelope ID.
- `sql.cancel` bypasses automatic `agents:command` and relay batching because
  it is latency-sensitive.

The collected relay-streaming datasource also registers cancellation only while
a task waits for its per-agent slot. Cancelling a queued scope removes that task
immediately, completes it with `RelayRequestCancelled`, re-evaluates the queue,
and never starts its streaming datasource call.

## Product and QA expectations

- Leaving a streaming screen stops local waiting immediately. Once the hub has
  supplied a stream ID, the client also attempts `sql.cancel`.
- No UI error should be rendered for a normal superseding refresh or navigation
  cancellation; the mapped cancellation failure is intentionally suppressed.
- Do not promise that a unary query stops on the agent. The supported guarantee
  is that Colmeia no longer waits for its local result.
- Validate remote cancellation with hub/agent audit telemetry when available;
  the client-side attempt alone does not prove that a particular agent can
  abort the underlying database operation.

## Cross-repository follow-ups

- Keep the `stream_id` cancellation paths covered by hub and agent contract
  tests.
- If product requires guaranteed interruption of long unary SQL, define and
  ship a dedicated hub/agent protocol. Reusing local relay cancellation is not
  sufficient.
