import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/observability/socket/socket_channel_metrics.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:colmeia/core/socket/payload_frame_codec.dart';
import 'package:colmeia/core/socket/per_agent_concurrency_gate.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/core/socket/relay/relay_conversation.dart';
import 'package:colmeia/core/socket/relay/relay_conversation_manager.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:colmeia/core/socket/relay/relay_rpc_outcome.dart';
import 'package:colmeia/core/socket/socket_app_error_retry_after.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

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
    Duration defaultTimeout = const Duration(seconds: 30),
    RelayPayloadFrameCompression defaultCompression =
        RelayPayloadFrameCompression.auto,
    int defaultStreamInitialWindow = 32,
    int defaultStreamRefillThreshold = 16,
  }) : _connection = connection,
       _conversationManager = conversationManager,
       _codec = codec ?? const PayloadFrameCodec(),
       _concurrencyGate = concurrencyGate,
       _channelMetrics = channelMetrics,
       _defaultTimeout = defaultTimeout,
       _defaultCompression = defaultCompression,
       _defaultStreamInitialWindow = defaultStreamInitialWindow,
       _defaultStreamRefillThreshold = defaultStreamRefillThreshold,
       _outcomes = StreamController<RelayRpcOutcome>.broadcast() {
    _stateSub = _connection.states().listen(_onConnectionState);
  }

  final ConsumerSocketConnection _connection;
  final RelayConversationManager _conversationManager;
  final PayloadFrameCodec _codec;
  final PerAgentConcurrencyGate? _concurrencyGate;
  final SocketChannelMetrics? _channelMetrics;
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

  /// Client request ids currently pending per `conversationId`. Used for
  /// O(1) routing in [_pendingFromFrame] when the hub omits `requestId` on
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

  StreamSubscription<ConsumerSocketConnectionState>? _stateSub;
  io.Socket? _attachedSocket;
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
    final gate = _concurrencyGate;
    if (gate != null) {
      try {
        await gate.acquire(pending.agentId);
      } on Object catch (e, s) {
        _failPending(
          clientRequestId,
          RelayConversationStartFailure(
            message: 'relay concurrency gate acquire failed: $e',
            cause: e,
            stackTrace: s,
          ),
        );
        return pending.completer.future;
      }
      pending.relayPerAgentSlotRelease = () => gate.release(pending.agentId);
    }
    await _emitRpcRequestAsync(
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
            await gate.acquire(pending.agentId);
          } on Object catch (e, s) {
            _failPending(
              clientRequestId,
              RelayConversationStartFailure(
                message: 'relay concurrency gate acquire failed: $e',
                cause: e,
                stackTrace: s,
              ),
            );
            return;
          }
          pending.relayPerAgentSlotRelease = () =>
              gate.release(pending.agentId);
        }
        await _emitRpcRequestAsync(
          conversationId: pending.conversationId,
          clientRequestId: clientRequestId,
          body: body,
          compression: compression,
          pending: pending,
        );
      })().catchError((Object error, StackTrace stack) async {
        reportUnhandledStreamError(error, stack);
      }),
    );

    return controller.stream;
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
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
    }
    // `_conversationManager.obtain` calls `_connection.connect()` which
    // surfaces the two terminal handshake failures as `StateError`
    // (same shape as `SocketCommandDispatcherImpl`). We MUST translate
    // them to the shared `SocketDispatch*` exceptions BEFORE the
    // generic Object catch below — otherwise the
    // `SocketWithRestFallbackAgentQueriesRemoteDataSource` cannot
    // distinguish "hub forbidden / auth dead" (latch + REST) from a
    // transient relay start failure (no fallback, surface as-is).
    // ignore: avoid_catching_errors
    on StateError catch (e) {
      final message = e.message;
      if (message.startsWith('Consumer socket namespace forbidden:')) {
        throw SocketDispatchNamespaceForbidden(
          message: message,
          role: _extractMarker(message, 'role='),
          namespace: _extractMarker(message, 'namespace='),
          cause: e,
        );
      }
      if (message.startsWith('Consumer socket reconnect exhausted:')) {
        throw SocketDispatchDisconnected(
          message: 'Cannot start relay conversation: $e',
          cause: e,
        );
      }
      if (message.startsWith('Consumer socket unauthorized:')) {
        throw SocketDispatchUnauthorized(
          message: 'Cannot start relay conversation: $e',
          cause: e,
        );
      }
      // Other StateErrors (used-after-dispose, etc.) surface as
      // start failures because they are not a hub-policy issue.
      throw RelayConversationStartFailure(
        message: 'failed to obtain relay conversation: $e',
        cause: e,
      );
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
  Future<void> _emitRpcRequestAsync({
    required String conversationId,
    required String clientRequestId,
    required Map<String, Object?> body,
    required RelayPayloadFrameCompression compression,
    required _PendingRelay pending,
  }) async {
    pending.method ??= _extractMethod(body);
    PayloadFrameEncodeResult encoded;
    try {
      // The client_request_id in the JSON-RPC `id` field is what makes the
      // hub idempotent, so we mirror it on the envelope `requestId` for
      // observability — the hub ignores envelope.requestId on inbound.
      encoded = await _codec.encodeJsonAsync(
        body,
        requestId: clientRequestId,
      );
    } on PayloadFrameDecodeException catch (e, s) {
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
    final socket = _connection.raw;
    if (identical(_attachedSocket, socket)) {
      return;
    }
    _detachListeners();
    socket
      ..on(RelayEventNames.rpcAccepted, _onAccepted)
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
        ..off(RelayEventNames.rpcAccepted)
        ..off(RelayEventNames.rpcResponse)
        ..off(RelayEventNames.rpcChunk)
        ..off(RelayEventNames.rpcComplete)
        ..off(RelayEventNames.rpcStreamPullResponse)
        ..off(RelayEventNames.appError);
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
        final clientRequestId = _clientIdByRequestId[value];
        if (clientRequestId != null) {
          return clientRequestId;
        }
      }
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
          retryAfter: extractRetryAfterFromAppError(map),
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
      pending.streamAcceptedAtElapsed = pending.stopwatch.elapsed;
      _enqueueRelayFrameWork(
        pending,
        () => _grantPullAsync(pending, pending.initialWindow),
      );
    }
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
    final pending = _pendingFromFrame(raw);
    if (pending == null) {
      return;
    }
    _enqueueRelayFrameWork(
      pending,
      () => _routeFrameAsyncForPending(
        pending,
        raw,
        eventName: 'rpc.response',
      ),
    );
  }

  void _onChunkFrame(Object? raw) {
    final pending = _pendingFromFrame(raw);
    if (pending == null) {
      return;
    }
    _enqueueRelayFrameWork(
      pending,
      () => _routeFrameAsyncForPending(
        pending,
        raw,
        eventName: 'rpc.chunk',
      ),
    );
  }

  void _onCompleteFrame(Object? raw) {
    final pending = _pendingFromFrame(raw);
    if (pending == null) {
      return;
    }
    _enqueueRelayFrameWork(
      pending,
      () => _routeFrameAsyncForPending(
        pending,
        raw,
        eventName: 'rpc.complete',
      ),
    );
  }

  Future<void> _routeFrameAsyncForPending(
    _PendingRelay pending,
    Object? raw, {
    required String eventName,
  }) async {
    if (_isDisposed) {
      return;
    }
    if (!_pendingByClientId.containsKey(pending.clientRequestId)) {
      return;
    }
    final frame = PayloadFrame.tryParse(raw);
    if (frame == null) {
      _channelMetrics?.recordRelayDecodeFailure(code: 'malformed_frame');
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

    final decodeSw = Stopwatch()..start();
    Object? decoded;
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
    _channelMetrics?.recordRelayPayloadDecodeWallClock(
      elapsed: decodeSw.elapsed,
    );
    if (_codec.usesWorkerIsolateForGzipDecode(frame)) {
      _channelMetrics?.recordRelayPayloadGzipDecodeIsolate();
    }
    if (_codec.usesWorkerIsolateForJsonDecode(frame)) {
      _channelMetrics?.recordRelayPayloadJsonDecodeIsolate();
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
    }
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
    );
  }

  void _releaseRelayGateSlot(_PendingRelay entry) {
    final release = entry.relayPerAgentSlotRelease;
    if (release != null) {
      entry.relayPerAgentSlotRelease = null;
      release();
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

  /// Same parser as the legacy `SocketCommandDispatcherImpl` —
  /// pulls a `key=value` token out of the `StateError.message` the
  /// connection layer emits for namespace rejection. Kept private
  /// (duplicated) instead of moved to a shared helper because the
  /// two dispatchers will diverge over time on which markers they
  /// care about, and the cost is one method.
  String? _extractMarker(String source, String key) {
    final start = source.indexOf(key);
    if (start < 0) {
      return null;
    }
    final valueStart = start + key.length;
    final remainder = source.substring(valueStart);
    final endIndex = remainder.indexOf(' ');
    final value = endIndex < 0 ? remainder : remainder.substring(0, endIndex);
    return value.isEmpty ? null : value;
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

  /// Serializes async frame handling and initial pull emission per request.
  Future<void> frameRoutingChain = Future<void>.value();

  /// Invoked once when the per-agent relay slot is finished.
  void Function()? relayPerAgentSlotRelease;

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

  /// Server stream identifier returned by pull acks or chunk payloads.
  /// Included on subsequent pull frames when present.
  String? streamId;

  /// [Stopwatch.elapsed] when `relay:rpc.accepted` succeeded (streaming only).
  Duration? streamAcceptedAtElapsed;

  bool streamFirstChunkMetricRecorded = false;

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
