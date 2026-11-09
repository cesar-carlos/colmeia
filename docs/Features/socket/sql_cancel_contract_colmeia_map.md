# SQL cancellation — Colmeia contract map

This document describes the Colmeia client behaviour. The hub and agent
semantics remain authoritative in `plug_server/docs/api/api_rest_bridge.md` and
`plug_server/docs/socket/socket_relay_protocol.md`.

Reviewed against the local hub checkout on **2026-11-08**. Colmeia attempts
best-effort cancellation for known streams, but its current wire payload is not
aligned with the current hub validator. Local cancellation is still useful; it
must not be presented as proof of a remote database abort.

## Confirmed wire gap

`lib/core/socket/agent_sql_cancel_command.dart` sends
`params: {stream_id, client_token?}`. The server's
`src/shared/validators/agent_command.ts` SQL-cancel schema requires at least one
of `execution_id` or `request_id`. The server contract covers active streaming,
materialized, batch and queued SQL when `enableSocketCancelMethod` is enabled;
unknown executions return `-32109` / `execution_not_found`.

A payload containing only the client's current `stream_id` does not satisfy that
schema. Confirm the correct execution/request identity across all transports
before changing the client; do not rename `stream_id` blindly. Cancellation must
use the same agent-policy credential as the originating request. This review
updated documentation only and did not execute a live cancellation test.

## Transport paths

| Path | Local cancellation | Remote SQL cancellation |
| --- | --- | --- |
| Relay unary (`relay:rpc.request`) | `RelayCommandDispatcher.cancel` fails the local waiter. The hub or agent can still finish the unary work. | Not implemented by this client path; the upstream contract supports execution/request IDs. |
| Relay streaming | Cancelling the subscription removes the local pending request, stops automatic pull refills, releases the local concurrency slot, and ignores late chunks. | `RelayStreamingAgentQueriesRemoteDataSource` attempts `sql.cancel` when a known stream is abandoned; current payload mismatch is described above. |
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
- Align the existing `sql.cancel` contract before adding a new RPC. Track the
  execution/request identity from the correct attempt, including retry and
  fast-path cases, and test rejected/unknown IDs as well as successful aborts.
- Add payload contract coverage against the hub validator. Test local completion
  separately from agent-side interruption and verify cancellation cannot stop
  a sibling item or another caller sharing the same physical work.
