# Server adjustments — DELIVERED report & client integration guide

> **What this is**: a delivery report from the `plug_server` hub team to the
> Colmeia client team, covering the four items proposed under
> [`README.md`](README.md). For each item: what shipped on the hub, the
> exact wire contract, the recommended client adoption path, and the
> validation method.
>
> **What this is NOT**: a replacement for the canonical contract docs. The
> source of truth for the wire format is the hub repository:
>
> - [`plug_server/docs/socket_relay_protocol.md`](../../../plug_database/plug_server/docs/socket_relay_protocol.md)
>   ("Relay unary fast-path", "Server-side phase diagnostics")
> - [`plug_server/docs/api_rest_bridge.md`](../../../plug_database/plug_server/docs/api_rest_bridge.md)
>   ("Server-side phase diagnostics", "Limite de um agentId por envelope")
> - [`plug_server/docs/socket_client_sdk.md`](../../../plug_database/plug_server/docs/socket_client_sdk.md)
>   ("Opt-ins de performance e diagnostico")
> - [`plug_server/docs/adrs/0008-relay-batch-protocol.md`](../../../plug_database/plug_server/docs/adrs/0008-relay-batch-protocol.md)
> - [`plug_server/docs/spikes/hmac_worker_offload.md`](../../../plug_database/plug_server/docs/spikes/hmac_worker_offload.md)
> - [`plug_server/docs/runbooks/socket_perf_investigation.md`](../../../plug_database/plug_server/docs/runbooks/socket_perf_investigation.md)

## TL;DR

| Item | Status | What to do on the client |
| ---- | ------ | ------------------------ |
| 3 — Relay unary fast-path | **shipped, opt-in** | Send `fastPath: true` on `relay:rpc.request` envelope for unary RPCs; tolerate missing `relay:rpc.accepted` on the happy path |
| 4 — Server-side phase diagnostics | **shipped, opt-in** | Send `requestServerTimings: true`; consume `meta.serverTimings` (relay) or `serverTimings` (Socket `agents:command` / REST) from responses |
| 1 — Relay batch | **v1 shipped** (`SOCKET_RELAY_BATCH_ENABLED=true` on hub) | Flip `SOCKET_RELAY_BATCH_ENABLED` on the client after the hub rolls it out; route `relay:rpc.request.batch` through `AgentCommandBatchCoordinator`-style coordinator, consume single `relay:rpc.batch_accepted` for correlation. v1 limitations: streaming-capable items rejected; per-item `requestServerTimings`/`fastPath` deferred to v2. |
| 2 — `agents:command` hang | **not a hub defect** | Audit `AgentCommandBatchCoordinator` to confirm it groups by `agentId` **before** envelope packing. Hub now documents 1 agentId per envelope as the contract. |

## Item 3 — Relay unary fast-path (SHIPPED)

### What changed on the hub

- `relay:rpc.request` envelope schema accepts a new optional field
  `fastPath: boolean` (default unset = legacy three-event behaviour).
- When `fastPath === true` **AND** the request was not deduplicated **AND**
  no validation/auth/capacity error occurred, the hub **does not emit**
  `relay:rpc.accepted`. The consumer goes straight from
  `relay:rpc.request` → `relay:rpc.response`.
- When dedup happens (`deduplicated/replayed/inFlight`), the hub **falls
  back** to emitting `relay:rpc.accepted` — the cached response cannot
  carry the new request's dedup state, so this edge keeps the legacy
  shape.
- When dispatch errors (validation, conversation not found, authorization,
  rate-limit, etc.), the hub **always** emits
  `relay:rpc.accepted { success: false, error }` regardless of the flag.
  Otherwise the consumer would be left without a signal.
- The hub does **not** reject `fastPath: true` for streaming-capable
  methods (`sql.execute` with `prefer_db_streaming`/`multi_result`,
  `sql.executeBatch`), but tracks it as misuse via
  `plug_socket_relay_fast_path_stream_inadvertent_total`.

### Wire envelope

```json
{
  "conversationId": "<conv-id>",
  "frame": "<PayloadFrame containing the JSON-RPC body>",
  "fastPath": true,
  "payloadFrameCompression": "default",
  "requestServerTimings": false
}
```

### Client adoption (Dart)

In `lib/core/socket/relay/relay_command_dispatcher_impl.dart`:

```dart
// Pseudocode — adapt to your existing emit helper.
Future<RpcResponse> sendUnary(RpcRequest request) async {
  if (!_isUnarySafeMethod(request.method)) {
    return _sendThreeEventFlow(request); // legacy 3-event
  }

  final clientRequestId = request.id ?? _generateUuid();
  final completer = _registerPendingClientId(clientRequestId);

  _socket.emit('relay:rpc.request', {
    'conversationId': _conversationId,
    'frame': await _encodeFrame(request, requestId: clientRequestId),
    if (kSocketRelayFastPathEnabled) 'fastPath': true,
    if (kSocketRelayServerTimingsEnabled) 'requestServerTimings': true,
  });

  // The handler below already listens on both events; nothing else changes.
  return completer.future;
}
```

In your `_onAccepted` handler — make sure it's **tolerant of being skipped**:

```dart
// Existing: maps clientRequestId -> requestId on rpc.accepted.
void _onAccepted(Map<String, dynamic> payload) {
  final clientRequestId = payload['clientRequestId'] as String?;
  final requestId = payload['requestId'] as String?;
  if (clientRequestId == null || requestId == null) return;

  _clientIdByRequestId[requestId] = clientRequestId;
  // Note: on fast-path happy paths this is NEVER called. The mapping is
  // recovered lazily in `_onResponseFrame` below from the PayloadFrame
  // envelope's `requestId` field, which carries the same hub-assigned id.
}
```

In your `_onResponseFrame` handler — populate the mapping when missing:

```dart
void _onResponseFrame(PayloadFrame frame) {
  final hubRequestId = frame.envelope.requestId;
  final clientRequestId = _clientIdFromJsonRpcId(frame.data);

  // Lazy mapping for fast-path responses that never went through
  // _onAccepted. Idempotent — safe to set even if _onAccepted already did.
  if (hubRequestId != null && clientRequestId != null) {
    _clientIdByRequestId.putIfAbsent(hubRequestId, () => clientRequestId);
  }

  final pending = _pendingByClientId.remove(clientRequestId);
  pending?.completer.complete(frame.data);
}
```

### What NOT to do

- **Do not** set `fastPath: true` for `sql.execute` with
  `prefer_db_streaming: true` or `multi_result: true`. Without
  `relay:rpc.accepted` to anchor the `requestId`, the first
  `relay:rpc.stream.pull` cannot be issued until the first chunk arrives.
  The hub will log + count the misuse but still serve the request.
- **Do not** rely on `relay:rpc.accepted` to learn `requestId` for cancel.
  The relay has no `relay:rpc.cancel` event; cancellation is via socket
  disconnect (abort signal) or `sql.cancel` with the stream's `stream_id`.

### Validation

Use the existing `tool/compare_e2e_transports.py`:

```powershell
# Baseline
python tool/compare_e2e_transports.py --scope suite --transport socket --runs 5

# Fast-path enabled
python tool/compare_e2e_transports.py --scope suite --transport socket --runs 5 \
  --dart-define=SOCKET_RELAY_FAST_PATH_ENABLED=true
```

Expected: every cross-agent file should drop by approximately the
per-RPC round-trip latency × number of relay RPCs the test issues. Single-agent
files improve proportionally to the number of relay RPCs. **Tail latency
should improve more than median** because the saved hop has fixed cost.

Cross-reference hub-side metrics (Prometheus):

```
plug_socket_relay_fast_path_requested_total
plug_socket_relay_fast_path_honored_total           # honored on happy path
plug_socket_relay_fast_path_fallback_dedup_total    # dedup forced accepted
plug_socket_relay_fast_path_fallback_error_total    # error forced accepted
plug_socket_relay_fast_path_stream_inadvertent_total  # misuse detector
```

If `honored / requested` < 50 % in steady state, something is forcing the
fallback — investigate via the audit log:

```
SELECT payload FROM socket_audit_event
WHERE event_type = 'relay:rpc.request'
  AND (payload->>'fastPathRequested')::bool = true
  AND (payload->>'fastPathHonored')::bool = false
ORDER BY created_at DESC LIMIT 100;
```

## Item 4 — Server-side phase diagnostics (SHIPPED)

### What changed on the hub

- New opt-in field `requestServerTimings: boolean` on three surfaces:
  - `relay:rpc.request` envelope
  - `agents:command` body (Socket `/consumers`)
  - `POST /api/v1/agents/commands` body (REST)
- When set, the hub attaches a per-phase latency snapshot to the response:
  - **Relay**: injected at `meta.serverTimings` inside the JSON-RPC body
    of `relay:rpc.response`.
  - **`agents:command` / REST**: sibling field `serverTimings` next to
    `requestId` in the response envelope.
- The hub force-creates the latency trace session for the request even when
  the global `BRIDGE_LATENCY_TRACE_ENABLED` toggle is off — so the opt-in
  works regardless of fleet sampling. Persistence to DB still respects
  sampling.
- Phase keys are stable per schema version, but **new keys may appear in
  minor versions**. Consumers MUST tolerate unknown keys.

### Envelope shape

```json
{
  "schemaVersion": 1,
  "phasesMs": {
    "consumer_frame_decode_ms": 0.42,
    "relay_preflight_ms": 0.13,
    "encode_ms": 0.85,
    "emit_to_socket_ms": 0.07,
    "agent_to_hub_ms": 142.1,
    "inbound_decode_ms": 0.41,
    "pending_resolve_ms": 0.18,
    "relay_forward_to_consumer_ms": 0.06
  }
}
```

Phase legend (from hub `docs/runbooks/socket_perf_investigation.md`):

| Phase | Meaning | Indicates |
| --- | --- | --- |
| `consumer_frame_decode_ms` | Hub decoded inbound PayloadFrame | gunzip + JSON.parse + HMAC cost |
| `relay_preflight_ms` | Validation + conversation lookup + capacity | Gate / fair-share saturation |
| `queue_wait_ms` (REST only) | Wait in per-agent dispatch queue | Agent saturation |
| `encode_ms` | Hub re-encode for agent | JSON.stringify + optional gzip + sign |
| `emit_to_socket_ms` | Socket.IO write to agent socket | < 1 ms ok; > 5 ms = backpressure |
| `agent_to_hub_ms` | Wire + agent processing | Dominated by agent SQL time |
| `inbound_decode_ms` | Hub decoded agent response | Mirror of `consumer_frame_decode_ms` |
| `pending_resolve_ms` | Settle pending promise + dispatch follow-up | Near zero in healthy state |
| `relay_forward_to_consumer_ms` | Hub→consumer emit | Consumer socket backpressure |
| `response_write_ms` | HTTP response write (REST) | TLS + socket flush |

### Client adoption (Dart)

In `lib/core/observability/socket/socket_channel_metrics.dart`:

```dart
class ServerTimings {
  ServerTimings({required this.schemaVersion, required this.phasesMs});

  factory ServerTimings.fromJson(Map<String, dynamic> json) {
    return ServerTimings(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      phasesMs: Map<String, double>.from(
        (json['phasesMs'] as Map?)
            ?.map((k, v) => MapEntry(k as String, (v as num).toDouble())) ??
            const {},
      ),
    );
  }

  final int schemaVersion;
  final Map<String, double> phasesMs;

  /// Use this in your `mergeAll` perf reviews. Tolerates schema bumps.
  double? phaseMs(String name) =>
      schemaVersion == 1 ? phasesMs[name] : null;
}
```

In `RelayCommandDispatcherImpl._onResponseFrame`:

```dart
final responseData = frame.data as Map<String, dynamic>;
final meta = responseData['meta'] as Map<String, dynamic>?;
final timingsJson = meta?['serverTimings'] as Map<String, dynamic>?;
if (timingsJson != null) {
  final timings = ServerTimings.fromJson(timingsJson);
  SocketChannelMetrics.recordPhases(timings.phasesMs);
}
```

In `SocketCommandDispatcherImpl` (`agents:command`) and the REST HTTP
client, the field is at the **top level** of the response envelope, not
under `meta`:

```dart
final timingsJson = response['serverTimings'] as Map<String, dynamic>?;
if (timingsJson != null) {
  SocketChannelMetrics.recordPhases(ServerTimings.fromJson(timingsJson).phasesMs);
}
```

### Adoption phasing

1. **Phase 1 — opt-in everywhere, default off.** Add a `dart-define`
   `SOCKET_RELAY_SERVER_TIMINGS_ENABLED` defaulting to `false`. Wire it
   into all three dispatchers.
2. **Phase 2 — enable in load tests and the E2E suite.** Run the existing
   `tool/compare_e2e_transports.py --runs 5` with the flag on and capture
   p50/p95 per phase. Save the artifact for regression detection.
3. **Phase 3 — opt-in for diagnostic builds.** Ship to internal tooling
   and SRE dashboards. Do NOT enable for prod consumers by default
   (~120 bytes per response × N consumers × Y RPS = noticeable bandwidth
   spend).
4. **Phase 4 (optional)** — enable in production for a small percentage of
   requests (sampling on the client side) to detect regressions.

### Validation

Run the comparator with phase emission:

```powershell
python tool/compare_e2e_transports.py --scope suite --transport both --runs 5 \
  --dart-define=SOCKET_RELAY_SERVER_TIMINGS_ENABLED=true \
  --emit-phases
```

Expected: median + p95 per phase printed for relay and REST. Use it to
identify which phase to attack next (see hub `docs/runbooks/socket_perf_investigation.md`
for the decision matrix).

Hub-side adoption metrics:

```
plug_socket_relay_server_timings_opt_in_total
plug_socket_agents_command_server_timings_opt_in_total
plug_rest_agents_command_server_timings_opt_in_total
```

## Item 1 — Relay batch (v1 SHIPPED)

### What changed on the hub

- **New event** `relay:rpc.request.batch` accepted on `/consumers`. Gated by
  `SOCKET_RELAY_BATCH_ENABLED` (default `false` — hub team will roll out
  per environment). When off, the event responds with `RELAY_BATCH_DISABLED`.
- **New ack event** `relay:rpc.batch_accepted` (JSON) emitted **once** per
  inbound envelope, carrying the per-item correlation map. Per-item
  responses continue on the existing `relay:rpc.response`.
- New env keys:
  - `SOCKET_RELAY_BATCH_ENABLED` (default `false`)
  - `SOCKET_RELAY_BATCH_MAX_ITEMS` (default `32`)
- New Prometheus counters (see `metrics_renderer.ts`):
  - `plug_socket_relay_batch_envelopes_received_total`
  - `plug_socket_relay_batch_envelopes_accepted_total`
  - `plug_socket_relay_batch_items_accepted_total`
  - `plug_socket_relay_batch_items_deduped_total`
  - `plug_socket_relay_batch_items_error_total`
  - `plug_socket_relay_batch_envelopes_rejected_total{reason=...}`

### Wire envelopes

Request:

```json
{
  "conversationId": "<conv-id>",
  "frame": "<PayloadFrame containing a JSON-RPC array of 1..32 commands>",
  "payloadFrameCompression": "default",
  "requestServerTimings": false,
  "fastPath": false
}
```

Successful ack (single emit per inbound):

```json
{
  "success": true,
  "conversationId": "<conv-id>",
  "batchSize": 3,
  "items": [
    { "clientRequestId": "a", "requestId": "<hub-uuid>" },
    {
      "clientRequestId": "b",
      "requestId": "<hub-uuid-original>",
      "deduplicated": true,
      "replayed": true
    },
    {
      "clientRequestId": "c",
      "error": { "code": "SERVICE_UNAVAILABLE", "statusCode": 503, "itemIndex": 2 }
    }
  ]
}
```

Envelope-level rejection error codes: `RELAY_BATCH_DISABLED`,
`BATCH_TOO_LARGE`, `BATCH_EMPTY`, `BATCH_ITEM_INVALID`,
`BATCH_ITEM_REQUIRES_ID`, `BATCH_DUPLICATE_ID`,
`BATCH_STREAMING_ITEM_REJECTED`, `RATE_LIMITED` (with
`details.availableSlots` / `details.requestedSlots`), `NOT_FOUND`,
`BAD_REQUEST`, `VALIDATION_ERROR`.

### Client adoption (Dart)

In a new `RelayBatchCommandCoordinator` (mirror of
`AgentCommandBatchCoordinator`):

```dart
final clientRequestIds = items.map((item) => item.clientRequestId).toList();
final completers = {
  for (final id in clientRequestIds) id: Completer<RpcResponse>(),
};

// Single emit on the batch event.
_socket.emit('relay:rpc.request.batch', {
  'conversationId': _conversationId,
  'frame': await _encodeBatchFrame(items),
});
// One-shot ack from the hub with per-item correlation.
final ack = await _waitForBatchAccepted();
if (ack['success'] != true) {
  // Envelope-level rejection: surface `error.code` to caller and complete all
  // completers with that error (e.g. RATE_LIMITED → retry with smaller batch).
  for (final c in completers.values) c.completeError(ack['error']);
  return;
}

// Populate clientRequestId -> requestId map from the ack so per-item
// `rpc.response` events arriving later can be correlated.
for (final item in ack['items'] as List) {
  final cid = item['clientRequestId'] as String;
  if (item['error'] != null) {
    completers[cid]!.completeError(item['error']);
  } else {
    _clientIdByRequestId[item['requestId']] = cid;
  }
}
```

### v1 limitations (worth knowing before adoption)

- **Streaming-capable items rejected.** `sql.executeBatch` and `sql.execute`
  with `prefer_db_streaming` / `multi_result` cannot be batched in v1. Send
  those as `relay:rpc.request` single.
- **Each item must declare a JSON-RPC `id`.** Notifications (`id: null`)
  are not allowed in v1 batches.
- **Per-item duplicate ids fail the envelope.** The whole batch returns
  `BATCH_DUPLICATE_ID`.
- **`requestServerTimings` and `fastPath` on the envelope are accepted by
  the schema but NOT propagated to per-item dispatch in v1**. For per-item
  timings, send the request as single `relay:rpc.request`. v2 will route
  these through.
- **Per-socket inflight gate is all-or-nothing.** If the batch needs N
  slots and only K < N are free, the entire envelope is rejected with
  `RATE_LIMITED { availableSlots: K, requestedSlots: N }`. The client
  should back off and retry with a smaller batch.

### Validation

After the hub team flips `SOCKET_RELAY_BATCH_ENABLED=true` in a
non-production environment, run the existing E2E suite:

```powershell
python tool/compare_e2e_transports.py --scope suite --transport socket --runs 5 \
  --dart-define=SOCKET_RELAY_BATCH_ENABLED=true
```

Expected: cross-agent files (`agent_query_across_agents_repositories_e2e_test.dart`,
`load_resumo_*_across_agents_e2e_test.dart`) collapse toward the REST
baseline. Single-agent files unchanged.

Hub-side adoption check:

```
sum(plug_socket_relay_batch_envelopes_accepted_total)
  / sum(plug_socket_relay_batch_envelopes_received_total)
```

should be near 1.0 once the client is sending well-formed batches; sustained
< 0.8 indicates pathological rejection — check `..._rejected_total{reason=...}`
breakdown.

## Item 2 — `agents:command` cross-agent "hang" (not a hub defect)

### What we found on the hub

The hub's `agents:command` correlation map is keyed on the **JSON-RPC `id`**
(`correlationId`), not on `(socketId, agentId)`. Two parallel
`agents:command` events from the same consumer to different agents do not
collide because their JSON-RPC `id`s are distinct. We could not reproduce
the alleged hang under that pattern.

The most likely root cause for the report:
**`AgentCommandBatchCoordinator` is packing commands targeted at DIFFERENT
agents into a single `agents:command` envelope.** The hub dispatches the
**whole batch** to the `agentId` declared in the envelope; items intended
for other agents will never produce an `rpc:response` because the target
agent doesn't recognize those ids, leading to the symptom: "first call
hangs, no response, no error".

### What was documented on the hub

A new section in
[`docs/api_rest_bridge.md`](../../../plug_database/plug_server/docs/api_rest_bridge.md)
("Limite de um `agentId` por envelope") makes the contract explicit:

> Tanto a rota REST quanto o evento Socket `agents:command` aceitam
> **exatamente um** `agentId` por envelope. Quando `command` é um array
> (batch JSON-RPC nativo), **todos os itens são despachados para o mesmo
> agente** declarado no `agentId` do envelope.

### Client action

1. **Audit `AgentCommandBatchCoordinator`** to confirm it groups commands
   by `agentId` **before** packing into an `agents:command` envelope.
   Commands targeting different agents must produce **separate envelopes**.
2. If the audit confirms the coordinator already groups correctly,
   provide a minimal repro: **1 socket connection, 2 distinct `agents:command`
   events (not 1 batch) to 2 different agents**, and capture hub logs
   during the run (`rpc_timeout_without_ack`, `rpcFrameDecodeFailed`,
   `agent_disconnected_before_dispatch`). The hub team will reopen the
   investigation with that evidence.
3. The current `injector_agent_queries.dart:348-354` relay fallback is
   safe to keep — it routes around the issue regardless of root cause.

## What changed in the hub repository (high level)

For traceability, the hub changes that back this delivery:

### Source

- `src/application/services/bridge_latency_trace_builder.ts` —
  `getPhasesSnapshot()`, `createBridgeLatencyTraceForRequest({ forceActive })`,
  schema versioning policy, defensive cap on phase keys.
- `src/application/services/server_timings_envelope.ts` (new) — helper to
  build and attach `meta.serverTimings`.
- `src/presentation/socket/consumers/relay_rpc_request.handler.ts` —
  accept `fastPath` + `requestServerTimings`, skip `accepted` on
  fast-path happy path, audit log fields.
- `src/presentation/socket/consumers/agents_command.handler.ts` —
  accept `requestServerTimings`, attach `serverTimings` envelope.
- `src/presentation/http/controllers/agents.controller.ts` — REST opt-in.
- `src/presentation/socket/hub/relay/rpc_bridge_dispatch_relay.ts` —
  propagate flags to `RelayRequestRoute`.
- `src/presentation/socket/hub/relay/rpc_bridge_agent_inbound.ts` —
  inject `meta.serverTimings` on forward; bypass re-encode when no
  mutation (perf optimization); detect fast-path + stream misuse.
- `src/presentation/socket/hub/relay/rpc_bridge_command_helpers.ts` —
  `EMPTY_OUTBOUND_RPC_META` sentinel, allocate-on-write `sanitize`.
- `src/presentation/socket/hub/registries/relay_request_registry.ts` —
  new fields `requestServerTimings`, `fastPath` on the route.
- `src/shared/utils/payload_frame.ts` — expose `decodedBytes` in
  `DecodedPayloadFrame`, new `encodePayloadFrameFromBytes`.
- `src/shared/utils/logger.ts` — `isLevelEnabled` for hot-path guards.
- `src/shared/metrics/socket_consumer.metrics.ts` — adoption counters.
- `src/shared/validators/agent_command.ts` — `requestServerTimings` on
  the body schema.
- `src/presentation/http/controllers/metrics_renderer.ts` — Prometheus
  lines for the adoption counters.

### Tests

- Unit + contract coverage in `tests/unit/**` and `tests/integration/**`
  for: schema acceptance, opt-in propagation, fast-path skip / fallbacks
  (dedup / error), envelope injection, bypass forwarder behaviour,
  envelope size budget, defensive caps.

### Docs

- `docs/socket_relay_protocol.md` — new sections "Relay unary fast-path"
  and "Server-side phase diagnostics".
- `docs/api_rest_bridge.md` — new column on the body schema table, new
  sections "Server-side phase diagnostics" and "Limite de um agentId
  por envelope".
- `docs/socket_client_sdk.md` — new section "Opt-ins de performance e
  diagnostico".
- `docs/adrs/0008-relay-batch-protocol.md` — ADR closing Item 1 spec
  gaps.
- `docs/spikes/hmac_worker_offload.md` — gated future improvement.
- `docs/runbooks/socket_perf_investigation.md` — operator runbook.

## Where to ask questions

- Wire contract or protocol-level questions: open issue against
  `plug_database/plug_server` referencing
  [`docs/socket_relay_protocol.md`](../../../plug_database/plug_server/docs/socket_relay_protocol.md).
- Adoption / migration questions on the Colmeia side: existing
  [`socket_channel_performance_review.md`](../Features/socket/socket_channel_performance_review.md)
  remains the integration playbook.
- New perf measurements that suggest a gap not covered here:
  follow the runbook
  [`docs/runbooks/socket_perf_investigation.md`](../../../plug_database/plug_server/docs/runbooks/socket_perf_investigation.md)
  to capture per-phase numbers first, then file the proposal back here.
