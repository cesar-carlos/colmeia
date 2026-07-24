import 'dart:async';

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/observability/socket/server_timings.dart';
import 'package:colmeia/core/socket/agent_command_outcome.dart';
import 'package:colmeia/core/socket/agent_latency_oracle.dart';
import 'package:colmeia/core/socket/agents_wire_payload.dart';
import 'package:colmeia/core/socket/consumer_socket_app_error_codes.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/consumer_socket_terminal_exception.dart';
import 'package:colmeia/core/socket/payload_frame_codec.dart';
import 'package:colmeia/core/socket/per_agent_concurrency_gate.dart';
import 'package:colmeia/core/socket/socket_app_error_retry_after.dart';
import 'package:colmeia/core/socket/socket_coalesce_key.dart';
import 'package:colmeia/core/socket/socket_command_coalescer.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/core/socket/socket_request_correlator.dart';
import 'package:colmeia/core/socket/socket_wire_utils.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Default implementation of [SocketCommandDispatcher].
///
/// Emits `agents:command` and routes `agents:command_response` /
/// `app:error` back to the calling [Future] through
/// [SocketRequestCorrelator]. Generates outcomes for the realtime
/// presence layer and metrics.
///
/// SRP-conscious: this dispatcher knows nothing about
/// `features/agent_queries/*`. It inspects the bridge response structure
/// (`response.item.error`) only enough to classify outcomes; the actual
/// JSON-RPC parsing remains in the repository. Request coalescing lives in
/// [SocketCommandCoalescer].
///
/// See `docs/Features/socket_command_dispatcher_design.md` §5.
class SocketCommandDispatcherImpl implements SocketCommandDispatcher {
  SocketCommandDispatcherImpl({
    required ConsumerSocketConnection connection,
    required SocketRequestCorrelator correlator,
    PerAgentConcurrencyGate? concurrencyGate,
    AgentLatencyOracle? latencyOracle,
    PayloadFrameCodec? payloadFrameCodec,
    Duration defaultTimeout = const Duration(seconds: 20),
    bool coalescingEnabled = true,
    void Function()? onCoalesced,
    void Function(ServerTimings)? onServerTimings,
  }) : _connection = connection,
       _correlator = correlator,
       _concurrencyGate = concurrencyGate,
       _latencyOracle = latencyOracle,
       _payloadFrameCodec = payloadFrameCodec ?? const PayloadFrameCodec(),
       _defaultTimeout = defaultTimeout,
       _coalescingEnabled = coalescingEnabled,
       _coalescer = SocketCommandCoalescer(onCoalesced: onCoalesced),
       _onServerTimings = onServerTimings,
       _outcomes = StreamController<AgentCommandOutcome>.broadcast() {
    _stateSub = _connection.states().listen(_onConnectionState);
  }

  final ConsumerSocketConnection _connection;
  final SocketRequestCorrelator _correlator;
  final PerAgentConcurrencyGate? _concurrencyGate;
  final AgentLatencyOracle? _latencyOracle;
  final PayloadFrameCodec _payloadFrameCodec;
  final Duration _defaultTimeout;
  final bool _coalescingEnabled;
  final SocketCommandCoalescer _coalescer;
  final void Function(ServerTimings)? _onServerTimings;
  final StreamController<AgentCommandOutcome> _outcomes;

  StreamSubscription<ConsumerSocketConnectionState>? _stateSub;
  io.Socket? _attachedSocket;
  bool _isDisposed = false;

  /// Per-pending metadata used to enrich outcomes after the correlator
  /// resolves. Captures `method` so metrics and presence consumers can
  /// pivot per JSON-RPC method without re-parsing the body.
  final Map<String, _PendingMeta> _meta = <String, _PendingMeta>{};

  static const String _eventCommandResponse = 'agents:command_response';
  static const String _eventAppError = 'app:error';

  @override
  Stream<AgentCommandOutcome> outcomes() => _outcomes.stream;

  @override
  Future<Map<String, dynamic>> sendAgentsCommand({
    required String agentId,
    required Map<String, Object?> body,
    required String rpcId,
    Duration? timeout,
    bool coalesce = true,
  }) {
    if (_isDisposed) {
      return Future<Map<String, dynamic>>.error(
        const SocketDispatchDisconnected(message: 'Dispatcher disposed'),
      );
    }
    if (!_coalescingEnabled || !coalesce) {
      return _dispatchAgentsCommand(
        agentId: agentId,
        body: body,
        rpcId: rpcId,
        timeout: timeout,
      );
    }
    final key = SocketCoalesceKey.compute(agentId: agentId, body: body);
    if (key == null) {
      // Body not coalesce-eligible (e.g. no method); fire normally.
      return _dispatchAgentsCommand(
        agentId: agentId,
        body: body,
        rpcId: rpcId,
        timeout: timeout,
      );
    }
    final followerFuture = _coalescer.tryJoinAsFollower(
      key: key,
      rpcId: rpcId,
      agentId: agentId,
      onJoined: (_) {
        final methodFollower = _extractMethod(body);
        final followerStopwatch = Stopwatch()..start();
        _meta[rpcId] = _PendingMeta(
          agentId: agentId,
          stopwatch: followerStopwatch,
          method: methodFollower,
        );
      },
    );
    if (followerFuture != null) {
      return followerFuture.whenComplete(() {
        final meta = _meta.remove(rpcId);
        meta?.stopwatch.stop();
      });
    }
    final hubFuture = _dispatchAgentsCommand(
      agentId: agentId,
      body: body,
      rpcId: rpcId,
      timeout: timeout,
    );
    return _coalescer.beginLead(
      key: key,
      rpcId: rpcId,
      hubFuture: hubFuture,
    );
  }

  Future<Map<String, dynamic>> _dispatchAgentsCommand({
    required String agentId,
    required Map<String, Object?> body,
    required String rpcId,
    Duration? timeout,
  }) async {
    try {
      await _connection.connect();
    } on ConsumerSocketTerminalException catch (e) {
      // Typed terminal failures from the connection layer. The exhaustive
      // switch lets the compiler verify every subtype is mapped — no more
      // fragile message.startsWith() parsing.
      switch (e) {
        case ConsumerSocketNamespaceForbidden():
          // Hub policy excludes this JWT role — REST fallback takes over.
          throw SocketDispatchNamespaceForbidden(
            message: e.message,
            role: e.role,
            namespace: e.namespace,
            cause: e,
          );
        case ConsumerSocketConnectCancelled():
        case ConsumerSocketReconnectExhausted():
        case ConsumerSocketHubForcedDisconnect():
          throw SocketDispatchDisconnected(
            message: 'Connect failed before dispatch: $e',
            cause: e,
          );
        case ConsumerSocketAuthFailed():
          throw SocketDispatchUnauthorized(
            message: 'Cannot connect to consumer socket: $e',
            cause: e,
          );
      }
    } on Object catch (e, s) {
      _emitTransient(
        agentId: agentId,
        rpcId: rpcId,
        elapsed: Duration.zero,
        reasonCode: 'connect_failed',
        cause: e,
      );
      throw SocketDispatchDisconnected(
        message: 'Connect failed before dispatch: $e',
        cause: e,
        stackTrace: s,
      );
    }

    _ensureListenersAttached();

    // Per-agent concurrency gate: bounds how many in-flight RPCs run for
    // the same agent. The wait happens AFTER connect() (no point queuing
    // if we cannot reach the hub) and BEFORE register/emit so the
    // correlator timeout window starts only when we actually emit.
    final gate = _concurrencyGate;
    if (gate != null) {
      try {
        await gate.acquire(agentId);
      } on TimeoutException catch (e, s) {
        _emitTransient(
          agentId: agentId,
          rpcId: rpcId,
          elapsed: Duration.zero,
          reasonCode: 'gate_acquire_timeout',
          cause: e,
        );
        throw SocketDispatchTimeout(
          message: 'Per-agent concurrency gate acquire timed out: $e',
          cause: e,
          stackTrace: s,
        );
      } on Object catch (e, s) {
        _emitTransient(
          agentId: agentId,
          rpcId: rpcId,
          elapsed: Duration.zero,
          reasonCode: 'gate_acquire_failed',
          cause: e,
        );
        throw SocketDispatchDisconnected(
          message: 'Per-agent concurrency gate acquire failed: $e',
          cause: e,
          stackTrace: s,
        );
      }
    }

    final method = _extractMethod(body);
    final effectiveTimeout = _resolveTimeout(
      explicitTimeout: timeout,
      agentId: agentId,
      method: method,
    );
    final stopwatch = Stopwatch()..start();
    _meta[rpcId] = _PendingMeta(
      agentId: agentId,
      stopwatch: stopwatch,
      method: method,
    );

    Future<Map<String, dynamic>> pending;
    try {
      pending = _correlator.register(rpcId, timeout: effectiveTimeout);
    } on SocketDispatchDuplicateId catch (e) {
      _meta.remove(rpcId);
      gate?.release(agentId);
      _emitTransient(
        agentId: agentId,
        rpcId: rpcId,
        elapsed: Duration.zero,
        reasonCode: 'duplicate_id',
        method: method,
        cause: e,
      );
      rethrow;
    } on Object {
      _meta.remove(rpcId);
      gate?.release(agentId);
      rethrow;
    }

    try {
      // Hub item 4 (`requestServerTimings`): augment the outbound body
      // with the opt-in flag so the hub attaches `serverTimings` to the
      // response. Shallow-copy preserves caller immutability.
      final emitBody = AppEnvironment.socketRequestServerTimingsEnabled
          ? <String, Object?>{...body, 'requestServerTimings': true}
          : body;
      _connection.raw.emit('agents:command', emitBody);
    } on Object catch (e, s) {
      _correlator.failWith(rpcId, e, s);
      _meta.remove(rpcId);
      gate?.release(agentId);
      _emitTransient(
        agentId: agentId,
        rpcId: rpcId,
        elapsed: stopwatch.elapsed,
        reasonCode: 'emit_failed',
        method: method,
        cause: e,
      );
      throw SocketDispatchDisconnected(
        message: 'emit failed: $e',
        cause: e,
        stackTrace: s,
      );
    }

    try {
      final response = await pending;
      stopwatch.stop();
      _emitOutcomeFromResponse(
        agentId: agentId,
        rpcId: rpcId,
        elapsed: stopwatch.elapsed,
        response: response,
        method: method,
      );
      // Hub item 4: parse `serverTimings` from the response envelope and
      // push to the metrics sink via the optional callback. Silent when
      // the consumer did not opt in or the field is missing.
      final serverTimings = ServerTimings.tryParseFromEnvelope(response);
      if (serverTimings != null) {
        _onServerTimings?.call(serverTimings);
      }
      return response;
    } on SocketDispatchException catch (e) {
      stopwatch.stop();
      _emitOutcomeFromException(
        agentId: agentId,
        rpcId: rpcId,
        elapsed: stopwatch.elapsed,
        exception: e,
        method: method,
      );
      rethrow;
    } finally {
      _meta.remove(rpcId);
      gate?.release(agentId);
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

  /// Picks the timeout in this order:
  ///
  /// 1. [explicitTimeout] when the caller passed one.
  /// 2. `AgentLatencyOracle.suggestTimeout` when the oracle is enabled
  ///    and the [method] is known. Honors [_defaultTimeout] as the
  ///    oracle's `fallback` (used while the oracle is still warming up).
  /// 3. [_defaultTimeout] otherwise.
  Duration _resolveTimeout({
    required Duration? explicitTimeout,
    required String agentId,
    required String? method,
  }) {
    if (explicitTimeout != null) {
      return explicitTimeout;
    }
    final oracle = _latencyOracle;
    if (oracle != null && method != null) {
      return oracle.suggestTimeout(
        agentId: agentId,
        method: method,
        fallback: _defaultTimeout,
      );
    }
    return _defaultTimeout;
  }

  @override
  void cancel(String rpcId, {String reason = 'caller_cancelled'}) {
    if (_isDisposed) {
      return;
    }
    final followerCompleter = _coalescer.takeFollower(rpcId);
    if (followerCompleter != null) {
      final metaFollower = _meta.remove(rpcId);
      if (metaFollower != null) {
        metaFollower.stopwatch.stop();
        _emitTransient(
          agentId: metaFollower.agentId,
          rpcId: rpcId,
          elapsed: metaFollower.stopwatch.elapsed,
          reasonCode: 'cancelled',
          method: metaFollower.method,
        );
      }
      if (!followerCompleter.isCompleted) {
        followerCompleter.completeError(
          SocketDispatchCancelled(
            message: 'Request cancelled by caller (reason=$reason)',
          ),
        );
      }
      return;
    }
    final meta = _meta[rpcId];
    if (meta == null) {
      return;
    }
    final leaderCoalesceKey = _coalescer.leaderKeyForRpcId(rpcId);
    final hasFollowers =
        leaderCoalesceKey != null &&
        _coalescer.hasFollowersForKey(leaderCoalesceKey);
    final cancelled = SocketDispatchCancelled(
      message: 'Request cancelled by caller (reason=$reason)',
    );
    if (hasFollowers) {
      _meta.remove(rpcId);
      meta.stopwatch.stop();
      final leaderClient = _coalescer.takeLeaderClientCompleter(rpcId);
      if (leaderClient != null && !leaderClient.isCompleted) {
        leaderClient.completeError(cancelled);
      }
      _emitTransient(
        agentId: meta.agentId,
        rpcId: rpcId,
        elapsed: meta.stopwatch.elapsed,
        reasonCode: 'cancelled',
        method: meta.method,
      );
      return;
    }
    _correlator.failWith(
      rpcId,
      cancelled,
    );
    _emitTransient(
      agentId: meta.agentId,
      rpcId: rpcId,
      elapsed: meta.stopwatch.elapsed,
      reasonCode: 'cancelled',
      method: meta.method,
    );
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
    await _correlator.dispose();
    _coalescer.dispose();
    if (!_outcomes.isClosed) {
      await _outcomes.close();
    }
    _meta.clear();
  }

  // ----- Internals -----

  void _ensureListenersAttached() {
    final socket = _connection.raw;
    if (identical(_attachedSocket, socket)) {
      return;
    }
    _detachListeners();
    socket
      ..on(_eventCommandResponse, _onCommandResponse)
      ..on(_eventAppError, _onAppError);
    _attachedSocket = socket;
    AppLogger.debug(
      'Attached agents:command listeners to active socket',
      context: <String, Object?>{
        'component': 'SocketCommandDispatcherImpl',
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
        ..off(_eventCommandResponse, _onCommandResponse)
        ..off(_eventAppError, _onAppError);
    } on Object catch (_) {
      // Socket is already being torn down; the next connect will attach
      // listeners to the new raw socket instance.
    }
    _attachedSocket = null;
  }

  void _onCommandResponse(Object? raw) {
    final normalizedRaw = _normalizeCommandResponseRaw(raw);
    Map<String, dynamic>? decodedMap;
    try {
      decodedMap = decodeAgentsWirePayloadMap(
        normalizedRaw,
        codec: _payloadFrameCodec,
      );
    } on PayloadFrameDecodeException catch (error, stackTrace) {
      AppLogger.warning(
        'agents:command_response PayloadFrame decode failed',
        context: <String, Object?>{
          'component': 'SocketCommandDispatcherImpl',
          'code': error.code,
          'pendingCount': _correlator.pendingCount,
        },
        error: error,
        stackTrace: stackTrace,
      );
      _failUncorrelatableCommandResponse(
        SocketDispatchDecodeFailure(
          message:
              'agents:command_response PayloadFrame decode failed: '
              '${error.code}',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
      return;
    }
    final map = _unwrapAgentsCommandResponseEnvelope(decodedMap);
    if (map == null) {
      AppLogger.warning(
        'agents:command_response is not a Map',
        context: <String, Object?>{
          'component': 'SocketCommandDispatcherImpl',
          'pendingCount': _correlator.pendingCount,
        },
      );
      _failUncorrelatableCommandResponse(
        const SocketDispatchDecodeFailure(
          message: 'agents:command_response is not a Map',
        ),
      );
      return;
    }
    var rpcId = _extractRpcId(map);
    rpcId ??= _disambiguateSqlExecuteBatchRpcId(map);
    if (rpcId == null && _failFlatTopLevelBridgeIfPossible(map)) {
      return;
    }
    if (rpcId == null) {
      AppLogger.warning(
        'agents:command_response missing rpcId',
        context: <String, Object?>{
          'component': 'SocketCommandDispatcherImpl',
          'topLevelKeys': map.keys.take(32).join(','),
          'pendingCount': _correlator.pendingCount,
          'batchDispatchMetaCount': _meta.values
              .where((m) => m.method == 'sql.executeBatch')
              .length,
          'rawRuntimeType': raw.runtimeType.toString(),
        },
      );
      _failUncorrelatableCommandResponse(
        const SocketDispatchDecodeFailure(
          message: 'agents:command_response missing rpcId',
        ),
      );
      return;
    }
    if (_isLegacyStreamingResponse(map)) {
      final streamId = _legacyStreamId(map);
      AppLogger.warning(
        'agents:command_response uses legacy stream_id on unary path; not supported',
        context: <String, Object?>{
          'component': 'SocketCommandDispatcherImpl',
          'rpcId': rpcId,
          'streamId': streamId,
        },
      );
      _correlator.failWith(
        rpcId,
        SocketDispatchLegacyStreamingUnsupported(
          message:
              'Hub returned stream_id=$streamId on the legacy agents:command '
              'path. Colmeia does not implement agents:stream_pull for this '
              'channel. Use relay (useRelay: true) or REST for this query.',
          streamId: streamId,
        ),
      );
      return;
    }
    // Top-level bridge failure (overload shed, auth, etc.):
    // `{ success: false, requestId, error: { code, retryAfterMs? } }`.
    // Fail the pending with SocketDispatchAppError so retry policies see
    // the backoff hint — do not completeWith the error map as success.
    if (map['success'] == false) {
      _correlator.failWith(rpcId, _flatBridgeFailureException(map));
      return;
    }
    _correlator.completeWith(rpcId, map);
  }

  void _onAppError(Object? raw) {
    final map = _toStringKeyedMap(raw) ?? const <String, dynamic>{};
    final error = _toStringKeyedMap(map['error']);
    final rpcId = _extractRpcId(map);
    final code =
        (map['code'] as Object?)?.toString() ??
        (error?['code'] as Object?)?.toString() ??
        'app_error';
    final message =
        (map['message'] as Object?)?.toString() ??
        (map['userMessage'] as Object?)?.toString() ??
        (error?['message'] as Object?)?.toString() ??
        code;
    final exception = SocketDispatchAppError(
      message: message,
      serverCode: code,
      retryAfter: extractRetryAfterFromAppError(map),
    );

    if (ConsumerSocketAppErrorCodes.isTerminal(code)) {
      // Connection layer owns teardown + intentional disconnect reason.
      // Fail all pendings here so callers do not hang until disconnect.
      _correlator.failAll(exception);
      return;
    }

    if (rpcId != null) {
      _correlator.failWith(rpcId, exception);
      return;
    }
    // Global app:error (e.g., SERVICE_UNAVAILABLE on overload). Fail all.
    _correlator.failAll(exception);
  }

  void _onConnectionState(ConsumerSocketConnectionState state) {
    switch (state) {
      case ConsumerSocketDisconnected():
      case ConsumerSocketError():
      case ConsumerSocketUnauthorized():
        _detachListeners();
        _coalescer.failFollowersAndClearInflight(
          const SocketDispatchDisconnected(
            message: 'Socket transitioned away from connected',
          ),
        );
        _correlator.failAll(
          const SocketDispatchDisconnected(
            message: 'Socket transitioned away from connected',
          ),
        );
      case ConsumerSocketConnected():
      case ConsumerSocketConnecting():
        break;
    }
  }

  /// Fail-fast for responses that cannot be correlated to a specific rpcId.
  ///
  /// Hub contract expects corrupted/uncorrelatable frames to release the
  /// waiter instead of hanging until the correlator timeout. With a single
  /// pending request the failure is unambiguous; with multiple pendings we
  /// fail all to avoid leaving callers blocked on a poisoned channel.
  void _failUncorrelatableCommandResponse(SocketDispatchException failure) {
    final soleId = _correlator.solePendingRpcIdWhenUnambiguous;
    if (soleId != null) {
      _correlator.failWith(soleId, failure);
      return;
    }
    if (_correlator.pendingCount > 0) {
      _correlator.failAll(failure);
    }
  }

  Map<String, dynamic>? _toStringKeyedMap(Object? raw) =>
      socketToStringKeyedMap(raw);

  /// Socket.IO may deliver `agents:command_response` as a single-arg Map or
  /// as a multi-arg list (first Map wins).
  Object? _normalizeCommandResponseRaw(Object? raw) {
    if (raw is List<dynamic>) {
      if (raw.length == 1) {
        return raw.first;
      }
      for (final Object? element in raw) {
        if (element is Map) {
          return element;
        }
      }
      return null;
    }
    return raw;
  }

  /// Some hubs wrap the REST bridge envelope under `result` / `data` /
  /// `payload` instead of emitting it at the event root.
  Map<String, dynamic>? _unwrapAgentsCommandResponseEnvelope(
    Map<String, dynamic>? map,
  ) {
    if (map == null) {
      return null;
    }
    if (map['response'] is Map) {
      return map;
    }
    for (final wrapKey in <String>['result', 'data', 'payload']) {
      final inner = map[wrapKey];
      if (inner is Map) {
        final nested = _toStringKeyedMap(inner);
        if (nested != null && nested['response'] is Map) {
          return nested;
        }
      }
    }
    return map;
  }

  String? _extractRpcId(Map<String, dynamic> map) {
    final candidates = <Object?>[
      map['clientRequestId'],
      map['client_request_id'],
      map['rpcId'],
      map['rpc_id'],
      map['requestId'],
      map['request_id'],
      // JSON-RPC 2.0 request id echo (plug hubs often mirror `command.id`
      // here; `sql.executeBatch` batch envelopes may omit `rpcId`/`requestId`).
      map['id'],
      _read(map, const <String>['result', 'id']),
      _read(map, const <String>['result', 'rpcId']),
      _read(map, const <String>['response', 'item', 'id']),
      _read(map, const <String>['command', 'id']),
    ];
    for (final candidate in candidates) {
      final resolved = _coerceRpcId(candidate);
      if (resolved != null) {
        return resolved;
      }
    }
    return null;
  }

  static String? _coerceRpcId(Object? candidate) {
    if (candidate is String && candidate.isNotEmpty) {
      return candidate;
    }
    if (candidate is num) {
      return candidate.toString();
    }
    return null;
  }

  /// Some hubs mirror REST-only `sql.executeBatch` bodies on
  /// `agents:command_response` without `rpcId` / `requestId` / JSON-RPC `id`.
  ///
  /// When that happens we may still disambiguate:
  ///
  /// * If exactly one in-flight **correlator** pending is a `sql.executeBatch`
  ///   (dispatcher metadata plus `SocketRequestCorrelator.hasPendingRpcId`),
  ///   use that pending id. Coalesced followers share the leader's hub flight but
  ///   only the leader is registered in the correlator — filtering avoids
  ///   treating followers as separate batch flights.
  /// * If that payload matches a known batch wire shape, correlate
  ///   immediately; else when the correlator's `pendingCount` is `1`
  ///   and the map looks like a generic bridge success (`response` map, no
  ///   top-level `error`), correlate to that sole batch leader.
  /// * If there is no batch metadata match but the correlator has exactly one
  ///   pending request and the payload matches a known batch wire shape, use
  ///   that sole pending id (legacy path).
  List<String> _pendingSqlExecuteBatchRpcIdsInCorrelator() {
    return _meta.entries
        .where(
          (e) =>
              e.value.method == 'sql.executeBatch' &&
              _correlator.hasPendingRpcId(e.key),
        )
        .map((e) => e.key)
        .toList(growable: false);
  }

  String? _disambiguateSqlExecuteBatchRpcId(Map<String, dynamic> map) {
    final pendingBatchRpcIds = _pendingSqlExecuteBatchRpcIdsInCorrelator();

    if (pendingBatchRpcIds.length == 1) {
      final inferred = pendingBatchRpcIds.single;
      if (_isCorrelatableSqlExecuteBatchWireEnvelope(map)) {
        AppLogger.debug(
          'agents:command_response correlated via sql.executeBatch dispatch '
          'metadata (hub omitted correlation fields; batch wire shape)',
          context: <String, Object?>{
            'component': 'SocketCommandDispatcherImpl',
            'rpcId': inferred,
          },
        );
        return inferred;
      }
      if (_correlator.pendingCount == 1 &&
          map['error'] == null &&
          (map['response'] is Map || _flatTopLevelBridgeSuccess(map))) {
        AppLogger.debug(
          'agents:command_response correlated via sql.executeBatch dispatch '
          'metadata (hub omitted correlation fields; sole pending bridge '
          'envelope)',
          context: <String, Object?>{
            'component': 'SocketCommandDispatcherImpl',
            'rpcId': inferred,
          },
        );
        return inferred;
      }
      return null;
    }

    if (pendingBatchRpcIds.isEmpty) {
      if (!_isCorrelatableSqlExecuteBatchWireEnvelope(map)) {
        return null;
      }
      final sole = _correlator.solePendingRpcIdWhenUnambiguous;
      if (sole != null) {
        AppLogger.debug(
          'agents:command_response correlated via sole pending rpcId '
          '(batch envelope without wire id; no batch method in metadata)',
          context: <String, Object?>{
            'component': 'SocketCommandDispatcherImpl',
            'rpcId': sole,
          },
        );
      }
      return sole;
    }
    return null;
  }

  /// Plug hubs sometimes emit `{success, error}` at the root with no
  /// `response` object on `agents:command_response`.
  bool _flatTopLevelBridgeSuccess(Map<String, dynamic> map) {
    if (map['response'] != null) {
      return false;
    }
    if (map['success'] != true) {
      return false;
    }
    final err = map['error'];
    if (err == null) {
      return true;
    }
    if (err is Map && err.isEmpty) {
      return true;
    }
    if (err is String && err.isEmpty) {
      return true;
    }
    return false;
  }

  bool _flatTopLevelBridgeFailure(Map<String, dynamic> map) {
    if (map['response'] != null) {
      return false;
    }
    if (map['success'] == false) {
      return true;
    }
    final err = map['error'];
    if (err is Map && err.isNotEmpty) {
      return true;
    }
    if (err is String && err.isNotEmpty) {
      return true;
    }
    return false;
  }

  bool _failFlatTopLevelBridgeIfPossible(Map<String, dynamic> map) {
    if (!_flatTopLevelBridgeFailure(map)) {
      return false;
    }
    final leaders = _pendingSqlExecuteBatchRpcIdsInCorrelator();
    if (leaders.length != 1) {
      return false;
    }
    _correlator.failWith(leaders.single, _flatBridgeFailureException(map));
    return true;
  }

  Object _flatBridgeFailureException(Map<String, dynamic> map) {
    final retryAfter = extractRetryAfterFromAppError(map);
    final err = map['error'];
    if (err is Map<String, dynamic>) {
      final code = err['code']?.toString() ?? 'bridge_error';
      final message =
          err['message']?.toString() ?? err['reason']?.toString() ?? code;
      return SocketDispatchAppError(
        message: message,
        serverCode: code,
        retryAfter: retryAfter,
      );
    }
    if (err is Map) {
      final m = Map<String, dynamic>.from(err);
      final code = m['code']?.toString() ?? 'bridge_error';
      final message =
          m['message']?.toString() ?? m['reason']?.toString() ?? code;
      return SocketDispatchAppError(
        message: message,
        serverCode: code,
        retryAfter: retryAfter,
      );
    }
    return const SocketDispatchDecodeFailure(
      message:
          'agents:command_response flat bridge failure without structured error',
    );
  }

  /// REST `parseBatchSuccess` parity (`response.item.result.items`) or
  /// coordinator-style `response.type == batch` with `items`.
  ///
  /// Omits strict `success: true` checks: some hubs leave flags out on
  /// success paths while still returning `items`.
  bool _isCorrelatableSqlExecuteBatchWireEnvelope(Map<String, dynamic> map) {
    if (_bridgeRestParityBatchWireShape(map)) {
      return true;
    }
    if (_coordinatorBatchWireShape(map)) {
      return true;
    }
    return _flatSqlExecuteBatchResponseWireShape(map);
  }

  /// `response.items` without `response.type == batch` and without the
  /// nested `item.result.items` REST shape — observed on some plug hubs.
  bool _flatSqlExecuteBatchResponseWireShape(Map<String, dynamic> map) {
    final response = map['response'];
    if (response is! Map) {
      return false;
    }
    if (response['success'] == false) {
      return false;
    }
    if (response['type'] == 'batch') {
      return false;
    }
    return response['items'] is List;
  }

  bool _bridgeRestParityBatchWireShape(Map<String, dynamic> map) {
    final response = map['response'];
    if (response is! Map) {
      return false;
    }
    if (response['success'] == false) {
      return false;
    }
    final item = response['item'];
    if (item is! Map) {
      return false;
    }
    if (item['success'] == false) {
      return false;
    }
    final result = item['result'];
    if (result is! Map) {
      return false;
    }
    return result['items'] is List;
  }

  bool _coordinatorBatchWireShape(Map<String, dynamic> map) {
    final response = map['response'];
    if (response is! Map) {
      return false;
    }
    if (response['type'] != 'batch') {
      return false;
    }
    if (response['success'] == false) {
      return false;
    }
    return response['items'] is List;
  }

  /// True when the hub signalled progressive streaming on the legacy
  /// `agents:command` channel via a non-empty `stream_id` / `streamId` in the
  /// JSON-RPC `result`. Colmeia does not implement `agents:stream_pull` or
  /// chunk events on this path — even a first chunk with partial `rows` would
  /// be incomplete without pull, so any `stream_id` is treated as unsupported.
  bool _isLegacyStreamingResponse(Map<String, dynamic> map) {
    final streamId = _legacyStreamId(map);
    return streamId != null && streamId.isNotEmpty;
  }

  String? _legacyStreamId(Map<String, dynamic> map) {
    final result = _read(map, const <String>['response', 'item', 'result']);
    if (result is! Map) {
      return null;
    }
    final value = result['stream_id'] ?? result['streamId'];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  Object? _read(Map<String, dynamic> map, List<String> path) {
    Object? current = map;
    for (final key in path) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  void _safeAddOutcome(AgentCommandOutcome outcome) {
    if (_outcomes.isClosed) {
      return;
    }
    _outcomes.add(outcome);
  }

  void _emitOutcomeFromResponse({
    required String agentId,
    required String rpcId,
    required Duration elapsed,
    required Map<String, dynamic> response,
    required String? method,
  }) {
    // Inspect response.item.error (if any) to classify the outcome.
    // This mirrors what the repository's parser will do, but without
    // importing the agent_queries feature.
    final errorMap = _read(response, const <String>[
      'response',
      'item',
      'error',
    ]);
    if (errorMap is Map) {
      final code = (errorMap['code'] as Object?)?.toString();
      final reason = (errorMap['reason'] as Object?)?.toString();
      final classification = _classifyRpcError(code: code, reason: reason);
      switch (classification) {
        case _RpcErrorClass.offline:
          _safeAddOutcome(
            AgentCommandFailedOffline(
              agentId: agentId,
              rpcId: rpcId,
              observedAt: DateTime.now().toUtc(),
              elapsed: elapsed,
              reasonCode: '${code ?? '-'}/${reason ?? '-'}',
              method: method,
            ),
          );
          return;
        case _RpcErrorClass.auth:
          _safeAddOutcome(
            AgentCommandFailedAuth(
              agentId: agentId,
              rpcId: rpcId,
              observedAt: DateTime.now().toUtc(),
              elapsed: elapsed,
              reasonCode: '${code ?? '-'}/${reason ?? '-'}',
              method: method,
            ),
          );
          return;
        case _RpcErrorClass.transient:
          _safeAddOutcome(
            AgentCommandFailedTransient(
              agentId: agentId,
              rpcId: rpcId,
              observedAt: DateTime.now().toUtc(),
              elapsed: elapsed,
              reasonCode: '${code ?? '-'}/${reason ?? '-'}',
              method: method,
            ),
          );
          return;
      }
    }

    _safeAddOutcome(
      AgentCommandSuccess(
        agentId: agentId,
        rpcId: rpcId,
        observedAt: DateTime.now().toUtc(),
        elapsed: elapsed,
        method: method,
      ),
    );
  }

  void _emitOutcomeFromException({
    required String agentId,
    required String rpcId,
    required Duration elapsed,
    required SocketDispatchException exception,
    required String? method,
  }) {
    if (exception is SocketDispatchAppError) {
      final classification = _classifyRpcError(code: exception.code);
      switch (classification) {
        case _RpcErrorClass.offline:
          _safeAddOutcome(
            AgentCommandFailedOffline(
              agentId: agentId,
              rpcId: rpcId,
              observedAt: DateTime.now().toUtc(),
              elapsed: elapsed,
              reasonCode: exception.code,
              method: method,
            ),
          );
          return;
        case _RpcErrorClass.auth:
          _safeAddOutcome(
            AgentCommandFailedAuth(
              agentId: agentId,
              rpcId: rpcId,
              observedAt: DateTime.now().toUtc(),
              elapsed: elapsed,
              reasonCode: exception.code,
              method: method,
            ),
          );
          return;
        case _RpcErrorClass.transient:
          break;
      }
    }
    _emitTransient(
      agentId: agentId,
      rpcId: rpcId,
      elapsed: elapsed,
      reasonCode: exception.code,
      method: method,
      cause: exception,
    );
  }

  void _emitTransient({
    required String agentId,
    required String rpcId,
    required Duration elapsed,
    required String reasonCode,
    String? method,
    Object? cause,
  }) {
    _safeAddOutcome(
      AgentCommandFailedTransient(
        agentId: agentId,
        rpcId: rpcId,
        observedAt: DateTime.now().toUtc(),
        elapsed: elapsed,
        reasonCode: reasonCode,
        method: method,
        cause: cause,
      ),
    );
  }

  _RpcErrorClass _classifyRpcError({String? code, String? reason}) {
    final normalizedCode = code?.toLowerCase();
    final normalizedReason = reason?.toLowerCase();

    const offlineSignals = <String>{
      'agent_offline',
      'protocol_not_ready',
      'agent_not_found',
      'agent_unreachable',
      'circuit_open',
    };
    const authSignals = <String>{
      'unauthorized',
      'authentication_failed',
      'agent_access_denied',
      'token_revoked',
      'missing_client_token',
    };

    if (normalizedReason != null && offlineSignals.contains(normalizedReason)) {
      return _RpcErrorClass.offline;
    }
    if (normalizedReason != null && authSignals.contains(normalizedReason)) {
      return _RpcErrorClass.auth;
    }
    if (normalizedCode != null) {
      if (offlineSignals.contains(normalizedCode)) {
        return _RpcErrorClass.offline;
      }
      if (authSignals.contains(normalizedCode)) {
        return _RpcErrorClass.auth;
      }
      // Hub JSON-RPC numeric codes for auth (api_rest_bridge.md):
      // -32001 (Authentication), -32002 (Unauthorized).
      if (normalizedCode == '-32001' || normalizedCode == '-32002') {
        return _RpcErrorClass.auth;
      }
    }
    return _RpcErrorClass.transient;
  }
}

class _PendingMeta {
  _PendingMeta({
    required this.agentId,
    required this.stopwatch,
    required this.method,
  });
  final String agentId;
  final Stopwatch stopwatch;
  final String? method;
}

enum _RpcErrorClass { offline, auth, transient }
