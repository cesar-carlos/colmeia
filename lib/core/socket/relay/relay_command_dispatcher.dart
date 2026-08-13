import 'package:colmeia/core/socket/agent_sql_open_stream.dart';
import 'package:colmeia/core/socket/relay/relay_batch_item.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart'
    show RelayRequestCancelled;
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:colmeia/core/socket/relay/relay_rpc_outcome.dart';

/// High-level entry point for sending a JSON-RPC request through the relay
/// channel and receiving the correlated response.
///
/// Two surfaces are exposed:
///
/// 1. `sendUnary` — single-shot request that resolves with the same
///    `Map<String, dynamic>` shape used by `agents:command` / REST. Use it
///    for queries that produce a bounded payload.
/// 2. `sendStreaming` (PR-L+ part 2) — opens the request and exposes the
///    inbound `relay:rpc.chunk` events as a `Stream<Map<String, dynamic>>`.
///    The dispatcher manages backpressure by emitting `relay:rpc.stream.pull`
///    automatically with a configurable rolling window. Stream closes when
///    `relay:rpc.complete` arrives with `terminal_status: completed`;
///    surfaces an error when the hub aborts the stream (`aborted`, `error`).
abstract interface class RelayCommandDispatcher {
  /// Sends a single JSON-RPC payload (`body`) over the relay conversation
  /// for [agentId] and resolves with the JSON-decoded `relay:rpc.response`.
  ///
  /// The [body] mirrors the body sent through `agents:command`; the
  /// dispatcher will:
  ///
  /// 1. Encode it as a `PayloadFrame` (auto-gzip per `PayloadFrameCodec`).
  /// 2. Open a conversation via the manager (or reuse the active one).
  /// 3. Emit `relay:rpc.request` with `{conversationId, frame, payloadFrameCompression}`.
  /// 4. Wait for `relay:rpc.accepted`, then either:
  ///    - resolve on the first `relay:rpc.response` (single response), or
  ///    - resolve on `relay:rpc.complete` if the hub bundles the response
  ///      into a single completion frame.
  ///
  /// Throws subtypes of `RelayDispatchException`; never throws raw
  /// `StateError` for transport problems.
  ///
  /// [timeoutMs] is forwarded on the `relay:rpc.request` envelope for
  /// forward-compat with REST-style per-request waits. The hub schema
  /// does **not** honor it yet (field is stripped; wait stays
  /// `SOCKET_RELAY_REQUEST_TIMEOUT_MS`) — see
  /// `docs/plug_server/relay_envelope_timeout_ms.md`. [timeout] is the
  /// consumer-side pending deadline; prefer the caller's
  /// `bridgeTimeoutMs` (not `bridgeTimeoutMs + buffer`) for both.
  Future<Map<String, dynamic>> sendUnary({
    required String agentId,
    required Map<String, Object?> body,
    required String clientRequestId,
    Duration? timeout,
    int? timeoutMs,
    RelayPayloadFrameCompression compression =
        RelayPayloadFrameCompression.auto,
  });

  /// Same wire payload as [sendUnary], but consumes the response as a
  /// `Stream` of decoded `relay:rpc.chunk` payloads. Use when the agent is
  /// expected to deliver a large result progressively.
  ///
  /// Backpressure is managed automatically:
  ///
  /// - On `relay:rpc.accepted`, the dispatcher grants
  ///   [initialWindowSize] chunk credits via `relay:rpc.stream.pull`.
  /// - Whenever the outstanding budget falls to or below
  ///   [refillThreshold], the dispatcher refills back to
  ///   [initialWindowSize].
  /// - A non-streaming `relay:rpc.response` is forwarded as a single
  ///   chunk and immediately closes the stream.
  /// - `relay:rpc.complete` with `terminal_status: completed`/`success`
  ///   closes the stream normally; any other status (or invalid
  ///   PayloadFrame on response/chunk) raises a `RelayDispatchException`
  ///   on the stream and closes it.
  ///
  /// The returned stream is **single-subscription** — attach a listener
  /// immediately after this call returns so chunks are not dropped while
  /// the dispatcher is already forwarding events.
  ///
  /// Cancelling the returned subscription does **not** notify the hub
  /// (the relay protocol has no client-side cancel today). The dispatcher
  /// drops further chunks and lets the request settle; combined with the
  /// existing [timeout], this prevents leaks.
  Stream<Map<String, dynamic>> sendStreaming({
    required String agentId,
    required Map<String, Object?> body,
    required String clientRequestId,
    Duration? timeout,
    int? timeoutMs,
    int? initialWindowSize,
    int? refillThreshold,
    RelayPayloadFrameCompression compression =
        RelayPayloadFrameCompression.auto,
  });

  /// Emits a `relay:rpc.request.batch` envelope (hub item 1, v1 shipped
  /// 2026-05-28) carrying [items] for the same conversation/[agentId].
  ///
  /// The hub answers with a single `relay:rpc.batch_accepted` JSON
  /// envelope; per-item replies arrive on the regular
  /// `relay:rpc.response` channel. The returned future resolves with the
  /// per-item responses **in the same order as [items]**.
  ///
  /// Envelope-level rejections (`RELAY_BATCH_DISABLED`, `BATCH_TOO_LARGE`,
  /// `RATE_LIMITED`, etc.) surface as a single `RelayRequestRejected`
  /// failing every entry of the returned list. Per-item errors carried
  /// inside a successful ack fail only that entry — sibling entries
  /// still resolve when their own response arrives.
  ///
  /// v1 limitations (see
  /// `docs/server_adjustments/relay_rpc_batch_protocol.md`):
  ///
  /// - Streaming-capable items are rejected with
  ///   `BATCH_STREAMING_ITEM_REJECTED`. Callers must route them through
  ///   [sendUnary] before reaching the coordinator.
  /// - Each item MUST declare a JSON-RPC `id`; the wire format rejects
  ///   notifications (`id: null`).
  /// - Duplicate `id`s fail the whole envelope with `BATCH_DUPLICATE_ID`.
  /// - Per-item `requestServerTimings`/`fastPath` are NOT propagated by
  ///   the hub in v1.
  Future<List<Map<String, dynamic>>> sendBatch({
    required String agentId,
    required List<RelayBatchItem> items,
    Duration? timeout,
    int? timeoutMs,
    RelayPayloadFrameCompression compression =
        RelayPayloadFrameCompression.auto,
  });

  /// Fails the pending unary future or streaming controller for
  /// [clientRequestId] with [RelayRequestCancelled], if still registered.
  ///
  /// Idempotent: unknown or already-settled ids are ignored.
  ///
  /// Does **not** notify the hub (same limitation as cancelling a
  /// [sendStreaming] subscription).
  void cancel(String clientRequestId, {String reason = 'caller_cancelled'});

  /// Fail-fast every in-flight unary/streaming waiter and return open
  /// stream ids so the caller can emit hub `sql.cancel`.
  ///
  /// Used by E2E teardown and navigation-away so the next SQL call is
  /// not queued behind abandoned streams. Unary agent work is still
  /// best-effort only (see `sql_cancel_contract_colmeia_map.md`).
  List<AgentSqlOpenStream> cancelAllPending({
    String reason = 'caller_cancelled',
  });

  /// Broadcast stream of outcomes (success or failure). Subscribers from
  /// the presence layer / metrics see exactly one event per `sendUnary`
  /// or `sendStreaming` invocation.
  Stream<RelayRpcOutcome> outcomes();

  Future<void> dispose();
}
