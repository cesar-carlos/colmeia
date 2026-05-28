# Server-side phase diagnostics

> **Status:** **DELIVERED** on the hub as opt-in `requestServerTimings: true`
> on all three surfaces — `relay:rpc.request`, Socket `agents:command`,
> and REST `POST /api/v1/agents/commands` (2026-05-28). See
> [`DELIVERED.md`](DELIVERED.md) for the integration guide, envelope shape,
> phase-name legend, adoption phasing, and validation method. The hub
> implementation shipped **both** the inline-in-response envelope (proposal
> Option 1) and the adoption counters; Prometheus histograms per phase
> already existed via the latency trace pipeline. **Priority:** medium.
> Required to validate every other item in this folder without guessing.

## Problem

When we measure REST↔Socket gaps we see only **wall-clock end to end**.
We cannot tell whether the gap comes from:

- network RTT (consumer ↔ hub)
- hub queueing / fair-share
- agent CPU / SQL execution
- agent ↔ hub forwarding
- response materialization on the hub

That ambiguity blocks any data-driven optimization. The client side is
adding granular phase metrics in
[`socket_channel_metrics.dart`](../../lib/core/observability/socket/socket_channel_metrics.dart)
(see companion change shipped with these docs). The hub needs to expose
matching server-side timings so the two halves can be correlated.

## What we want exposed

For every relay or `agents:command` RPC, the hub should record (and
ideally surface via a header / response meta field, or at minimum log)
the following timings on a per-`clientRequestId` basis:

| Phase | Meaning |
| --- | --- |
| `hub_received_ms` | wall-clock receipt of `rpc.request` / `agents:command` on the hub socket |
| `hub_validated_ms` | after JSON-RPC parse + permission check |
| `hub_enqueued_ms` | placed on the per-agent outbound queue |
| `agent_forwarded_ms` | dispatched to the agent socket |
| `agent_responded_ms` | first byte of agent response received |
| `hub_responded_ms` | hub finished materializing the response back to the consumer |

Differences between adjacent timestamps tell us **which** hop is slow:

- `hub_received → hub_validated`: parse / auth cost
- `hub_validated → hub_enqueued`: gate / fair-share wait
- `hub_enqueued → agent_forwarded`: queue depth / partition contention
- `agent_forwarded → agent_responded`: agent + DB time (where SQL lives)
- `agent_responded → hub_responded`: response materialization / stream
  collapse on the hub

## Two delivery options (pick one or both)

### Option 1 — Inline in the response envelope

Add an optional `meta.serverTimings` field on `relay:rpc.response`,
`relay:rpc.complete`, and `agents:command_response`:

```json
{
  "meta": {
    "serverTimings": {
      "hub_received_ms": 0,
      "hub_validated_ms": 1,
      "hub_enqueued_ms": 1,
      "agent_forwarded_ms": 3,
      "agent_responded_ms": 142,
      "hub_responded_ms": 144
    }
  }
}
```

Values are milliseconds since `hub_received_ms` (the local baseline).
The hub MUST not include `meta.serverTimings` when the consumer did not
opt in (privacy / payload size), e.g. through a `meta.requestServerTimings`
hint on the request.

Pros:
- Client-side correlation is trivial — same `clientRequestId` already
  available.
- Works without any extra observability pipeline.

Cons:
- Adds ~120 B to every response. Mitigate with the opt-in flag.

### Option 2 — Hub-side metric export

Emit Prometheus / OpenTelemetry histograms per phase, labelled by
`agent_id`, `method`, and `transport` (`rest` / `agents_command` /
`relay_unary` / `relay_streaming`). This is independent of the
consumer, so the team can already act on dashboards.

Pros:
- No protocol change.
- Aggregated view of fleet-wide behaviour.

Cons:
- Cannot correlate a single Colmeia E2E run with hub-side phases unless
  the hub log carries `clientRequestId`.

**Recommended:** ship **both**. Option 1 (opt-in) makes the Colmeia E2E
comparator immediately useful; Option 2 makes the hub team's life easier
in steady state.

## Client uptake

If Option 1 ships:

- `RelayCommandDispatcherImpl` and `SocketCommandDispatcherImpl` parse
  `meta.serverTimings` from the response and forward to
  `SocketChannelMetrics` as phase-attributed timings.
- `tool/compare_e2e_transports.py --runs N` already emits client-side
  phase percentiles (see companion change); pairs naturally with hub
  numbers.

If only Option 2 ships:

- The Colmeia team correlates wall-clock E2E runs against hub
  dashboards by timestamp + agent id.

## Acceptance criteria

- For every `sql.execute` / `sql.executeBatch` issued by the Colmeia
  E2E suite, the hub records the six phase timings.
- If Option 1 is shipped: a Colmeia test run with the opt-in flag set
  receives `meta.serverTimings` on every response and reports p50/p95
  per phase.
- `socket_relay_protocol.md` and `api_rest_bridge.md` document the
  envelope contract and the opt-in.

## Why this is worth doing **before** items 1–3

Without phase diagnostics any single number we see (e.g. "+20% on
suite") is hard to attribute. After phase diagnostics ship:

- The conversation start cost is measurable (item: relay pre-warm
  already addressed client-side).
- The relay 3-hop overhead has its own bucket (validates
  [`relay_unary_fast_path.md`](relay_unary_fast_path.md)).
- The fan-out / queue contention shows up as `hub_validated →
  hub_enqueued` growth (validates
  [`relay_rpc_batch_protocol.md`](relay_rpc_batch_protocol.md) impact).
- The `agents:command` hang has a clear last-known phase (validates
  [`agents_command_cross_agent_hang.md`](agents_command_cross_agent_hang.md)
  hypotheses 1–5).

## References

- Client metrics class: `lib/core/observability/socket/socket_channel_metrics.dart`
- Existing hub observability: `plug_server/docs/observability.md`
- Existing hub performance doc: `plug_server/docs/performance_hub_agent.md`
