import 'dart:async';

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/observability/socket/server_timings.dart';
import 'package:colmeia/core/observability/socket/socket_channel_metrics.dart';
import 'package:colmeia/core/socket/agent_latency_oracle.dart';
import 'package:colmeia/core/socket/agent_sql_open_stream.dart';
import 'package:colmeia/core/socket/consumer_socket_app_error_codes.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/consumer_socket_terminal_exception.dart';
import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:colmeia/core/socket/payload_frame_codec.dart';
import 'package:colmeia/core/socket/per_agent_concurrency_gate.dart';
import 'package:colmeia/core/socket/relay/relay_batch_item.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/core/socket/relay/relay_conversation.dart';
import 'package:colmeia/core/socket/relay/relay_conversation_ended_router.dart';
import 'package:colmeia/core/socket/relay/relay_conversation_manager.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:colmeia/core/socket/relay/relay_rpc_outcome.dart';
import 'package:colmeia/core/socket/relay/relay_streaming_capable_command.dart';
import 'package:colmeia/core/socket/socket_app_error_retry_after.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/core/socket/socket_wire_utils.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

part 'relay_pending_entries.dart';

/// Default `RelayCommandDispatcher`. Wraps a `ConsumerSocketConnection`
/// (for `emit`) and a `RelayConversationManager` (for the conversation
/// lifecycle). Listens to the four data events
/// (`accepted` / `response` / `chunk` / `complete`) once per connection and
/// fans them out by `client_request_id` / `requestId`.
///
/// `relay:rpc.response`, `relay:rpc.chunk`, and `relay:rpc.complete` payloads
/// are decoded with [PayloadFrameCodec.decodeJsonAsync] on a **per-request
/// chain** so chunk ordering and credit refills stay consistent. Wire
/// handlers return immediately; tests and tools must flush the event queue
/// (e.g. `pumpEventQueue` from `flutter_test`) before asserting on side
/// effects that follow decode.
///
/// Two pending kinds share the same routing path:
///
/// - [_PendingUnary] — single-shot request (`sendUnary`).
/// - [_PendingStream] — chunked request (`sendStreaming`) with auto-pull.
class RelayCommandDispatcherImpl implements RelayCommandDispatcher {
  RelayCommandDispatcherImpl({
    required ConsumerSocketConnection connection,
    required RelayConversationManager conversationManager,
    PayloadFrameCodec? codec,
    PerAgentConcurrencyGate? concurrencyGate,
    SocketChannelMetrics? channelMetrics,
    AgentLatencyOracle? latencyOracle,
    Duration defaultTimeout = const Duration(seconds: 30),
    RelayPayloadFrameCompression defaultCompression =
        RelayPayloadFrameCompression.auto,
    int defaultStreamInitialWindow = 32,
    int defaultStreamRefillThreshold = 16,
    RelayConversationEndedRouter? conversationEndedRouter,
  }) : _connection = connection,
       _conversationManager = conversationManager,
       _codec = codec ?? const PayloadFrameCodec(),
       _concurrencyGate = concurrencyGate,
       _channelMetrics = channelMetrics,
       _latencyOracle = latencyOracle,
       _defaultTimeout = defaultTimeout,
       _defaultCompression = defaultCompression,
       _defaultStreamInitialWindow = defaultStreamInitialWindow,
       _defaultStreamRefillThreshold = defaultStreamRefillThreshold,
       _conversationEndedRouter = conversationEndedRouter,
       _outcomes = StreamController<RelayRpcOutcome>.broadcast() {
    _stateSub = _connection.states().listen(_onConnectionState);
    if (_conversationEndedRouter != null) {
      void handler({
        required String conversationId,
        String? requestId,
        String? reason,
      }) {
        _onHubConversationEnded(
          conversationId: conversationId,
          reason: reason,
        );
      }

      _routerCallback = handler;
      _conversationEndedRouter.addListener(handler);
    }
  }

  final ConsumerSocketConnection _connection;
  final RelayConversationManager _conversationManager;
  final PayloadFrameCodec _codec;
  final PerAgentConcurrencyGate? _concurrencyGate;
  final SocketChannelMetrics? _channelMetrics;
  final AgentLatencyOracle? _latencyOracle;
  final Duration _defaultTimeout;
  final RelayPayloadFrameCompression _defaultCompression;
  final int _defaultStreamInitialWindow;
  final int _defaultStreamRefillThreshold;
  final StreamController<RelayRpcOutcome> _outcomes;

  /// Pending requests keyed by `client_request_id`. The `requestId` (server
  /// id) is filled in when `relay:rpc.accepted` arrives so subsequent
  /// `response` / `complete` events can be routed by either id — the hub
  /// uses `requestId` for downstream events.
  final Map<String, _PendingRelay> _pendingByClientId =
      <String, _PendingRelay>{};

  /// Reverse index from server-assigned `requestId` to `client_request_id`.
  /// Populated after `relay:rpc.accepted`, and also after a fast-path body
  /// `id` lookup so a following `rpc.complete` can use the O(1) map.
  final Map<String, String> _clientIdByRequestId = <String, String>{};

  /// Client request ids belonging to the most recently emitted batch per
  /// `conversationId`. Used to scope envelope-level rejections without
  /// failing unrelated pendings on the same conversation.
  final Map<String, Set<String>> _activeBatchClientIdsByConversationId =
      <String, Set<String>>{};

  /// Client request ids currently pending per `conversationId`. Used for
  /// O(1) routing in [_pendingRouteFromFrame] when the hub omits `requestId` on
  /// the frame and exactly one RPC is in flight for that conversation.
  final Map<String, Set<String>> _pendingClientIdsByConversationId =
      <String, Set<String>>{};

  void _registerPendingConversation(
    String conversationId,
    String clientRequestId,
  ) {
    _pendingClientIdsByConversationId
        .putIfAbsent(conversationId, () => <String>{})
        .add(clientRequestId);
  }

  void _unregisterPendingConversation(
    String conversationId,
    String clientRequestId,
  ) {
    final set = _pendingClientIdsByConversationId[conversationId];
    if (set == null) {
      return;
    }
    set.remove(clientRequestId);
    if (set.isEmpty) {
      _pendingClientIdsByConversationId.remove(conversationId);
    }
  }

  final RelayConversationEndedRouter? _conversationEndedRouter;
  ConversationEndedCallback? _routerCallback;

  StreamSubscription<ConsumerSocketConnectionState>? _stateSub;
  io.Socket? _attachedSocket;
  bool _isDisposed = false;

  /// Serializes fast-path frames that still need an async body decode
  /// before a pending can be identified.
  Future<void> _unresolvedFrameChain = Future<void>.value();

  @override
  Stream<RelayRpcOutcome> outcomes() => _outcomes.stream;

  @override
  Future<Map<String, dynamic>> sendUnary({
    required String agentId,
    required Map<String, Object?> body,
    required String clientRequestId,
    Duration? timeout,
    int? timeoutMs,
    RelayPayloadFrameCompression compression =
        RelayPayloadFrameCompression.auto,
  }) async {
    final pending = await _prepareSend<_PendingUnary>(
      agentId: agentId,
      clientRequestId: clientRequestId,
      makePending:
          ({
            required resolvedAgentId,
            required resolvedConversationId,
            required resolvedMethod,
            required stopwatch,
          }) {
            return _PendingUnary(
              agentId: resolvedAgentId,
              conversationId: resolvedConversationId,
              clientRequestId: clientRequestId,
              method: resolvedMethod,
              stopwatch: stopwatch,
            );
          },
    );
    final gate = _concurrencyGate;
    if (gate != null) {
      try {
        await gate.acquire(
          pending.agentId,
          onQueuedWaiter: (c) => pending.gateQueueWaitCompleter = c,
        );
      } on GateQueueWaitCancelled {
        return pending.completer.future;
      } on Object catch (e, s) {
        _failPending(
          clientRequestId,
          RelayConversationStartFailure(
            message: 'relay concurrency gate acquire failed: $e',
            conversationId: pending.conversationId,
            clientRequestId: clientRequestId,
            cause: e,
            stackTrace: s,
          ),
        );
        return pending.completer.future;
      }
      if (!_pendingByClientId.containsKey(clientRequestId)) {
        gate.release(pending.agentId);
        return pending.completer.future;
      }
      pending.relayPerAgentSlotRelease = () => gate.release(pending.agentId);
    }
    pending.gateQueueWaitCompleter = null;
    _armPendingTimeout(pending, timeout, rpcMethodHint: _extractMethod(body));
    await _emitRpcRequestAsync(
      conversationId: pending.conversationId,
      clientRequestId: clientRequestId,
      body: body,
      compression: compression,
      pending: pending,
      // Unary RPCs can opt into the hub fast-path: if enabled, the hub
      // skips `relay:rpc.accepted` on the happy path and goes straight
      // from `rpc.request` → `rpc.response`. Never combine fastPath with
      // streaming-capable bodies (prefer_db_streaming / multi_result /
      // sql.executeBatch) — the hub rejects that with
      // `accepted { success: false, clientRequestId }` (BAD_REQUEST).
      allowFastPath: !isRelayStreamingCapableRpcBody(body),
      timeoutMs: timeoutMs,
    );
    return pending.completer.future;
  }

  @override
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
  }) {
    final controller = StreamController<Map<String, dynamic>>();

    void reportUnhandledStreamError(Object error, StackTrace stack) {
      _channelMetrics?.recordRelayStreamingUnhandledError();
      if (controller.isClosed) {
        return;
      }
      controller.addError(
        RelayConversationStartFailure(
          message: 'unhandled relay stream error: $error',
          cause: error,
          stackTrace: stack,
        ),
      );
      unawaited(controller.close());
    }

    unawaited(
      (() async {
        final window = initialWindowSize ?? _defaultStreamInitialWindow;
        final threshold = refillThreshold ?? _defaultStreamRefillThreshold;
        final _PendingStream pending;
        try {
          pending = await _prepareSend<_PendingStream>(
            agentId: agentId,
            clientRequestId: clientRequestId,
            makePending:
                ({
                  required resolvedAgentId,
                  required resolvedConversationId,
                  required resolvedMethod,
                  required stopwatch,
                }) {
                  return _PendingStream(
                    agentId: resolvedAgentId,
                    conversationId: resolvedConversationId,
                    clientRequestId: clientRequestId,
                    method: resolvedMethod,
                    stopwatch: stopwatch,
                    controller: controller,
                    initialWindow: window,
                    refillThreshold: threshold,
                  );
                },
          );
        } on RelayDispatchException catch (e) {
          if (!controller.isClosed) {
            controller.addError(e);
            // close() returns Future<void>; subscribers observe the error
            // via the stream subscription, no need to await here.
            unawaited(controller.close());
          }
          return;
        } on SocketDispatchException catch (e) {
          if (!controller.isClosed) {
            controller.addError(e);
            unawaited(controller.close());
          }
          return;
        } on Object catch (e, s) {
          if (!controller.isClosed) {
            controller.addError(
              RelayConversationStartFailure(
                message: 'failed to prepare relay stream: $e',
                cause: e,
                stackTrace: s,
              ),
            );
            unawaited(controller.close());
          }
          return;
        }
        final gate = _concurrencyGate;
        if (gate != null) {
          try {
            await gate.acquire(
              pending.agentId,
              onQueuedWaiter: (c) => pending.gateQueueWaitCompleter = c,
            );
          } on GateQueueWaitCancelled {
            return;
          } on Object catch (e, s) {
            _failPending(
              clientRequestId,
              RelayConversationStartFailure(
                message: 'relay concurrency gate acquire failed: $e',
                conversationId: pending.conversationId,
                clientRequestId: clientRequestId,
                cause: e,
                stackTrace: s,
              ),
            );
            return;
          }
          if (!_pendingByClientId.containsKey(clientRequestId)) {
            gate.release(pending.agentId);
            return;
          }
          pending.relayPerAgentSlotRelease = () =>
              gate.release(pending.agentId);
        }
        pending.gateQueueWaitCompleter = null;
        _armPendingTimeout(
          pending,
          timeout,
          rpcMethodHint: _extractMethod(body),
        );
        await _emitRpcRequestAsync(
          conversationId: pending.conversationId,
          clientRequestId: clientRequestId,
          body: body,
          compression: compression,
          pending: pending,
          timeoutMs: timeoutMs,
        );
      })().catchError((Object error, StackTrace stack) async {
        reportUnhandledStreamError(error, stack);
      }),
    );

    return controller.stream;
  }

  @override
  Future<List<Map<String, dynamic>>> sendBatch({
    required String agentId,
    required List<RelayBatchItem> items,
    Duration? timeout,
    int? timeoutMs,
    RelayPayloadFrameCompression compression =
        RelayPayloadFrameCompression.auto,
  }) async {
    if (_isDisposed) {
      throw const RelayDispatcherDisposed(message: 'Dispatcher disposed');
    }
    if (items.isEmpty) {
      throw const RelayRequestRejected(
        message: 'relay batch requires at least one item',
        serverCode: 'BATCH_EMPTY',
      );
    }
    if (items.length > _maxBatchItems) {
      throw RelayRequestRejected(
        message:
            'relay batch is capped at $_maxBatchItems items '
            '(got ${items.length}); split the call site.',
        serverCode: 'BATCH_TOO_LARGE',
      );
    }
    // Defensive duplicate detection — the hub fails the whole envelope
    // with BATCH_DUPLICATE_ID, but catching it client-side avoids the
    // round-trip and the `_pendingByClientId` collision below.
    final seen = <String>{};
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      if (!seen.add(item.clientRequestId)) {
        throw RelayRequestRejected(
          message:
              'relay batch contains duplicate clientRequestId '
              '"${item.clientRequestId}"',
          serverCode: 'BATCH_DUPLICATE_ID',
        );
      }
      if (isRelayStreamingCapableRpcBody(item.body)) {
        throw RelayRequestRejected(
          message:
              'relay batch item[$index] is streaming-capable '
              '(prefer_db_streaming / multi_result / sql.executeBatch); '
              'hub would reject with BATCH_STREAMING_ITEM_REJECTED',
          serverCode: 'BATCH_STREAMING_ITEM_REJECTED',
          clientRequestId: item.clientRequestId,
        );
      }
    }
    final concurrencyCeiling = _concurrencyGate?.maxInflightPerAgent;
    if (concurrencyCeiling != null && items.length > concurrencyCeiling) {
      throw RelayRequestRejected(
        message:
            'relay batch size ${items.length} exceeds per-agent concurrency '
            'ceiling $concurrencyCeiling; split the call site or raise '
            'SOCKET_MAX_INFLIGHT_PER_AGENT',
        serverCode: 'BATCH_TOO_LARGE',
      );
    }

    // Register N pendings sharing the same conversation. The first call
    // resolves the conversation; subsequent items piggyback. Any failure
    // before emit (gate, conversation, encode) propagates as the envelope
    // failure so every item completes with the same error.
    final pendings = <_PendingUnary>[];
    String? conversationId;
    String? sharedAgentId;
    try {
      for (final item in items) {
        final pending = await _prepareSend<_PendingUnary>(
          agentId: agentId,
          clientRequestId: item.clientRequestId,
          makePending:
              ({
                required resolvedAgentId,
                required resolvedConversationId,
                required resolvedMethod,
                required stopwatch,
              }) {
                conversationId ??= resolvedConversationId;
                sharedAgentId ??= resolvedAgentId;
                return _PendingUnary(
                  agentId: resolvedAgentId,
                  conversationId: resolvedConversationId,
                  clientRequestId: item.clientRequestId,
                  method: _extractMethod(item.body),
                  stopwatch: stopwatch,
                );
              },
        );
        pendings.add(pending);
      }
    } on Object catch (e, s) {
      // Roll back any partial registration so siblings do not leak.
      for (final pending in pendings) {
        _failPending(
          pending.clientRequestId,
          e is RelayDispatchException
              ? e
              : RelayConversationStartFailure(
                  message: 'failed to prepare relay batch: $e',
                  cause: e,
                  stackTrace: s,
                ),
        );
      }
      rethrow;
    }

    final gate = _concurrencyGate;
    if (gate != null) {
      try {
        // Atomic multi-slot reserve: acquiring one slot per item in a loop
        // deadlocks when batch size > maxInflight (slots held by this batch
        // never free until emit, but emit waits on the remaining acquires).
        // Hub still sees N inflight items; we just reserve them together.
        final slotAgentId = sharedAgentId ?? agentId;
        await gate.acquireSlots(
          slotAgentId,
          pendings.length,
          onQueuedWaiter: (c) {
            for (final pending in pendings) {
              pending.gateQueueWaitCompleter = c;
            }
          },
        );
        for (final pending in pendings) {
          pending
            ..relayPerAgentSlotRelease = (() => gate.release(pending.agentId))
            ..gateQueueWaitCompleter = null;
        }
      } on Object catch (e, s) {
        final failure = e is GateQueueWaitCancelled
            ? RelayRequestCancelled(
                message: 'relay batch gate wait cancelled',
                conversationId: conversationId,
              )
            : RelayConversationStartFailure(
                message: 'relay batch gate acquire failed: $e',
                cause: e,
                stackTrace: s,
              );
        for (final pending in pendings) {
          _failPending(pending.clientRequestId, failure);
        }
        return _collectBatchResults(pendings);
      }
    }

    final effectiveTimeout = timeout ?? _resolveBatchTimeout(items);
    for (var i = 0; i < pendings.length; i++) {
      _armPendingTimeout(
        pendings[i],
        items[i].timeout ?? effectiveTimeout,
        rpcMethodHint: _extractMethod(items[i].body),
      );
    }

    // Encode the JSON-RPC array as a single PayloadFrame.
    PayloadFrameEncodeResult encoded;
    final encodeSw = Stopwatch()..start();
    try {
      encoded = await _codec.encodeJsonAsync(
        items.map((item) => item.body).toList(growable: false),
      );
      encodeSw.stop();
      _channelMetrics?.recordRelayPayloadEncodeWallClock(
        elapsed: encodeSw.elapsed,
      );
    } on PayloadFrameDecodeException catch (e, s) {
      encodeSw.stop();
      _channelMetrics?.recordRelayPayloadEncodeWallClock(
        elapsed: encodeSw.elapsed,
      );
      _channelMetrics?.recordRelayDecodeFailure(code: e.code);
      final failure = RelayDecodeFailure(
        message: 'failed to encode relay batch: ${e.message}',
        code: e.code,
        conversationId: conversationId,
        cause: e,
        stackTrace: s,
      );
      for (final pending in pendings) {
        _failPending(pending.clientRequestId, failure);
      }
      return _collectBatchResults(pendings);
    }

    final emittedAt = pendings.first.stopwatch.elapsed;
    try {
      final resolvedConversationId = conversationId;
      if (resolvedConversationId != null) {
        _activeBatchClientIdsByConversationId[resolvedConversationId] = pendings
            .map((p) => p.clientRequestId)
            .toSet();
      }
      final hubTimeoutMs = _resolveBatchHubTimeoutMs(items, timeoutMs);
      _connection.raw.emit(
        RelayEventNames.rpcRequestBatch,
        <String, Object?>{
          'conversationId': conversationId,
          'frame': encoded.frame.toMap(),
          'payloadFrameCompression':
              (compression == RelayPayloadFrameCompression.auto
                      ? _defaultCompression
                      : compression)
                  .wireValue,
          if (AppEnvironment.socketRequestServerTimingsEnabled)
            'requestServerTimings': true,
          'timeoutMs': ?hubTimeoutMs,
        },
      );
      for (final pending in pendings) {
        pending.requestEmittedAtElapsed = emittedAt;
      }
    } on Object catch (e, s) {
      final failure = RelayConversationLost(
        message: 'failed to emit relay:rpc.request.batch: $e',
        conversationId: conversationId,
        cause: e,
        stackTrace: s,
      );
      for (final pending in pendings) {
        _failPending(pending.clientRequestId, failure);
      }
    }

    return _collectBatchResults(pendings);
  }

  /// Awaits every pending's completer and collects responses in the
  /// caller-supplied order. Per-item failures are surfaced as
  /// [RelayDispatchException]; envelope failures already populated every
  /// completer with the same exception, so the first error rethrows.
  ///
  /// We use [Future.wait] (over a manual `for await`) so that errors on
  /// **every** sibling future receive a handler at the same microtask —
  /// otherwise an envelope-level failure that completes 32 completers
  /// at once would surface only the first error and leak the others as
  /// "unhandled" into the surrounding zone.
  Future<List<Map<String, dynamic>>> _collectBatchResults(
    List<_PendingUnary> pendings,
  ) {
    return Future.wait<Map<String, dynamic>>(
      pendings.map((pending) => pending.completer.future),
    );
  }

  /// Hub-side cap on items per `relay:rpc.request.batch` envelope (v1).
  /// Mirrored client-side so callers see the same failure shape without a
  /// round-trip. Source: hub doc `adrs/0008-relay-batch-protocol.md`.
  static const int _maxBatchItems = 32;

  Duration _resolveBatchTimeout(List<RelayBatchItem> items) {
    Duration? max;
    for (final item in items) {
      final value = item.timeout;
      if (value != null && (max == null || value > max)) {
        max = value;
      }
    }
    return max ?? _defaultTimeout;
  }

  int? _resolveBatchHubTimeoutMs(List<RelayBatchItem> items, int? timeoutMs) {
    var max = _normalizeHubTimeoutMs(timeoutMs);
    for (final item in items) {
      final itemMs = _normalizeHubTimeoutMs(item.timeoutMs);
      if (itemMs == null) {
        continue;
      }
      if (max == null || itemMs > max) {
        max = itemMs;
      }
    }
    return max;
  }

  int? _normalizeHubTimeoutMs(int? timeoutMs) {
    if (timeoutMs == null || timeoutMs < 1) {
      return null;
    }
    return timeoutMs;
  }

  /// Routes the single `relay:rpc.batch_accepted` envelope received per
  /// emitted batch. Populates the `clientRequestId → requestId` map so
  /// the existing [_onResponseFrame] can route per-item responses, and
  /// fails any item the hub reported with an inline `error`.
  void _onBatchAccepted(Object? raw) {
    final map = _toMap(raw);
    if (map == null) {
      return;
    }
    final success = map['success'];
    if (success is bool && !success) {
      final error = _toMap(map['error']);
      final code = error?['code']?.toString() ?? 'request_rejected';
      final message =
          error?['message']?.toString() ??
          'relay:rpc.batch_accepted reported success=false';
      final details = _toMap(error?['details']) ?? _toMap(map['details']);
      _failBatchByEnvelopeId(
        map,
        RelayRequestRejected(
          message: message,
          serverCode: code,
          retryAfter: extractRetryAfterFromAppError(map),
          availableSlots: _positiveIntOrNull(
            details?['availableSlots'] ?? details?['available_slots'],
          ),
          requestedSlots: _positiveIntOrNull(
            details?['requestedSlots'] ?? details?['requested_slots'],
          ),
        ),
      );
      return;
    }
    final items = map['items'];
    if (items is! List) {
      _failBatchByEnvelopeId(
        map,
        const RelayDecodeFailure(
          message: 'relay:rpc.batch_accepted missing items',
        ),
      );
      return;
    }
    for (final raw in items) {
      if (raw is! Map) {
        continue;
      }
      final item = raw.cast<String, Object?>();
      final clientRequestId = item['clientRequestId']?.toString();
      if (clientRequestId == null || clientRequestId.isEmpty) {
        continue;
      }
      final pending = _pendingByClientId[clientRequestId];
      if (pending == null) {
        continue;
      }
      // Record the request→accepted phase metric the same way unary does.
      final acceptedAt = pending.stopwatch.elapsed;
      final emittedAt = pending.requestEmittedAtElapsed;
      if (emittedAt != null && acceptedAt >= emittedAt) {
        _channelMetrics?.recordRelayRequestToAccepted(
          elapsed: acceptedAt - emittedAt,
        );
      }
      final itemError = _toMap(item['error']);
      if (itemError != null) {
        final code = itemError['code']?.toString() ?? 'item_failed';
        final message =
            itemError['message']?.toString() ?? 'relay batch item failed';
        _failPending(
          clientRequestId,
          RelayRequestRejected(
            message: message,
            serverCode: code,
            retryAfter: extractRetryAfterFromAppError(itemError),
            conversationId: pending.conversationId,
            clientRequestId: clientRequestId,
          ),
        );
        continue;
      }
      final requestId = item['requestId']?.toString();
      if (requestId != null && requestId.isNotEmpty) {
        pending.requestId = requestId;
        _clientIdByRequestId[requestId] = clientRequestId;
      }
      pending
        ..deduplicated = item['deduplicated'] == true
        ..replayed = item['replayed'] == true
        ..inFlight = item['inFlight'] == true
        ..unaryAcceptedAtElapsed = acceptedAt;
      if (pending.inFlight) {
        _channelMetrics?.recordRelayAcceptedInFlight();
      }
    }
  }

  /// Drops every pending referenced by [batchPayload] when the hub
  /// rejected the whole envelope. The reject ack typically omits
  /// per-item `clientRequestId`s; we infer the set from the
  /// `conversationId` and fail every pending currently tracked there.
  void _failBatchByEnvelopeId(
    Map<String, Object?> batchPayload,
    RelayDispatchException failure,
  ) {
    final items = batchPayload['items'];
    if (items is List) {
      for (final raw in items) {
        if (raw is! Map) {
          continue;
        }
        final clientRequestId = raw
            .cast<String, Object?>()['clientRequestId']
            ?.toString();
        if (clientRequestId != null && clientRequestId.isNotEmpty) {
          _failPending(clientRequestId, failure);
        }
      }
      return;
    }
    final conversationId = batchPayload['conversationId']?.toString();
    if (conversationId == null) {
      return;
    }
    final batchClientIds = _activeBatchClientIdsByConversationId.remove(
      conversationId,
    );
    if (batchClientIds == null || batchClientIds.isEmpty) {
      AppLogger.warning(
        'relay batch envelope rejected without item list or active batch ids',
        context: <String, Object?>{
          'component': 'RelayCommandDispatcherImpl',
          'conversationId': conversationId,
        },
      );
      return;
    }
    for (final clientRequestId in batchClientIds) {
      _failPending(clientRequestId, failure);
    }
  }

  @override
  void cancel(String clientRequestId, {String reason = 'caller_cancelled'}) {
    if (_isDisposed) {
      return;
    }
    _failPending(
      clientRequestId,
      RelayRequestCancelled(
        message: 'Relay request cancelled by caller (reason=$reason)',
        clientRequestId: clientRequestId,
      ),
    );
  }

  @override
  List<AgentSqlOpenStream> cancelAllPending({
    String reason = 'caller_cancelled',
  }) {
    if (_isDisposed) {
      return const <AgentSqlOpenStream>[];
    }
    final streams = <AgentSqlOpenStream>[];
    final ids = _pendingByClientId.keys.toList(growable: false);
    for (final pending in _pendingByClientId.values) {
      if (pending is! _PendingStream) {
        continue;
      }
      final streamId = pending.streamId?.trim();
      if (streamId == null || streamId.isEmpty) {
        continue;
      }
      streams.add(
        AgentSqlOpenStream(agentId: pending.agentId, streamId: streamId),
      );
    }
    for (final clientRequestId in ids) {
      cancel(clientRequestId, reason: reason);
    }
    return streams;
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    final cb = _routerCallback;
    if (cb != null) {
      _conversationEndedRouter?.removeListener(cb);
      _routerCallback = null;
    }
    await _stateSub?.cancel();
    _stateSub = null;
    _detachListeners();
    final pending = _pendingByClientId.values.toList(growable: false);
    _pendingByClientId.clear();
    _clientIdByRequestId.clear();
    _pendingClientIdsByConversationId.clear();
    for (final entry in pending) {
      entry.timeoutTimer?.cancel();
      entry.failExternally(
        RelayDispatcherDisposed(
          message: 'Relay dispatcher disposed mid-flight',
          conversationId: entry.conversationId,
          clientRequestId: entry.clientRequestId,
        ),
      );
      _releaseRelayGateSlot(entry);
    }
    if (!_outcomes.isClosed) {
      await _outcomes.close();
    }
  }

  // ----- Internals -----

  /// Shared preparation for both `sendUnary` and `sendStreaming`. Resolves
  /// the conversation, registers the pending entry, and hands the typed
  /// pending back so callers can either await its completer or wire its stream
  /// controller before acquiring backpressure and emitting on the wire.
  ///
  /// The request timeout is armed after the per-agent gate is acquired. Gate
  /// wait time is controlled by [PerAgentConcurrencyGate]; request timeout
  /// covers the actual relay round-trip.
  Future<T> _prepareSend<T extends _PendingRelay>({
    required String agentId,
    required String clientRequestId,
    required T Function({
      required String resolvedAgentId,
      required String resolvedConversationId,
      required String? resolvedMethod,
      required Stopwatch stopwatch,
    })
    makePending,
  }) async {
    if (_isDisposed) {
      throw const RelayDispatcherDisposed(message: 'Dispatcher disposed');
    }
    if (_pendingByClientId.containsKey(clientRequestId)) {
      throw RelayDuplicateRequestId(
        message: 'clientRequestId already pending: $clientRequestId',
        conversationId: _pendingByClientId[clientRequestId]!.conversationId,
        clientRequestId: clientRequestId,
      );
    }

    final RelayConversation conversation;
    try {
      conversation = await _conversationManager.obtain(agentId);
    } on RelayDispatchException {
      rethrow;
    }
    // `_conversationManager.obtain` calls `_connection.connect()` which
    // surfaces terminal handshake failures as typed
    // [ConsumerSocketTerminalException]. We MUST translate them to the shared
    // `SocketDispatch*` exceptions BEFORE the generic Object catch below so
    // `SocketWithRestFallbackAgentQueriesRemoteDataSource` can distinguish
    // "hub forbidden / auth dead" (latch + REST) from transient relay
    // failures (surface as-is).
    on ConsumerSocketTerminalException catch (e) {
      switch (e) {
        case ConsumerSocketNamespaceForbidden():
          throw SocketDispatchNamespaceForbidden(
            message: e.message,
            role: e.role,
            namespace: e.namespace,
            cause: e,
          );
        case ConsumerSocketReconnectExhausted():
        case ConsumerSocketConnectCancelled():
        case ConsumerSocketHubForcedDisconnect():
          throw SocketDispatchDisconnected(
            message: 'Cannot start relay conversation: $e',
            cause: e,
          );
        case ConsumerSocketAuthFailed():
          throw SocketDispatchUnauthorized(
            message: 'Cannot start relay conversation: $e',
            cause: e,
          );
      }
    } on Object catch (e, s) {
      throw RelayConversationStartFailure(
        message: 'failed to obtain relay conversation: $e',
        cause: e,
        stackTrace: s,
      );
    }
    final conversationId = conversation.conversationId!;

    _ensureListenersAttached();

    final stopwatch = Stopwatch()..start();
    final pending = makePending(
      resolvedAgentId: agentId,
      resolvedConversationId: conversationId,
      resolvedMethod: null,
      stopwatch: stopwatch,
    );
    _pendingByClientId[clientRequestId] = pending;
    _registerPendingConversation(conversationId, clientRequestId);
    return pending;
  }

  void _armPendingTimeout(
    _PendingRelay pending,
    Duration? timeout, {
    String? rpcMethodHint,
  }) {
    if (!_pendingByClientId.containsKey(pending.clientRequestId)) {
      return;
    }
    final method = pending.method ?? rpcMethodHint;
    var effectiveTimeout = timeout ?? _defaultTimeout;
    final oracle = _latencyOracle;
    if (timeout == null && oracle != null && method != null) {
      effectiveTimeout = oracle.suggestTimeout(
        agentId: pending.agentId,
        method: method,
        fallback: _defaultTimeout,
        ceiling: _defaultTimeout,
      );
    }
    pending.timeoutTimer = Timer(effectiveTimeout, () {
      _failPending(
        pending.clientRequestId,
        RelayRequestTimeout(
          message:
              'No response for clientRequestId=${pending.clientRequestId} after '
              '${effectiveTimeout.inSeconds}s',
          conversationId: pending.conversationId,
          clientRequestId: pending.clientRequestId,
        ),
      );
    });
  }

  /// Encodes [body] as a PayloadFrame and emits `relay:rpc.request`.
  /// Callers stash the typed pending; this method only knows how to
  /// translate a logical body into the wire envelope and surface
  /// transport-level failures back through [_failPending].
  ///
  /// [allowFastPath] is `true` only for unary RPCs whose semantics
  /// tolerate the hub skipping `relay:rpc.accepted`. Streaming RPCs
  /// MUST keep the three-event flow because the initial pull window
  /// depends on the accepted hop arriving first.
  Future<void> _emitRpcRequestAsync({
    required String conversationId,
    required String clientRequestId,
    required Map<String, Object?> body,
    required RelayPayloadFrameCompression compression,
    required _PendingRelay pending,
    bool allowFastPath = false,
    int? timeoutMs,
  }) async {
    pending.method ??= _extractMethod(body);
    PayloadFrameEncodeResult encoded;
    final encodeSw = Stopwatch()..start();
    try {
      // The client_request_id in the JSON-RPC `id` field is what makes the
      // hub idempotent, so we mirror it on the envelope `requestId` for
      // observability — the hub ignores envelope.requestId on inbound.
      encoded = await _codec.encodeJsonAsync(
        body,
        requestId: clientRequestId,
      );
      encodeSw.stop();
      _channelMetrics?.recordRelayPayloadEncodeWallClock(
        elapsed: encodeSw.elapsed,
      );
    } on PayloadFrameDecodeException catch (e, s) {
      encodeSw.stop();
      _channelMetrics?.recordRelayPayloadEncodeWallClock(
        elapsed: encodeSw.elapsed,
      );
      _channelMetrics?.recordRelayDecodeFailure(code: e.code);
      _failPending(
        clientRequestId,
        RelayDecodeFailure(
          message: 'failed to encode relay request: ${e.message}',
          code: e.code,
          conversationId: conversationId,
          clientRequestId: clientRequestId,
          cause: e,
          stackTrace: s,
        ),
      );
      return;
    }

    final useFastPath =
        allowFastPath && AppEnvironment.socketRelayFastPathEnabled;
    // Per-request hub wait via envelope `timeoutMs` (REST parity through
    // computeBridgeWaitTimeoutMs). See docs/plug_server/relay_envelope_timeout_ms.md.
    final hubTimeoutMs = _normalizeHubTimeoutMs(timeoutMs);
    try {
      _connection.raw.emit(
        RelayEventNames.rpcRequest,
        <String, Object?>{
          'conversationId': conversationId,
          'frame': encoded.frame.toMap(),
          'payloadFrameCompression':
              (compression == RelayPayloadFrameCompression.auto
                      ? _defaultCompression
                      : compression)
                  .wireValue,
          if (AppEnvironment.socketRequestServerTimingsEnabled)
            'requestServerTimings': true,
          if (useFastPath) 'fastPath': true,
          'timeoutMs': ?hubTimeoutMs,
        },
      );
      pending.requestEmittedAtElapsed = pending.stopwatch.elapsed;
    } on Object catch (e, s) {
      _failPending(
        clientRequestId,
        RelayConversationLost(
          message: 'failed to emit relay:rpc.request: $e',
          conversationId: conversationId,
          clientRequestId: clientRequestId,
          cause: e,
          stackTrace: s,
        ),
      );
    }
  }

  void _ensureListenersAttached() {
    final socket = _connection.raw;
    if (identical(_attachedSocket, socket)) {
      return;
    }
    _detachListeners();
    socket
      ..on(RelayEventNames.rpcAccepted, _onAccepted)
      ..on(RelayEventNames.rpcBatchAccepted, _onBatchAccepted)
      ..on(RelayEventNames.rpcResponse, _onResponseFrame)
      ..on(RelayEventNames.rpcChunk, _onChunkFrame)
      ..on(RelayEventNames.rpcComplete, _onCompleteFrame)
      ..on(RelayEventNames.rpcStreamPullResponse, _onStreamPullResponse)
      ..on(RelayEventNames.appError, _onAppError);
    _attachedSocket = socket;
    AppLogger.debug(
      'Attached relay listeners to active socket',
      context: <String, Object?>{
        'component': 'RelayCommandDispatcherImpl',
        'socketIdentity': identityHashCode(socket),
      },
    );
  }

  void _detachListeners() {
    final socket = _attachedSocket;
    if (socket == null) {
      return;
    }
    try {
      socket
        ..off(RelayEventNames.rpcAccepted, _onAccepted)
        ..off(RelayEventNames.rpcBatchAccepted, _onBatchAccepted)
        ..off(RelayEventNames.rpcResponse, _onResponseFrame)
        ..off(RelayEventNames.rpcChunk, _onChunkFrame)
        ..off(RelayEventNames.rpcComplete, _onCompleteFrame)
        ..off(RelayEventNames.rpcStreamPullResponse, _onStreamPullResponse)
        ..off(RelayEventNames.appError, _onAppError);
    } on Object catch (_) {
      // Socket is already being torn down; the next relay send will attach
      // listeners to the fresh raw socket instance.
    }
    _attachedSocket = null;
  }

  void _onConnectionState(ConsumerSocketConnectionState state) {
    switch (state) {
      case ConsumerSocketDisconnected(:final reason):
        _detachListeners();
        _failAllPending(
          (entry) => RelayConversationLost(
            message:
                'relay conversation lost because socket disconnected'
                '${reason == null ? '' : ' (reason=$reason)'}',
            conversationId: entry.conversationId,
            clientRequestId: entry.clientRequestId,
          ),
        );
      case ConsumerSocketError(:final message, :final cause):
        _detachListeners();
        _failAllPending(
          (entry) => RelayConversationLost(
            message: 'relay conversation lost after socket error: $message',
            conversationId: entry.conversationId,
            clientRequestId: entry.clientRequestId,
            cause: cause,
          ),
        );
      case ConsumerSocketUnauthorized():
        _detachListeners();
        _failAllPending(
          (entry) => RelayConversationLost(
            message: 'relay conversation lost because socket is unauthorized',
            conversationId: entry.conversationId,
            clientRequestId: entry.clientRequestId,
          ),
        );
      case ConsumerSocketConnected():
      case ConsumerSocketConnecting():
        break;
    }
  }

  void _onAppError(Object? raw) {
    final map = _toMap(raw);
    if (map == null) {
      return;
    }
    final error = _toMap(map['error']);
    final code =
        map['code']?.toString() ?? error?['code']?.toString() ?? 'app_error';
    final message =
        map['message']?.toString() ??
        map['userMessage']?.toString() ??
        error?['message']?.toString() ??
        code;
    final retryAfter = extractRetryAfterFromAppError(map);
    if (ConsumerSocketAppErrorCodes.isTerminal(code)) {
      _failAllPending(
        (entry) => RelayRequestRejected(
          message: message,
          serverCode: code,
          retryAfter: retryAfter,
          conversationId: entry.conversationId,
          clientRequestId: entry.clientRequestId,
        ),
      );
      return;
    }
    final clientRequestId = _resolveClientRequestIdForAppError(map);
    if (clientRequestId != null) {
      final pending = _pendingByClientId[clientRequestId];
      if (pending == null) {
        return;
      }
      _failPending(
        clientRequestId,
        RelayRequestRejected(
          message: message,
          serverCode: code,
          retryAfter: retryAfter,
          conversationId: pending.conversationId,
          clientRequestId: clientRequestId,
        ),
      );
      return;
    }
    if (_hasAppErrorCorrelationId(map)) {
      AppLogger.debug(
        'Ignoring relay app:error for non-pending request',
        context: <String, Object?>{
          'component': 'RelayCommandDispatcherImpl',
          'code': code,
          'topLevelKeys': map.keys.take(32).join(','),
        },
      );
      return;
    }
    _failAllPending(
      (entry) => RelayRequestRejected(
        message: message,
        serverCode: code,
        retryAfter: retryAfter,
        conversationId: entry.conversationId,
        clientRequestId: entry.clientRequestId,
      ),
    );
  }

  /// JSON-only ack for `relay:rpc.stream.pull`. Carries either:
  ///
  /// - `success: true` + `windowSize` actually granted (may be smaller
  ///   than what the dispatcher asked for) + a `rateLimit` snapshot;
  /// - `success: false` + `error.code` (typically `RATE_LIMITED`) + the
  ///   same `rateLimit` snapshot for diagnostics.
  ///
  /// On rejection we fail the streaming pending so the consumer learns
  /// **immediately** that no more chunks are coming, instead of waiting
  /// for the request timeout. The hub-supplied `Retry-After` hint
  /// (`error.data.retry_after_ms`) is preserved so the caller can throttle.
  void _onStreamPullResponse(Object? raw) {
    final map = _toMap(raw);
    if (map == null) {
      return;
    }
    final clientRequestId = _resolveClientRequestIdForPull(map);
    if (clientRequestId == null) {
      return;
    }
    final pending = _pendingByClientId[clientRequestId];
    if (pending is! _PendingStream) {
      return;
    }
    final success = map['success'];
    if (success is bool && !success) {
      final error = _toMap(map['error']);
      final code = error?['code']?.toString() ?? 'pull_rejected';
      final message =
          error?['message']?.toString() ??
          'relay:rpc.stream.pull_response reported success=false';
      _failPending(
        clientRequestId,
        RelayRequestRejected(
          message: message,
          serverCode: code,
          retryAfter: extractRetryAfterFromAppError(map),
          conversationId: pending.conversationId,
          clientRequestId: clientRequestId,
        ),
      );
      return;
    }
    final streamId = _extractStreamId(map);
    if (streamId != null) {
      pending.streamId = streamId;
    }
    final granted =
        _toIntOrNull(map['windowSize']) ?? _toIntOrNull(map['window_size']);
    if (granted != null &&
        granted >= 0 &&
        granted < pending.outstandingCredits) {
      // Hub clamped the window: align the local counter so the next refill
      // reflects what the server actually authorized.
      pending.outstandingCredits = granted;
    }
    final rateLimit = _toMap(map['rateLimit']) ?? _toMap(map['rate_limit']);
    final remainingCredits =
        _toIntOrNull(rateLimit?['remainingCredits']) ??
        _toIntOrNull(rateLimit?['remaining_credits']);
    if (remainingCredits != null && remainingCredits >= 0) {
      if (remainingCredits < pending.outstandingCredits) {
        pending.outstandingCredits = remainingCredits;
      }
      AppLogger.debug(
        'relay stream pull rateLimit snapshot',
        context: <String, Object?>{
          'component': 'RelayCommandDispatcherImpl',
          'clientRequestId': clientRequestId,
          'remainingCredits': remainingCredits,
          'limit': rateLimit?['limit'],
          'scope': rateLimit?['scope'],
        },
      );
    }
  }

  String? _resolveClientRequestIdForPull(Map<String, Object?> map) {
    final clientRequestId =
        map['clientRequestId']?.toString() ??
        map['client_request_id']?.toString();
    if (clientRequestId != null && clientRequestId.isNotEmpty) {
      return clientRequestId;
    }
    final requestId = map['requestId']?.toString();
    if (requestId != null && requestId.isNotEmpty) {
      return _clientIdByRequestId[requestId];
    }
    return null;
  }

  String? _resolveClientRequestIdForAppError(Map<String, Object?> map) {
    for (final key in <String>[
      'clientRequestId',
      'client_request_id',
      'rpcId',
      'rpc_id',
    ]) {
      final value = map[key]?.toString();
      if (value != null &&
          value.isNotEmpty &&
          _pendingByClientId.containsKey(value)) {
        return value;
      }
    }
    for (final key in <String>['requestId', 'request_id']) {
      final value = map[key]?.toString();
      if (value != null && value.isNotEmpty) {
        if (_pendingByClientId.containsKey(value)) {
          return value;
        }
        final clientRequestId = _clientIdByRequestId[value];
        if (clientRequestId != null) {
          return clientRequestId;
        }
      }
    }
    return null;
  }

  bool _hasAppErrorCorrelationId(Map<String, Object?> map) {
    for (final key in <String>[
      'clientRequestId',
      'client_request_id',
      'rpcId',
      'rpc_id',
      'requestId',
      'request_id',
    ]) {
      final value = map[key]?.toString();
      if (value != null && value.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  int? _toIntOrNull(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw.trim());
    }
    return null;
  }

  int? _positiveIntOrNull(Object? raw) {
    final value = _toIntOrNull(raw);
    if (value == null || value < 0) {
      return null;
    }
    return value;
  }

  void _onAccepted(Object? raw) {
    final map = _toMap(raw);
    if (map == null) {
      return;
    }
    final success = map['success'];
    final isRejection = success is bool && !success;
    final clientRequestId = map['clientRequestId']?.toString();
    if (clientRequestId == null || clientRequestId.isEmpty) {
      // Optional defense: hub now echoes clientRequestId on error accepted,
      // but older builds / early pre-decode failures may omit it. When
      // exactly one pending matches (optionally by conversationId), fail it
      // immediately instead of waiting for the client timer.
      if (isRejection) {
        _failOrphanAcceptedRejection(map);
      }
      return;
    }
    final pending = _pendingByClientId[clientRequestId];
    if (pending == null) {
      return;
    }
    if (isRejection) {
      _failAcceptedRejection(pending: pending, map: map);
      return;
    }
    final requestId = map['requestId']?.toString();
    if (requestId != null && requestId.isNotEmpty) {
      pending.requestId = requestId;
      _clientIdByRequestId[requestId] = clientRequestId;
    }
    pending
      ..deduplicated = map['deduplicated'] == true
      ..replayed = map['replayed'] == true
      ..inFlight = map['inFlight'] == true;

    if (pending.inFlight) {
      AppLogger.debug(
        'relay:rpc.accepted inFlight — waiting without resend',
        context: <String, Object?>{
          'component': 'RelayCommandDispatcherImpl',
          'clientRequestId': clientRequestId,
          'requestId': pending.requestId,
          'conversationId': pending.conversationId,
        },
      );
      _channelMetrics?.recordRelayAcceptedInFlight();
    }

    // Record the request→accepted phase for both unary and streaming
    // pendings. The emit timestamp can be null if the accept fires
    // before the emit Future returned (very rare; treat as 0 sample
    // instead by skipping).
    final acceptedAt = pending.stopwatch.elapsed;
    final emittedAt = pending.requestEmittedAtElapsed;
    if (emittedAt != null && acceptedAt >= emittedAt) {
      _channelMetrics?.recordRelayRequestToAccepted(
        elapsed: acceptedAt - emittedAt,
      );
    }

    // Streaming requests grant the initial pull window as soon as the hub
    // has acknowledged the request. Without an explicit budget the hub
    // would buffer chunks server-side and possibly abort the stream when
    // the buffer cap is hit.
    //
    // When inFlight=true this waiter must NOT grant a new pull window —
    // the original request already owns credits / stream state.
    if (pending is _PendingStream) {
      pending.streamAcceptedAtElapsed = acceptedAt;
      if (!pending.inFlight) {
        _enqueueRelayFrameWork(
          pending,
          () => _grantPullAsync(pending, pending.initialWindow),
        );
      }
    } else {
      pending.unaryAcceptedAtElapsed = acceptedAt;
    }
  }

  void _failAcceptedRejection({
    required _PendingRelay pending,
    required Map<String, dynamic> map,
  }) {
    final error = _toMap(map['error']);
    final code = error?['code']?.toString() ?? 'request_rejected';
    final message =
        error?['message']?.toString() ??
        'relay:rpc.accepted reported success=false';
    final acceptedConversationId = map['conversationId']?.toString();
    final conversationId =
        acceptedConversationId != null && acceptedConversationId.isNotEmpty
        ? acceptedConversationId
        : pending.conversationId;
    _failPending(
      pending.clientRequestId,
      RelayRequestRejected(
        message: message,
        serverCode: code,
        retryAfter: extractRetryAfterFromAppError(map),
        conversationId: conversationId,
        clientRequestId: pending.clientRequestId,
      ),
    );
  }

  void _failOrphanAcceptedRejection(Map<String, dynamic> map) {
    final conversationId = map['conversationId']?.toString();
    final candidates = _pendingByClientId.values
        .where((pending) {
          if (conversationId == null || conversationId.isEmpty) {
            return true;
          }
          return pending.conversationId == conversationId;
        })
        .toList(growable: false);
    if (candidates.length != 1) {
      AppLogger.warning(
        'Ignoring relay:rpc.accepted success=false without clientRequestId',
        context: <String, Object?>{
          'component': 'RelayCommandDispatcherImpl',
          'conversationId': conversationId,
          'pendingCandidates': candidates.length,
          'errorCode': _toMap(map['error'])?['code'],
        },
      );
      return;
    }
    _failAcceptedRejection(pending: candidates.single, map: map);
  }

  void _enqueueRelayFrameWork(
    _PendingRelay pending,
    Future<void> Function() work,
  ) {
    pending.frameRoutingChain = pending.frameRoutingChain.then<void>(
      (_) async {
        if (_isDisposed) {
          return;
        }
        if (!_pendingByClientId.containsKey(pending.clientRequestId)) {
          return;
        }
        try {
          await work();
        } on Object catch (e, s) {
          AppLogger.warning(
            'relay pending async work failed',
            context: <String, Object?>{
              'component': 'RelayCommandDispatcherImpl',
              'clientRequestId': pending.clientRequestId,
              'error': e.toString(),
            },
            error: e,
            stackTrace: s,
          );
        }
      },
    );
  }

  void _onResponseFrame(Object? raw) {
    _routeOrEnqueueRelayFrame(
      raw,
      eventName: 'rpc.response',
      markStreamTerminal: true,
    );
  }

  void _onChunkFrame(Object? raw) {
    _routeOrEnqueueRelayFrame(raw, eventName: 'rpc.chunk');
  }

  void _onCompleteFrame(Object? raw) {
    _routeOrEnqueueRelayFrame(
      raw,
      eventName: 'rpc.complete',
      markStreamTerminal: true,
    );
  }

  void _routeOrEnqueueRelayFrame(
    Object? raw, {
    required String eventName,
    bool markStreamTerminal = false,
  }) {
    final route = _pendingRouteFromFrame(raw);
    if (route != null) {
      final pending = route.pending;
      // Streaming callers treat rpc.response as a terminal (non-streaming
      // agent answering a streaming request). Mark before enqueue so a
      // previously queued initial pull cannot emit after this frame.
      if (markStreamTerminal && pending is _PendingStream) {
        pending.streamTerminalSeen = true;
      }
      _enqueueRelayFrameWork(
        pending,
        () => _routeFrameAsyncForPending(
          pending,
          parseResult: route.parseResult,
          headers: route.headers,
          eventName: eventName,
          preDecodedBody: route.preDecodedBody,
        ),
      );
      return;
    }
    _enqueueUnresolvedRelayFrameWork(
      () => _routeUnresolvedFrameFromBodyAsync(
        raw,
        eventName: eventName,
        markStreamTerminal: markStreamTerminal,
      ),
    );
  }

  void _enqueueUnresolvedRelayFrameWork(Future<void> Function() work) {
    _unresolvedFrameChain = _unresolvedFrameChain.then<void>((_) async {
      if (_isDisposed) {
        return;
      }
      try {
        await work();
      } on Object catch (e, s) {
        AppLogger.warning(
          'relay unresolved frame async work failed',
          context: <String, Object?>{
            'component': 'RelayCommandDispatcherImpl',
            'error': e.toString(),
          },
          error: e,
          stackTrace: s,
        );
      }
    });
  }

  Future<void> _routeUnresolvedFrameFromBodyAsync(
    Object? raw, {
    required String eventName,
    required bool markStreamTerminal,
  }) async {
    final headersResult = PayloadFrame.parseHeaders(raw);
    final PayloadFrameHeaders headers;
    switch (headersResult) {
      case PayloadFrameHeadersParseSuccess(headers: final parsedHeaders):
        headers = parsedHeaders;
      case PayloadFrameParseFailure():
        return;
    }
    if (_canSyncDecodeBodyForRoutingHeaders(headers)) {
      return;
    }
    final materialized = PayloadFrame.materialize(headers);
    final PayloadFrame frame;
    switch (materialized) {
      case PayloadFrameParseSuccess(frame: final parsedFrame):
        frame = parsedFrame;
      case final PayloadFrameParseFailure failure:
        _channelMetrics?.recordRelayDecodeFailure(code: failure.code);
        return;
    }
    final decodeSw = Stopwatch()..start();
    Object? decoded;
    try {
      decoded = await _codec.decodeJsonAsync(frame);
    } on PayloadFrameDecodeException catch (e) {
      decodeSw.stop();
      _channelMetrics?.recordRelayPayloadDecodeWallClock(
        elapsed: decodeSw.elapsed,
      );
      _channelMetrics?.recordRelayDecodeFailure(code: e.code);
      return;
    }
    decodeSw.stop();
    _recordRelayDecodeMetrics(decodeSw, frame);
    final pending = _pendingFromDecodedBodyValue(decoded);
    if (pending == null) {
      return;
    }
    _rememberRequestIdMapping(headers.requestId, pending.clientRequestId);
    if (markStreamTerminal && pending is _PendingStream) {
      pending.streamTerminalSeen = true;
    }
    _enqueueRelayFrameWork(
      pending,
      () => _routeFrameAsyncForPending(
        pending,
        parseResult: PayloadFrameParseSuccess(frame),
        eventName: eventName,
        preDecodedBody: decoded,
      ),
    );
  }

  Future<void> _routeFrameAsyncForPending(
    _PendingRelay pending, {
    required String eventName,
    PayloadFrameParseResult? parseResult,
    PayloadFrameHeaders? headers,
    Object? preDecodedBody,
  }) async {
    if (_isDisposed) {
      return;
    }
    if (!_pendingByClientId.containsKey(pending.clientRequestId)) {
      return;
    }
    if (parseResult is PayloadFrameParseFailure) {
      _channelMetrics?.recordRelayDecodeFailure(code: parseResult.code);
      _failPending(
        pending.clientRequestId,
        RelayDecodeFailure(
          message:
              'received $eventName without a valid PayloadFrame envelope: '
              '${parseResult.message}',
          code: parseResult.code,
          conversationId: pending.conversationId,
          clientRequestId: pending.clientRequestId,
        ),
      );
      return;
    }
    final PayloadFrame frame;
    switch (parseResult) {
      case PayloadFrameParseSuccess(frame: final parsedFrame):
        frame = parsedFrame;
      case PayloadFrameParseFailure():
        return;
      case null:
        final resolvedHeaders = headers;
        if (resolvedHeaders == null) {
          return;
        }
        switch (PayloadFrame.materialize(resolvedHeaders)) {
          case PayloadFrameParseSuccess(frame: final parsedFrame):
            frame = parsedFrame;
          case final PayloadFrameParseFailure failure:
            _channelMetrics?.recordRelayDecodeFailure(code: failure.code);
            _failPending(
              pending.clientRequestId,
              RelayDecodeFailure(
                message:
                    'received $eventName without a valid PayloadFrame envelope: '
                    '${failure.message}',
                code: failure.code,
                conversationId: pending.conversationId,
                clientRequestId: pending.clientRequestId,
              ),
            );
            return;
        }
    }

    var decoded = preDecodedBody;
    if (decoded == null) {
      final decodeSw = Stopwatch()..start();
      try {
        decoded = await _codec.decodeJsonAsync(frame);
      } on PayloadFrameDecodeException catch (e, s) {
        decodeSw.stop();
        _channelMetrics?.recordRelayPayloadDecodeWallClock(
          elapsed: decodeSw.elapsed,
        );
        _channelMetrics?.recordRelayDecodeFailure(code: e.code);
        _failPending(
          pending.clientRequestId,
          RelayDecodeFailure(
            message: 'failed to decode $eventName: ${e.message}',
            code: e.code,
            conversationId: pending.conversationId,
            clientRequestId: pending.clientRequestId,
            cause: e,
            stackTrace: s,
          ),
        );
        return;
      }
      decodeSw.stop();
      _recordRelayDecodeMetrics(decodeSw, frame);
    }

    if (decoded is! Map) {
      _channelMetrics?.recordRelayDecodeFailure(code: 'malformed_payload');
      _failPending(
        pending.clientRequestId,
        RelayDecodeFailure(
          message: '$eventName payload is not a JSON object',
          code: 'malformed_payload',
          conversationId: pending.conversationId,
          clientRequestId: pending.clientRequestId,
        ),
      );
      return;
    }
    final logical = decoded.map(
      (key, value) => MapEntry<String, dynamic>(key.toString(), value),
    );

    switch (pending) {
      case final _PendingUnary unary:
        _routeUnary(unary, eventName, logical);
      case final _PendingStream stream:
        await _routeStreamAsync(stream, eventName, logical);
    }
  }

  void _routeUnary(
    _PendingUnary pending,
    String eventName,
    Map<String, dynamic> logical,
  ) {
    if (eventName == 'rpc.complete') {
      final terminalStatus = _terminalStatusOf(logical);
      if (terminalStatus != null && !_isHealthyTerminal(terminalStatus)) {
        final errorCode = _streamErrorCodeOf(logical);
        _failPending(
          pending.clientRequestId,
          RelayStreamTerminated(
            message: errorCode == null
                ? 'relay:rpc.complete terminal_status=$terminalStatus'
                : 'relay:rpc.complete terminal_status=$terminalStatus '
                      'error_code=$errorCode',
            terminalStatus: terminalStatus,
            errorCode: errorCode,
            conversationId: pending.conversationId,
            clientRequestId: pending.clientRequestId,
          ),
        );
        return;
      }
    } else if (eventName == 'rpc.chunk') {
      // PR-L+ part 2 keeps unitary requests chunk-tolerant: we record that
      // chunks were observed (useful for diagnostics) but never forward
      // them to the unitary completer. The hub still terminates with
      // `rpc.complete` which is what completes the future.
      pending.receivedChunkCount += 1;
      AppLogger.debug(
        'Discarding relay:rpc.chunk on unary request',
        context: <String, Object?>{
          'component': 'RelayCommandDispatcherImpl',
          'clientRequestId': pending.clientRequestId,
        },
      );
      return;
    }
    _completePending(pending.clientRequestId, logical);
  }

  Future<void> _routeStreamAsync(
    _PendingStream pending,
    String eventName,
    Map<String, dynamic> logical,
  ) async {
    if (pending.controller.isClosed) {
      return;
    }
    if (eventName == 'rpc.complete') {
      final terminalStatus = _terminalStatusOf(logical);
      if (terminalStatus != null && !_isHealthyTerminal(terminalStatus)) {
        final errorCode = _streamErrorCodeOf(logical);
        _failPending(
          pending.clientRequestId,
          RelayStreamTerminated(
            message: errorCode == null
                ? 'relay:rpc.complete terminal_status=$terminalStatus'
                : 'relay:rpc.complete terminal_status=$terminalStatus '
                      'error_code=$errorCode',
            terminalStatus: terminalStatus,
            errorCode: errorCode,
            conversationId: pending.conversationId,
            clientRequestId: pending.clientRequestId,
          ),
        );
        return;
      }
      // Forward the complete payload as the final stream item so
      // downstream collectors (PR-L+ p3.5) can grab `total_rows`,
      // `execution_id`, `started_at`, `finished_at` — the chunks
      // themselves carry only `rows`. Subscribers that consume only
      // chunks tolerate this extra map (it has no `rows` key, so a
      // typical row-merging collector simply skips appending).
      pending.controller.add(logical);
      _completeStreamPending(pending);
      return;
    }
    if (eventName == 'rpc.response') {
      // Non-streaming agent on a streaming caller: forward as a single
      // chunk + close. The server's behavior is legal under the protocol
      // (relay does not negotiate streaming up front).
      pending.controller.add(logical);
      _completeStreamPending(pending);
      return;
    }
    // rpc.chunk
    if (!pending.streamFirstChunkMetricRecorded) {
      pending.streamFirstChunkMetricRecorded = true;
      final acceptedAt = pending.streamAcceptedAtElapsed;
      final metrics = _channelMetrics;
      if (acceptedAt != null && metrics != null) {
        metrics.recordRelayAcceptToFirstChunkWallClock(
          elapsed: pending.stopwatch.elapsed - acceptedAt,
        );
      }
    }
    _captureStreamId(pending, logical);
    pending.controller.add(logical);
    pending.outstandingCredits = (pending.outstandingCredits - 1).clamp(
      0,
      pending.initialWindow,
    );
    if (pending.outstandingCredits <= pending.refillThreshold) {
      final delta = pending.initialWindow - pending.outstandingCredits;
      if (delta > 0) {
        await _grantPullAsync(pending, delta);
      }
    }
  }

  /// Emits `relay:rpc.stream.pull` to grant [credits] more chunk credits.
  /// Updates the local outstanding-credit counter so the next refill
  /// computation is consistent.
  Future<void> _grantPullAsync(_PendingStream pending, int credits) async {
    if (credits <= 0) {
      return;
    }
    // Terminal already observed (or pending torn down): never pull after
    // the agent finished — see [_PendingStream.streamTerminalSeen].
    if (pending.streamTerminalSeen ||
        pending.controller.isClosed ||
        !_pendingByClientId.containsKey(pending.clientRequestId)) {
      return;
    }
    final requestId = pending.requestId;
    try {
      final encoded = await _codec.encodeJsonAsync(
        <String, Object?>{
          'request_id': requestId ?? pending.clientRequestId,
          if (pending.streamId != null) 'stream_id': pending.streamId,
          'window_size': credits,
        },
        requestId: requestId ?? pending.clientRequestId,
      );
      // Re-check after the async encode: a terminal frame may have arrived
      // while we were framing the pull.
      if (pending.streamTerminalSeen ||
          pending.controller.isClosed ||
          !_pendingByClientId.containsKey(pending.clientRequestId)) {
        return;
      }
      final envelope = <String, Object?>{
        'conversationId': pending.conversationId,
        'frame': encoded.frame.toMap(),
      };
      _connection.raw.emit(RelayEventNames.rpcStreamPull, envelope);
      pending.outstandingCredits += credits;
    } on Object catch (e, s) {
      AppLogger.warning(
        'failed to emit relay:rpc.stream.pull',
        context: <String, Object?>{
          'component': 'RelayCommandDispatcherImpl',
          'clientRequestId': pending.clientRequestId,
          'error': e.toString(),
        },
        error: e,
        stackTrace: s,
      );
      _failPending(
        pending.clientRequestId,
        RelayConversationLost(
          message: 'failed to emit relay:rpc.stream.pull: $e',
          conversationId: pending.conversationId,
          clientRequestId: pending.clientRequestId,
          cause: e,
          stackTrace: s,
        ),
      );
    }
  }

  String? _terminalStatusOf(Map<String, dynamic> logical) =>
      logical['terminal_status']?.toString() ??
      logical['terminalStatus']?.toString();

  bool _isHealthyTerminal(String status) =>
      status == 'completed' || status == 'success';

  String? _streamErrorCodeOf(Map<String, dynamic> logical) {
    final code =
        logical['error_code']?.toString() ?? logical['errorCode']?.toString();
    if (code == null || code.isEmpty) {
      return null;
    }
    return code;
  }

  void _captureStreamId(
    _PendingStream pending,
    Map<String, dynamic> logical,
  ) {
    final streamId = _extractStreamId(logical);
    if (streamId != null) {
      pending.streamId = streamId;
    }
  }

  String? _extractStreamId(Map<String, Object?> map) {
    final value = map['stream_id'] ?? map['streamId'];
    if (value == null) {
      return null;
    }
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  _PendingRelayFrameRoute? _pendingRouteFromFrame(Object? raw) {
    final headersResult = PayloadFrame.parseHeaders(raw);
    final PayloadFrameHeaders headers;
    switch (headersResult) {
      case PayloadFrameHeadersParseSuccess(headers: final parsedHeaders):
        headers = parsedHeaders;
      case final PayloadFrameParseFailure failure:
        AppLogger.warning(
          'relay frame parse failed before routing',
          context: <String, Object?>{
            'component': 'RelayCommandDispatcherImpl',
            'operation': 'pending_from_frame',
            'code': failure.code,
            'message': failure.message,
          },
        );
        final pending = _pendingFromRawCorrelation(raw);
        return pending == null
            ? null
            : _PendingRelayFrameRoute(
                pending: pending,
                parseResult: failure,
              );
    }
    String? clientRequestId;
    final requestId = headers.requestId;
    if (requestId != null && requestId.isNotEmpty) {
      clientRequestId = _clientIdByRequestId[requestId];
    }
    if (clientRequestId != null) {
      final pending = _pendingByClientId[clientRequestId];
      return pending == null
          ? null
          : _PendingRelayFrameRoute(
              pending: pending,
              headers: headers,
            );
    }
    final pendingFromRaw = _pendingFromRawCorrelation(raw);
    if (pendingFromRaw != null) {
      return _PendingRelayFrameRoute(
        pending: pendingFromRaw,
        headers: headers,
      );
    }
    if (!_canSyncDecodeBodyForRoutingHeaders(headers)) {
      return null;
    }
    final materialized = PayloadFrame.materialize(headers);
    final PayloadFrame frame;
    switch (materialized) {
      case PayloadFrameParseSuccess(frame: final parsedFrame):
        frame = parsedFrame;
      case PayloadFrameParseFailure():
        return null;
    }
    final pendingFromBody = _pendingFromSyncDecodedBody(frame);
    if (pendingFromBody != null) {
      _rememberRequestIdMapping(
        requestId,
        pendingFromBody.pending.clientRequestId,
      );
      return _PendingRelayFrameRoute(
        pending: pendingFromBody.pending,
        parseResult: PayloadFrameParseSuccess(frame),
        preDecodedBody: pendingFromBody.decoded,
      );
    }
    return null;
  }

  bool _canSyncDecodeBodyForRouting(PayloadFrame frame) {
    return frame.cmp == PayloadFrame.compressionNone;
  }

  bool _canSyncDecodeBodyForRoutingHeaders(PayloadFrameHeaders headers) {
    return headers.cmp == PayloadFrame.compressionNone;
  }

  void _recordRelayDecodeMetrics(Stopwatch decodeSw, PayloadFrame frame) {
    _channelMetrics?.recordRelayPayloadDecodeWallClock(
      elapsed: decodeSw.elapsed,
    );
    if (_codec.usesWorkerIsolateForGzipDecode(frame)) {
      _channelMetrics?.recordRelayPayloadGzipDecodeIsolate();
    }
    if (_codec.usesWorkerIsolateForJsonDecode(frame)) {
      _channelMetrics?.recordRelayPayloadJsonDecodeIsolate();
    }
  }

  void _rememberRequestIdMapping(String? requestId, String clientRequestId) {
    if (requestId == null || requestId.isEmpty) {
      return;
    }
    _clientIdByRequestId.putIfAbsent(requestId, () => clientRequestId);
  }

  _PendingRelay? _pendingFromDecodedBodyValue(Object? decoded) {
    if (decoded is! Map) {
      return null;
    }
    // Decoded JSON-RPC body: { jsonrpc, id, result|error, meta? }.
    // Hub unary fast-path (ADR 0009): when the hub honours
    // `fastPath: true` it skips `relay:rpc.accepted` but echoes the
    // client JSON-RPC `id` in the response body.
    final id = decoded['id']?.toString();
    if (id == null || id.isEmpty) {
      return null;
    }
    return _pendingByClientId[id];
  }

  /// Last-resort routing path: decode the PayloadFrame body **sync** and
  /// look up the JSON-RPC `id` in [_pendingByClientId]. Used only when
  /// every earlier lookup missed and the frame is uncompressed, so the
  /// cost is bounded to small unary fast-path responses. Errors and
  /// unrecognised shapes return `null` quietly — the upper layer will
  /// discard the frame.
  ({_PendingRelay pending, Object? decoded})? _pendingFromSyncDecodedBody(
    PayloadFrame frame,
  ) {
    if (!_canSyncDecodeBodyForRouting(frame)) {
      return null;
    }
    final decodeSw = Stopwatch()..start();
    try {
      final decoded = _codec.decodeJson(frame);
      decodeSw.stop();
      _recordRelayDecodeMetrics(decodeSw, frame);
      final pending = _pendingFromDecodedBodyValue(decoded);
      if (pending == null) {
        return null;
      }
      return (pending: pending, decoded: decoded);
    } on Object {
      decodeSw.stop();
      _channelMetrics?.recordRelayPayloadDecodeWallClock(
        elapsed: decodeSw.elapsed,
      );
      return null;
    }
  }

  _PendingRelay? _pendingFromRawCorrelation(Object? raw) {
    final map = _toMap(raw);
    final requestId = map?['requestId']?.toString();
    if (requestId != null && requestId.isNotEmpty) {
      final clientRequestId = _clientIdByRequestId[requestId];
      if (clientRequestId != null) {
        return _pendingByClientId[clientRequestId];
      }
    }
    // Fall back to a one-pending-conversation match: when the wire requestId
    // is missing (some events drop it for high-throughput streams), and only
    // a single pending request exists on the conversation, route to it.
    final conversationId = map?['conversationId']?.toString();
    if (conversationId == null) {
      return null;
    }
    final solo = _pendingClientIdsByConversationId[conversationId];
    if (solo == null || solo.length != 1) {
      return null;
    }
    return _pendingByClientId[solo.single];
  }

  void _safeAddRelayOutcome(RelayRpcOutcome outcome) {
    if (_outcomes.isClosed) {
      return;
    }
    _outcomes.add(outcome);
  }

  void _completePending(String clientRequestId, Map<String, dynamic> response) {
    final entry = _pendingByClientId.remove(clientRequestId);
    if (entry != null) {
      _unregisterPendingConversation(entry.conversationId, clientRequestId);
      _clearActiveBatchMembership(entry.conversationId, clientRequestId);
    }
    if (entry is! _PendingUnary) {
      return;
    }
    final requestId = entry.requestId;
    if (requestId != null) {
      _clientIdByRequestId.remove(requestId);
    }
    entry.timeoutTimer?.cancel();
    final acceptedAt = entry.unaryAcceptedAtElapsed;
    final respondedAt = entry.stopwatch.elapsed;
    entry.stopwatch.stop();
    if (acceptedAt != null && respondedAt >= acceptedAt) {
      _channelMetrics?.recordRelayAcceptedToResponse(
        elapsed: respondedAt - acceptedAt,
      );
    }
    // Hub item 4 (`requestServerTimings`): when the consumer opted in,
    // the relay response carries a per-phase snapshot under
    // `meta.serverTimings`. We fold it into the metrics service without
    // touching the JSON-RPC body the caller sees.
    final serverTimings = ServerTimings.tryParseFromRelayBody(response);
    if (serverTimings != null) {
      _channelMetrics?.recordServerTimings(serverTimings);
    }
    if (!entry.completer.isCompleted) {
      entry.completer.complete(response);
      _safeAddRelayOutcome(_buildSuccessOutcome(entry));
    }
    _releaseRelayGateSlot(entry);
  }

  void _completeStreamPending(_PendingStream entry) {
    final removed = _pendingByClientId.remove(entry.clientRequestId);
    if (removed == null) {
      return;
    }
    _unregisterPendingConversation(
      removed.conversationId,
      entry.clientRequestId,
    );
    final requestId = entry.requestId;
    if (requestId != null) {
      _clientIdByRequestId.remove(requestId);
    }
    entry.timeoutTimer?.cancel();
    entry.stopwatch.stop();
    if (!entry.controller.isClosed) {
      // close() returns a Future that completes when listeners drained
      // the buffered events. The dispatcher does not need to wait — the
      // success outcome below is the public signal callers act on.
      unawaited(entry.controller.close());
      _safeAddRelayOutcome(_buildSuccessOutcome(entry));
    }
    _releaseRelayGateSlot(entry);
  }

  RelayRpcSuccess _buildSuccessOutcome(_PendingRelay entry) {
    return RelayRpcSuccess(
      agentId: entry.agentId,
      conversationId: entry.conversationId,
      clientRequestId: entry.clientRequestId,
      requestId: entry.requestId,
      observedAt: DateTime.now().toUtc(),
      elapsed: entry.stopwatch.elapsed,
      method: entry.method,
      deduplicated: entry.deduplicated,
      replayed: entry.replayed,
      inFlight: entry.inFlight,
    );
  }

  void _releaseRelayGateSlot(_PendingRelay entry) {
    final release = entry.relayPerAgentSlotRelease;
    if (release != null) {
      entry.relayPerAgentSlotRelease = null;
      release();
    }
  }

  void _clearActiveBatchMembership(
    String conversationId,
    String clientRequestId,
  ) {
    final batchIds = _activeBatchClientIdsByConversationId[conversationId];
    if (batchIds == null) {
      return;
    }
    batchIds.remove(clientRequestId);
    if (batchIds.isEmpty) {
      _activeBatchClientIdsByConversationId.remove(conversationId);
    }
  }

  void _failPending(
    String clientRequestId,
    RelayDispatchException exception,
  ) {
    final entry = _pendingByClientId.remove(clientRequestId);
    if (entry == null) {
      return;
    }
    _clearActiveBatchMembership(entry.conversationId, clientRequestId);
    final gate = _concurrencyGate;
    final qw = entry.gateQueueWaitCompleter;
    if (gate != null && qw != null) {
      gate.cancelQueuedWaiter(entry.agentId, qw);
      entry.gateQueueWaitCompleter = null;
    }
    _unregisterPendingConversation(entry.conversationId, clientRequestId);
    _releaseRelayGateSlot(entry);
    final requestId = entry.requestId;
    if (requestId != null) {
      _clientIdByRequestId.remove(requestId);
    }
    entry.timeoutTimer?.cancel();
    entry.stopwatch.stop();
    final emitted = entry.failExternally(exception);
    if (emitted) {
      _safeAddRelayOutcome(
        RelayRpcFailure(
          agentId: entry.agentId,
          conversationId: entry.conversationId,
          clientRequestId: clientRequestId,
          requestId: requestId,
          observedAt: DateTime.now().toUtc(),
          elapsed: entry.stopwatch.elapsed,
          method: entry.method,
          exception: exception,
        ),
      );
    }
  }

  void _failAllPending(
    RelayDispatchException Function(_PendingRelay entry) buildException,
  ) {
    final pending = _pendingByClientId.values.toList(growable: false);
    for (final entry in pending) {
      _failPending(entry.clientRequestId, buildException(entry));
    }
  }

  /// Fails every pending request on [conversationId] with [RelayConversationLost].
  /// Idempotent — no-op when no pendings exist for the conversation.
  void failPendingsForConversation(
    String conversationId, {
    required String reason,
  }) {
    if (_isDisposed) {
      return;
    }
    final clientIds = _pendingClientIdsByConversationId[conversationId];
    if (clientIds == null || clientIds.isEmpty) {
      return;
    }
    for (final clientRequestId in List<String>.of(clientIds)) {
      _failPending(
        clientRequestId,
        RelayConversationLost(
          message: 'Hub terminated relay conversation (reason=$reason)',
          conversationId: conversationId,
          clientRequestId: clientRequestId,
        ),
      );
    }
  }

  void _onHubConversationEnded({
    required String conversationId,
    String? reason,
  }) {
    failPendingsForConversation(
      conversationId,
      reason: reason ?? 'hub_ended',
    );
  }

  String? _extractMethod(Map<String, Object?> body) {
    final directMethod = body['method'];
    if (directMethod is String && directMethod.isNotEmpty) {
      return directMethod;
    }
    final command = body['command'];
    if (command is Map) {
      final method = command['method'];
      if (method is String && method.isNotEmpty) {
        return method;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _toMap(Object? raw) =>
      socketToStringKeyedMap(raw);
}
