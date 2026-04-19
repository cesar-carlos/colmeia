import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:colmeia/core/socket/payload_frame_codec.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/core/socket/relay/relay_conversation.dart';
import 'package:colmeia/core/socket/relay/relay_conversation_manager.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:colmeia/core/socket/relay/relay_rpc_outcome.dart';

/// Default `RelayCommandDispatcher`. Wraps a `ConsumerSocketConnection`
/// (for `emit`) and a `RelayConversationManager` (for the conversation
/// lifecycle). Listens to the four data events
/// (`accepted` / `response` / `chunk` / `complete`) once per connection and
/// fans them out by `client_request_id` / `requestId`.
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
    Duration defaultTimeout = const Duration(seconds: 30),
    RelayPayloadFrameCompression defaultCompression =
        RelayPayloadFrameCompression.auto,
    int defaultStreamInitialWindow = 32,
    int defaultStreamRefillThreshold = 16,
  }) : _connection = connection,
       _conversationManager = conversationManager,
       _codec = codec ?? const PayloadFrameCodec(),
       _defaultTimeout = defaultTimeout,
       _defaultCompression = defaultCompression,
       _defaultStreamInitialWindow = defaultStreamInitialWindow,
       _defaultStreamRefillThreshold = defaultStreamRefillThreshold,
       _outcomes = StreamController<RelayRpcOutcome>.broadcast();

  final ConsumerSocketConnection _connection;
  final RelayConversationManager _conversationManager;
  final PayloadFrameCodec _codec;
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
  /// Populated only after `relay:rpc.accepted`.
  final Map<String, String> _clientIdByRequestId = <String, String>{};

  bool _listenersAttached = false;
  bool _isDisposed = false;

  @override
  Stream<RelayRpcOutcome> outcomes() => _outcomes.stream;

  @override
  Future<Map<String, dynamic>> sendUnary({
    required String agentId,
    required Map<String, Object?> body,
    required String clientRequestId,
    Duration? timeout,
    RelayPayloadFrameCompression compression =
        RelayPayloadFrameCompression.auto,
  }) async {
    final pending = await _prepareSend<_PendingUnary>(
      agentId: agentId,
      clientRequestId: clientRequestId,
      timeout: timeout,
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
    _emitRpcRequest(
      conversationId: pending.conversationId,
      clientRequestId: clientRequestId,
      body: body,
      compression: compression,
      pending: pending,
    );
    return pending.completer.future;
  }

  @override
  Stream<Map<String, dynamic>> sendStreaming({
    required String agentId,
    required Map<String, Object?> body,
    required String clientRequestId,
    Duration? timeout,
    int? initialWindowSize,
    int? refillThreshold,
    RelayPayloadFrameCompression compression =
        RelayPayloadFrameCompression.auto,
  }) {
    final controller = StreamController<Map<String, dynamic>>.broadcast();

    // Run the async preparation in the background and forward errors to
    // the controller so the caller observes everything via the stream.
    // The Future is intentionally fire-and-forget — observers consume the
    // stream, not this future.
    // ignore: discarded_futures
    Future<void>(() async {
      final window = initialWindowSize ?? _defaultStreamInitialWindow;
      final threshold = refillThreshold ?? _defaultStreamRefillThreshold;
      final _PendingStream pending;
      try {
        pending = await _prepareSend<_PendingStream>(
          agentId: agentId,
          clientRequestId: clientRequestId,
          timeout: timeout,
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
      }
      _emitRpcRequest(
        conversationId: pending.conversationId,
        clientRequestId: clientRequestId,
        body: body,
        compression: compression,
        pending: pending,
      );
    });

    return controller.stream;
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    if (_listenersAttached) {
      try {
        _connection.raw
          ..off(RelayEventNames.rpcAccepted)
          ..off(RelayEventNames.rpcResponse)
          ..off(RelayEventNames.rpcChunk)
          ..off(RelayEventNames.rpcComplete)
          ..off(RelayEventNames.rpcStreamPullResponse);
      }
      // ConsumerSocketConnection.raw throws StateError when already torn
      // down; that's expected during dispose.
      // ignore: avoid_catching_errors
      on StateError catch (_) {
        // Connection may already be torn down.
      }
      _listenersAttached = false;
    }
    final pending = _pendingByClientId.values.toList(growable: false);
    _pendingByClientId.clear();
    _clientIdByRequestId.clear();
    for (final entry in pending) {
      entry.timeoutTimer?.cancel();
      entry.failExternally(
        RelayDispatcherDisposed(
          message: 'Relay dispatcher disposed mid-flight',
          conversationId: entry.conversationId,
          clientRequestId: entry.clientRequestId,
        ),
      );
    }
    if (!_outcomes.isClosed) {
      await _outcomes.close();
    }
  }

  // ----- Internals -----

  /// Shared preparation for both `sendUnary` and `sendStreaming`. Resolves
  /// the conversation, registers the pending entry, arms the timeout, and
  /// hands the typed pending back so callers can either await its
  /// completer or wire its stream controller before emitting on the wire.
  Future<T> _prepareSend<T extends _PendingRelay>({
    required String agentId,
    required String clientRequestId,
    required Duration? timeout,
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

    final effectiveTimeout = timeout ?? _defaultTimeout;
    pending.timeoutTimer = Timer(effectiveTimeout, () {
      _failPending(
        clientRequestId,
        RelayRequestTimeout(
          message:
              'No response for clientRequestId=$clientRequestId after '
              '${effectiveTimeout.inSeconds}s',
          conversationId: conversationId,
          clientRequestId: clientRequestId,
        ),
      );
    });
    return pending;
  }

  /// Encodes [body] as a PayloadFrame and emits `relay:rpc.request`.
  /// Callers stash the typed pending; this method only knows how to
  /// translate a logical body into the wire envelope and surface
  /// transport-level failures back through [_failPending].
  void _emitRpcRequest({
    required String conversationId,
    required String clientRequestId,
    required Map<String, Object?> body,
    required RelayPayloadFrameCompression compression,
    required _PendingRelay pending,
  }) {
    pending.method ??= _extractMethod(body);
    PayloadFrameEncodeResult encoded;
    try {
      // The client_request_id in the JSON-RPC `id` field is what makes the
      // hub idempotent, so we mirror it on the envelope `requestId` for
      // observability — the hub ignores envelope.requestId on inbound.
      encoded = _codec.encodeJson(
        body,
        requestId: clientRequestId,
      );
    } on PayloadFrameDecodeException catch (e, s) {
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
        },
      );
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
    if (_listenersAttached) {
      return;
    }
    _listenersAttached = true;
    _connection.raw
      ..on(RelayEventNames.rpcAccepted, _onAccepted)
      ..on(RelayEventNames.rpcResponse, _onResponseFrame)
      ..on(RelayEventNames.rpcChunk, _onChunkFrame)
      ..on(RelayEventNames.rpcComplete, _onCompleteFrame)
      ..on(RelayEventNames.rpcStreamPullResponse, _onStreamPullResponse);
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
          conversationId: pending.conversationId,
          clientRequestId: clientRequestId,
        ),
      );
      return;
    }
    final granted = _toIntOrNull(map['windowSize']) ??
        _toIntOrNull(map['window_size']);
    if (granted != null && granted >= 0 && granted < pending.outstandingCredits) {
      // Hub clamped the window: align the local counter so the next refill
      // reflects what the server actually authorized.
      pending.outstandingCredits = granted;
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

  void _onAccepted(Object? raw) {
    final map = _toMap(raw);
    if (map == null) {
      return;
    }
    final clientRequestId = map['clientRequestId']?.toString();
    if (clientRequestId == null || clientRequestId.isEmpty) {
      return;
    }
    final pending = _pendingByClientId[clientRequestId];
    if (pending == null) {
      return;
    }
    final success = map['success'];
    if (success is bool && !success) {
      final error = _toMap(map['error']);
      final code = error?['code']?.toString() ?? 'request_rejected';
      final message =
          error?['message']?.toString() ??
          'relay:rpc.accepted reported success=false';
      _failPending(
        clientRequestId,
        RelayRequestRejected(
          message: message,
          serverCode: code,
          conversationId: pending.conversationId,
          clientRequestId: clientRequestId,
        ),
      );
      return;
    }
    final requestId = map['requestId']?.toString();
    if (requestId != null && requestId.isNotEmpty) {
      pending.requestId = requestId;
      _clientIdByRequestId[requestId] = clientRequestId;
    }
    pending
      ..deduplicated = map['deduplicated'] == true
      ..replayed = map['replayed'] == true;

    // Streaming requests grant the initial pull window as soon as the hub
    // has acknowledged the request. Without an explicit budget the hub
    // would buffer chunks server-side and possibly abort the stream when
    // the buffer cap is hit.
    if (pending is _PendingStream) {
      _grantPull(pending, pending.initialWindow);
    }
  }

  void _onResponseFrame(Object? raw) {
    _routeFrame(raw, eventName: 'rpc.response');
  }

  void _onChunkFrame(Object? raw) {
    _routeFrame(raw, eventName: 'rpc.chunk');
  }

  void _onCompleteFrame(Object? raw) {
    _routeFrame(raw, eventName: 'rpc.complete');
  }

  void _routeFrame(Object? raw, {required String eventName}) {
    final pending = _pendingFromFrame(raw);
    if (pending == null) {
      return;
    }
    final frame = PayloadFrame.tryParse(raw);
    if (frame == null) {
      _failPending(
        pending.clientRequestId,
        RelayDecodeFailure(
          message: 'received $eventName without a valid PayloadFrame envelope',
          code: 'malformed_frame',
          conversationId: pending.conversationId,
          clientRequestId: pending.clientRequestId,
        ),
      );
      return;
    }

    Object? decoded;
    try {
      decoded = _codec.decodeJson(frame);
    } on PayloadFrameDecodeException catch (e, s) {
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

    if (decoded is! Map) {
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
      case _PendingUnary():
        _routeUnary(pending, eventName, logical);
      case _PendingStream():
        _routeStream(pending, eventName, logical);
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
        _failPending(
          pending.clientRequestId,
          RelayStreamTerminated(
            message: 'relay:rpc.complete terminal_status=$terminalStatus',
            terminalStatus: terminalStatus,
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

  void _routeStream(
    _PendingStream pending,
    String eventName,
    Map<String, dynamic> logical,
  ) {
    if (pending.controller.isClosed) {
      return;
    }
    if (eventName == 'rpc.complete') {
      final terminalStatus = _terminalStatusOf(logical);
      if (terminalStatus != null && !_isHealthyTerminal(terminalStatus)) {
        _failPending(
          pending.clientRequestId,
          RelayStreamTerminated(
            message: 'relay:rpc.complete terminal_status=$terminalStatus',
            terminalStatus: terminalStatus,
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
    pending.controller.add(logical);
    pending.outstandingCredits =
        (pending.outstandingCredits - 1).clamp(0, pending.initialWindow);
    if (pending.outstandingCredits <= pending.refillThreshold) {
      final delta = pending.initialWindow - pending.outstandingCredits;
      if (delta > 0) {
        _grantPull(pending, delta);
      }
    }
  }

  /// Emits `relay:rpc.stream.pull` to grant [credits] more chunk credits.
  /// Updates the local outstanding-credit counter so the next refill
  /// computation is consistent.
  void _grantPull(_PendingStream pending, int credits) {
    if (credits <= 0) {
      return;
    }
    final requestId = pending.requestId;
    final envelope = <String, Object?>{
      'conversationId': pending.conversationId,
      'requestId': ?requestId,
      'windowSize': credits,
    };
    try {
      _connection.raw.emit(RelayEventNames.rpcStreamPull, envelope);
      pending.outstandingCredits += credits;
    } on Object catch (e) {
      AppLogger.warning(
        'failed to emit relay:rpc.stream.pull',
        context: <String, Object?>{
          'component': 'RelayCommandDispatcherImpl',
          'clientRequestId': pending.clientRequestId,
          'error': e.toString(),
        },
      );
    }
  }

  String? _terminalStatusOf(Map<String, dynamic> logical) =>
      logical['terminal_status']?.toString() ??
      logical['terminalStatus']?.toString();

  bool _isHealthyTerminal(String status) =>
      status == 'completed' || status == 'success';

  _PendingRelay? _pendingFromFrame(Object? raw) {
    final frame = PayloadFrame.tryParse(raw);
    String? clientRequestId;
    final requestId = frame?.requestId;
    if (requestId != null && requestId.isNotEmpty) {
      clientRequestId = _clientIdByRequestId[requestId];
    }
    if (clientRequestId != null) {
      return _pendingByClientId[clientRequestId];
    }
    // Fall back to a one-pending-conversation match: when the wire requestId
    // is missing (some events drop it for high-throughput streams), and only
    // a single pending request exists on the conversation, route to it.
    final map = _toMap(raw);
    final conversationId = map?['conversationId']?.toString();
    if (conversationId == null) {
      return null;
    }
    final candidates = _pendingByClientId.values
        .where((entry) => entry.conversationId == conversationId)
        .toList(growable: false);
    if (candidates.length == 1) {
      return candidates.single;
    }
    return null;
  }

  void _completePending(String clientRequestId, Map<String, dynamic> response) {
    final entry = _pendingByClientId.remove(clientRequestId);
    if (entry is! _PendingUnary) {
      return;
    }
    final requestId = entry.requestId;
    if (requestId != null) {
      _clientIdByRequestId.remove(requestId);
    }
    entry.timeoutTimer?.cancel();
    entry.stopwatch.stop();
    if (!entry.completer.isCompleted) {
      entry.completer.complete(response);
      _outcomes.add(_buildSuccessOutcome(entry));
    }
  }

  void _completeStreamPending(_PendingStream entry) {
    final removed = _pendingByClientId.remove(entry.clientRequestId);
    if (removed == null) {
      return;
    }
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
      _outcomes.add(_buildSuccessOutcome(entry));
    }
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
    );
  }

  void _failPending(
    String clientRequestId,
    RelayDispatchException exception,
  ) {
    final entry = _pendingByClientId.remove(clientRequestId);
    if (entry == null) {
      return;
    }
    final requestId = entry.requestId;
    if (requestId != null) {
      _clientIdByRequestId.remove(requestId);
    }
    entry.timeoutTimer?.cancel();
    entry.stopwatch.stop();
    final emitted = entry.failExternally(exception);
    if (emitted) {
      _outcomes.add(
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

  String? _extractMethod(Map<String, Object?> body) {
    final command = body['command'];
    if (command is Map) {
      final method = command['method'];
      if (method is String && method.isNotEmpty) {
        return method;
      }
    }
    return null;
  }

  static Map<String, Object?>? _toMap(Object? raw) {
    if (raw is Map<String, Object?>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry<String, Object?>(key.toString(), value),
      );
    }
    return null;
  }
}

/// Common state shared by both unitary and streaming pendings.
sealed class _PendingRelay {
  _PendingRelay({
    required this.agentId,
    required this.conversationId,
    required this.clientRequestId,
    required this.method,
    required this.stopwatch,
  });

  final String agentId;
  final String conversationId;
  final String clientRequestId;
  String? method;
  final Stopwatch stopwatch;

  String? requestId;
  bool deduplicated = false;
  bool replayed = false;
  Timer? timeoutTimer;

  /// Reports an external failure to the consumer (Future or Stream).
  /// Returns `true` when the failure was actually delivered (i.e. the
  /// underlying completer/controller was still open). Callers use the
  /// return value to decide whether to emit an outcome event.
  bool failExternally(RelayDispatchException exception);
}

class _PendingUnary extends _PendingRelay {
  _PendingUnary({
    required super.agentId,
    required super.conversationId,
    required super.clientRequestId,
    required super.method,
    required super.stopwatch,
  });

  final Completer<Map<String, dynamic>> completer =
      Completer<Map<String, dynamic>>();

  /// Diagnostic counter for chunks observed on a unary request (the
  /// dispatcher does not forward them, but the count helps spot agents
  /// that ignore the unary contract).
  int receivedChunkCount = 0;

  @override
  bool failExternally(RelayDispatchException exception) {
    if (completer.isCompleted) {
      return false;
    }
    completer.completeError(exception);
    return true;
  }
}

class _PendingStream extends _PendingRelay {
  _PendingStream({
    required super.agentId,
    required super.conversationId,
    required super.clientRequestId,
    required super.method,
    required super.stopwatch,
    required this.controller,
    required this.initialWindow,
    required this.refillThreshold,
  });

  final StreamController<Map<String, dynamic>> controller;

  /// Maximum number of in-flight chunks the dispatcher tolerates. Reset
  /// after every refill emission.
  final int initialWindow;

  /// Granularity for refilling the window: when [outstandingCredits]
  /// drops to or below this value the dispatcher tops the window back to
  /// [initialWindow] with a single `relay:rpc.stream.pull`.
  final int refillThreshold;

  /// Outstanding credits the hub still has authorised to send. Decremented
  /// per chunk received and replenished when `_grantPull` succeeds.
  int outstandingCredits = 0;

  @override
  bool failExternally(RelayDispatchException exception) {
    if (controller.isClosed) {
      return false;
    }
    controller.addError(exception);
    // close() completes once subscribers drained the error; the dispatcher
    // just signals failure here, callers receive it via the stream.
    unawaited(controller.close());
    return true;
  }
}
