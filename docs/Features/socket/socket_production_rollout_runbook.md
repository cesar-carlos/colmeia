# Socket Channel — Production Rollout Runbook

> Status: code-complete (`main` as of 2026-04-18).  
> Companion plan: [`socket_consumer_channel_plan.md`](socket_consumer_channel_plan.md)  
> Hub source-of-truth: `plug_server/docs/socket_relay_protocol.md`,
> `plug_server/docs/socket_client_sdk.md`. Local contract summaries:
> [`../../plug_server_docs_index_for_colmeia.md`](../../plug_server_docs_index_for_colmeia.md)
> and [`../../bridge_agent_sql_api_options.md`](../../bridge_agent_sql_api_options.md).

This document is the **operational** runbook for flipping the Colmeia
client from REST to the Socket channel against `plug_server`. It assumes
the architectural review and code work are done — only env flags,
infrastructure verification, smoke tests and rollback procedures are
listed here.

---

## 0. Capabilities recap (what the code already supports)

| Capability                                                                   | Implementation                         | Default behavior                              |
| ---------------------------------------------------------------------------- | -------------------------------------- | --------------------------------------------- |
| `/consumers` namespace, single connection                                    | `ConsumerSocketConnection`             | Disconnected until `connect()`                |
| Handshake `connection:ready` (`PayloadFrame`; raw JSON legacy override only) | `PayloadFrameConnectionReadyDecoder`   | `payload_frame_only`                          |
| Auth via JWT (`auth: { token }`) + single-flight refresh on 401/403          | `SessionSocketAuthTokenProvider`       | Reuses `AuthRefreshCoordinator`               |
| Reconnect with exponential backoff + full jitter                             | `SocketReconnectBackoff`               | 5 attempts, 1 s → 30 s                        |
| `Retry-After` honored on handshake (`app:error`) and on per-command failures | `socket_app_error_retry_after.dart`    | Server hint clamped to `reconnectMaxDelay`    |
| `agents:command` (legacy bridge over `/consumers`)                           | `SocketCommandDispatcherImpl`          | Coalescing on, concurrency gate at 8/agent    |
| `relay:*` unary + streaming (with `rpc.stream.pull` window clamp)            | `RelayCommandDispatcherImpl`           | Opt-in via `SOCKET_RELAY_ENABLED`             |
| PayloadFrame v1.0 encode/decode (auto-gzip, 10 MiB cap, 10x inflation guard) | `PayloadFrameCodec`                    | Always on once socket selected                |
| HMAC-SHA256 outbound signing                                                 | `Hmac256PayloadFrameSigner`            | Off until `SOCKET_PAYLOAD_SIGNING_KEY` set    |
| HMAC-SHA256 inbound verification                                             | `Hmac256PayloadFrameSignatureVerifier` | Auto-wired with the signer                    |
| `client:agent.profile.updated` push                                          | `ClientAgentProfileUpdatedListener`    | Opt-in via `SOCKET_PRESENCE_LISTENER_ENABLED` |
| App lifecycle pause/resume + post-login warm-up                              | `SocketLifecycleObserver`              | Active when `transport=socket`                |

---

## 1. Pre-flight — server & infrastructure

### 1.1 Hub side

Confirm the target `plug_server` deployment is on a build that:

- exposes `/consumers` namespace (any post-Q1 2026 build);
- accepts JWT in the Socket.IO handshake `auth.token`;
- emits `connection:ready` as `PayloadFrame`; raw JSON is legacy-only and
  requires `SOCKET_CONNECTION_READY_COMPAT_MODE=compat` or `raw_json_only`.

Optional but recommended hub configuration:

```bash
# Consumer namespace acceptance (set on the hub).
SOCKET_CONSUMER_ROLES=user,admin,client

# Catalog push to the client.
SOCKET_CLIENT_AGENT_PROFILE_PUSH_ENABLED=true

# Outbound shed-load hints we now respect during handshake.
SOCKET_RELAY_OUTBOUND_OVERLOAD_BACKLOG=2000
SOCKET_RELAY_OUTBOUND_OVERLOAD_P95_MS=2000

# If you want signature enforcement (defence in depth, optional).
PAYLOAD_SIGN_OUTBOUND=true
PAYLOAD_SIGNING_KEY=<random-256-bit-utf8>
PAYLOAD_SIGNING_KEY_ID=hub-2026-q2   # only when rotating keys
```

### 1.2 nginx / upstream

Sticky session is **required** for relay conversations and the bridge
in-memory state (per `plug_server/docs/scaling_and_roadmap.md`). Without
it `relay:rpc.request` lands on a different replica than the one that
opened the conversation and dies with `protocol_not_ready`.

Two acceptable strategies:

```nginx
# Option A: ip_hash (works for single device per public IP)
upstream colmeia_hub {
    ip_hash;
    server hub-1.internal:3000;
    server hub-2.internal:3000;
}

# Option B: cookie-based affinity (preferred for mobile/NAT)
upstream colmeia_hub {
    sticky cookie hub_node expires=1h domain=plug-server.example.com path=/;
    server hub-1.internal:3000;
    server hub-2.internal:3000;
}

server {
    location /socket.io/ {
        proxy_pass http://colmeia_hub;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
    }
}
```

Cross-check after deployment by inspecting response headers — the hub
sets `X-Hub-Instance-Id`, which we already log on every Dio response.
Multiple distinct values across consecutive REST calls within a single
session = sticky session NOT effective, do **not** flip
`AGENT_BRIDGE_TRANSPORT=socket` until fixed.

---

## 2. Three deployment modes

Pick the lowest-friction mode that meets the security bar of the target
environment. Each row only lists what changes vs. the row above it.

### Mode A — REST + signed-up presence (no socket dispatch)

Useful as a stepping stone — gets the catalog push without changing the
SQL transport.

```bash
AGENT_BRIDGE_TRANSPORT=rest                 # default
SOCKET_PRESENCE_LISTENER_ENABLED=true       # changed
```

Effect: app keeps issuing SQL via REST, but the consumer socket connects
post-login and consumes `client:agent.profile.updated`. Polling for
catalog changes is replaced by realtime push.

### Mode B — Full socket, permissive signing

The recommended target for most production deployments.

```bash
AGENT_BRIDGE_TRANSPORT=socket               # changed
SOCKET_RECONNECT_ATTEMPTS=8                 # mobile-friendly
SOCKET_WARM_UP_AFTER_LOGIN=true             # default; spelled out for ops
# SOCKET_PAYLOAD_SIGNING_KEY=               # leave empty when hub unsigned
```

Effect: every `agents:command` and `relay:*` flows through the socket;
unsigned frames in both directions; falls back to local exponential
backoff on transient failures, respects server `Retry-After` hints when
they arrive. In the app runtime, `AGENT_BRIDGE_TRANSPORT=socket`
implicitly enables relay and realtime presence, so no extra client-side
flag is required for those paths.

### Mode C — Full socket, strict signing (defence in depth)

Only after the hub itself runs with `PAYLOAD_SIGN_OUTBOUND=true` and the
key is rotated under controlled change management.

```bash
AGENT_BRIDGE_TRANSPORT=socket
SOCKET_PAYLOAD_SIGNING_KEY=<must match hub PAYLOAD_SIGNING_KEY>
SOCKET_PAYLOAD_SIGNING_KEY_ID=hub-2026-q2   # only if hub uses key_id
SOCKET_PAYLOAD_REQUIRE_SIGNATURE=true       # reject unsigned inbound
```

Effect: outbound frames are HMAC'd, inbound frames must carry a valid
HMAC; tampered or unsigned frames are rejected with stable codes
(`signature_invalid`, `signature_required`, `signature_key_id_mismatch`)
that surface as `PayloadFrameDecodeException` and propagate to the
dispatcher as transient socket failures.

---

## 3. Smoke test (manual, ~5 min)

Run against a staging build with the chosen mode. **Do not skip step 0**
even when you "know" the env is right — the cost of a bad rollout is
much higher than 30 s of grep.

0. **Verify build flags landed**: launch the build, drive a single
   action and check `flutter logs` for:
   - `Consumer socket warm-up requested` (presence of socket transport).
   - `connection:ready decoded` with `shape: payloadFrame` or
     `shape: rawJson` (handshake succeeded; tells you which decoder
     path the hub used).
   - In Mode C: any `signature_*` rejection means the keys disagree
     between client and hub — fix immediately.

1. **Login → home overview**:
   - Authenticate.
   - Wait ~2 s. The socket should warm up (visible in logs, no UI work).
   - Open the home overview. Every chart should render. Check the
     network tab / Sentry for any `agents:command` over REST — if
     present, the transport flag did NOT take effect.

2. **One SQL query** (any agent):
   - Trigger a query that runs on a single agent (e.g. agent detail
     "Refresh from agent" → `agent.getProfile`).
   - Expect a successful response within `SOCKET_REQUEST_TIMEOUT_MS`
     (15 s default). Any `protocol_not_ready` here usually means
     sticky session is broken.

3. **Streaming SQL via relay** (only Mode B/C):
   - Open a screen that pulls a ranking with > 100 rows
     (overview tabs do this).
   - Logs should show `relay:conversation.start` / `started`,
     successive `relay:rpc.chunk`, then `relay:rpc.complete`.
   - Inspect one outbound `relay:rpc.stream.pull`: it must be
     `{ conversationId, frame }`, with `frame` decoded as `PayloadFrame`
     containing `request_id`, `window_size` and `stream_id` once the hub
     has returned one. Raw `requestId` / `windowSize` at the top level is
     a stale client contract.
   - In overload, the `relay:rpc.stream.pull_response` carries
     `success: false` with `RATE_LIMITED` — the dispatcher honors it
     by failing the stream and surfacing a `Retry-After` countdown
     in the UI (overview "Reload" button shows "Retry in Ns").

4. **Pause/resume cycle**:
   - Send the app to background for ~10 s.
   - Bring it back to foreground.
   - Logs should show `SocketLifecycleObserver pause failed reason=app_paused`
     followed by `Consumer socket warm-up requested reason=app_resumed`.
   - Trigger one more query → must succeed without re-login.

5. **Logout**:
   - Sign out.
   - Logs should show disconnect reason `signed_out` (via
     `ConsumerSocketConnection.pause(reason: 'signed_out')`)
     and a clean disconnect (state → `ConsumerSocketDisconnected`).
   - No more `agents:command` / relay RPCs should be emitted.

6. **Token revocation** (catalog push, Mode A/B/C):
   - On the hub, revoke the client token of an agent the device has
     access to (or set `revokedAt` via admin tool).
   - Within the next push window, the agent detail screen's policy
     card should display the **Revoked** banner with the in-card
     CTAs (Remove token / Save new token). Push happens via
     `client:agent.profile.updated`.

If all six steps pass, the rollout is **green**. Promote the env to the
next stage.

---

## 4. Observability — what to watch after go-live

### 4.1 Client side (Sentry / log aggregator)

Expected baseline (no anomalies):

- `ConsumerSocketConnection state changed → ConsumerSocketConnected`
  near every login or app resume.
- Per-query `agents:command` round-trip ≤ p95 of REST equivalent.
  Worse-than-REST p95 is a regression — consider rolling back.

Red flags:

- `Consumer socket reconnect exhausted` repeatedly for the same user
  → sticky session probably broken.
- `signature_invalid` / `signature_key_id_mismatch` repeatedly →
  client-side `SOCKET_PAYLOAD_SIGNING_KEY` drifted from the hub.
- `protocol_not_ready` → handshake landed on a replica without
  `agent:capabilities` for the target agent. Sticky session and/or
  `SOCKET_AGENT_PROTOCOL_READY_GRACE_MS` on the hub.

### 4.2 Hub side (Prometheus `/metrics`)

Watch these counters during the first hours:

- `plug_socket_relay_rate_limit_*_rejected_total` — non-zero spikes
  mean Mode B/C is hitting the consumer rate ceiling. Either bump
  `SOCKET_RELAY_RATE_LIMIT_MAX_REQUESTS` on the hub or audit the
  app for a tight loop.
- `plug_socket_agents_command_rate_limit_rejected_total` — same
  signal for the legacy `agents:command` path.
- `plug_socket_relay_outbound_overload_*` — any non-zero is the
  exact "shed load" path the client now respects via
  `Retry-After`.

### 4.3 Channel metrics (`SocketChannelMetrics`)

Already wired into `SocketMetricsListener.start()` whenever the socket
transport is active. If the project ships a Grafana dashboard or
Sentry custom metrics view, ensure it includes:

- coalesce hits (fewer round-trips for free)
- batch emissions (only when `SOCKET_BATCH_ENABLED=true`)
- reconnect counter aggregated by `reasonCode`
- `restFallbackLatchTotal` — permanent REST latch (auth / namespace)
- `restFallbackTemporaryLatchTotal` — temporary REST window after
  consecutive socket/relay transport timeouts / disconnects

### 4.4 Troubleshooting — socket hang vs REST degradation

| Symptom | Likely cause | Client signal | Action |
| --- | --- | --- | --- |
| Charts fail with transport timeout, then recover on REST | Hub `/consumers` or relay stalled | After 3 consecutive timeouts, logs show temporary REST latch; metric `restFallbackTemporaryLatchTotal` increments | Confirm hub relay health; temporary window is 60s then socket probe |
| Every chart shows session-expired style auth failure | Hub `SOCKET_CONSUMER_ROLES` or exhausted refresh | Permanent REST latch; `restFallbackLatchTotal` | Fix hub roles / re-login |
| Parallel RPCs on same conversation time out with fastPath | Hub overwrites JSON-RPC `id` (ADR 0009 defect) | Client regression test documents both timeout | Set hub `SOCKET_RELAY_FAST_PATH_ENABLED=false` or deploy hub fix that echoes client `id` — see [`docs/server_adjustments/relay_unary_fast_path.md`](../../server_adjustments/relay_unary_fast_path.md) |

### 4.5 PayloadFrame isolates (recommended defaults)

Client defaults (do not change without measuring UI jank):

- `SOCKET_PAYLOAD_WORKER_ISOLATES_ENABLED=true`
- Gzip decode isolate threshold ≈ 16 KiB
- Gzip encode / JSON decode thresholds follow `AppEnvironment` defaults

---

## 5. Rollback procedure

The Socket transport is a **soft toggle**. To revert in under one
release cycle:

1. Flip the env back:

   ```bash
   AGENT_BRIDGE_TRANSPORT=rest
   SOCKET_RELAY_ENABLED=false
   # SOCKET_PRESENCE_LISTENER_ENABLED can stay `true` even in REST
   # mode — the listener just no-ops when there is no socket.
   ```

2. Deploy the build. Existing socket connections drain at the next
   app resume / re-login (the lifecycle observer detects the
   transport change at `_isSocketTransport` and stops attempting
   `connect()`).

3. No data migration is required — both transports speak the same
   JSON-RPC and bridge to the same `POST /api/v1/agents/commands`.

If the rollback is reactive (something on the hub broke), confirm
clients are no longer issuing `agents:command` over socket via the
hub's audit log (`audit_events`) before declaring the incident closed.

---

## 6. FAQ

### Why is `connection:ready` a PayloadFrame now?

Hub Phase 2 standardises every event on the binary envelope so signing applies
uniformly. Colmeia now defaults to `payload_frame_only`. Use `compat` or
`raw_json_only` only when validating an older hub; raw JSON is planned for
removal after 2026-09-30.

### Can I run signed outbound + unsigned inbound?

Yes. Set `SOCKET_PAYLOAD_SIGNING_KEY` (signer is always wired) but
leave `SOCKET_PAYLOAD_REQUIRE_SIGNATURE=false`. Outbound frames carry a
HMAC; inbound frames are accepted regardless. Useful when the hub
verifies but does not yet sign back.

### What happens if a chart fails because of `RATE_LIMITED`?

The repository propagates `RpcFailure(retryAfter: ...)` via
`appFailureRetryAfter`; the overview controller arms its
`RetryAfterGate` and disables the Reload button with a "Retry in Ns"
countdown until the gate opens. Manual retries inside the gate are
silent no-ops (UI treats them as "user already saw the wait").

### How do I verify HMAC signing is actually happening?

Easiest: enable verbose Socket.IO logs (`socket_io_client` debug) and
look for the `signature` block in emitted relay frames. Or add a
breakpoint in `Hmac256PayloadFrameSigner.sign` — it should fire on
every outbound `relay:rpc.request` once the codec is configured.

### Can mobile and web run different modes?

Yes. The codec, signer and verifier are pure Dart — they work on every
platform `socket_io_client` supports. Web builds have a slightly higher
handshake cost (Engine.IO over WebSocket), so consider
`SOCKET_HANDSHAKE_TIMEOUT_MS=15000` instead of the default 10 s.

---

## 7. Open follow-ups (non-blocking)

These are low-priority, no longer block production:

- **Hot reload of signing keys** — today the codec is built once at
  startup. Key rotation requires a process restart. Acceptable for
  mobile (next launch picks up new key); for long-lived web sessions
  a future PR could refresh the codec on `AuthSessionEvents.tokenRefreshed`.
- **Inbound `traceparent` propagation** — the codec preserves
  `traceId` in the envelope but the dispatcher does not yet plumb
  it into Sentry. Cosmetic for monitoring once distributed tracing
  lands.
- **`relay:rpc.request_ack` / `batch_ack` handlers** — declared in
  `RelayEventNames`, not consumed today. Informative only; ignore
  until product needs visibility into hub→agent handoff.
