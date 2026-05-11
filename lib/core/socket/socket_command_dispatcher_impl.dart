import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/agent_command_outcome.dart';
import 'package:colmeia/core/socket/agent_latency_oracle.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/per_agent_concurrency_gate.dart';
import 'package:colmeia/core/socket/socket_app_error_retry_after.dart';
import 'package:colmeia/core/socket/socket_coalesce_key.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/core/socket/socket_request_correlator.dart';
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
/// JSON-RPC parsing remains in the repository.
///
/// See `docs/Features/socket_command_dispatcher_design.md` §5.
class SocketCommandDispatcherImpl implements SocketCommandDispatcher {
  SocketCommandDispatcherImpl({
    required ConsumerSocketConnection connection,
    required SocketRequestCorrelator correlator,
    PerAgentConcurrencyGate? concurrencyGate,
    AgentLatencyOracle? latencyOracle,
    Duration defaultTimeout = const Duration(seconds: 20),
    bool coalescingEnabled = true,
    void Function()? onCoalesced,
  }) : _connection = connection,
       _correlator = correlator,
       _concurrencyGate = concurrencyGate,
       _latencyOracle = latencyOracle,
       _defaultTimeout = defaultTimeout,
       _coalescingEnabled = coalescingEnabled,
       _onCoalesced = onCoalesced,
       _outcomes = StreamController<AgentCommandOutcome>.broadcast() {
    _stateSub = _connection.states().listen(_onConnectionState);
  }

  final ConsumerSocketConnection _connection;
  final SocketRequestCorrelator _correlator;
  final PerAgentConcurrencyGate? _concurrencyGate;
  final AgentLatencyOracle? _latencyOracle;
  final Duration _defaultTimeout;
  final bool _coalescingEnabled;
  final void Function()? _onCoalesced;
  final StreamController<AgentCommandOutcome> _outcomes;

  /// Maps `SocketCoalesceKey` → in-flight Future. Reused while the entry
  /// exists so concurrent identical sends share the same response (and
  /// the same error). Entries are removed when the underlying future
  /// settles.
  final Map<String, Future<Map<String, dynamic>>> _inflightByKey =
      <String, Future<Map<String, dynamic>>>{};

  /// Leader `rpcId` for each active coalesce `key` (registered in correlator).
  final Map<String, String> _coalesceLeaderRpcIdByKey = <String, String>{};

  /// Followers of a coalesced flight: separate [Future] per `rpcId` for
  /// targeted cancellation without cancelling the shared hub request.
  final Map<String, Completer<Map<String, dynamic>>> _coalesceAwaiterByRpcId =
      <String, Completer<Map<String, dynamic>>>{};

  /// Follower `rpcId` → coalesce `key`.
  final Map<String, String> _coalesceAwaiterKeyByRpcId = <String, String>{};

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
    final existing = _inflightByKey[key];
    if (existing != null) {
      _onCoalesced?.call();
      final leaderRpcId = _coalesceLeaderRpcIdByKey[key];
      AppLogger.debug(
        'Coalesced agents:command into in-flight request',
        context: <String, Object?>{
          'component': 'SocketCommandDispatcherImpl',
          'agentId': agentId,
          'followerRpcId': rpcId,
          'leaderRpcId': leaderRpcId,
        },
      );
      final followerCompleter = Completer<Map<String, dynamic>>();
      final methodFollower = _extractMethod(body);
      final followerStopwatch = Stopwatch()..start();
      _meta[rpcId] = _PendingMeta(
        agentId: agentId,
        stopwatch: followerStopwatch,
        method: methodFollower,
      );
      _coalesceAwaiterByRpcId[rpcId] = followerCompleter;
      _coalesceAwaiterKeyByRpcId[rpcId] = key;
      unawaited(
        existing
            .then<void>(
              (value) {
                followerStopwatch.stop();
                if (!followerCompleter.isCompleted) {
                  followerCompleter.complete(value);
                }
              },
              onError: (Object error, StackTrace stack) {
                followerStopwatch.stop();
                if (!followerCompleter.isCompleted) {
                  followerCompleter.completeError(error, stack);
                }
              },
            )
            .whenComplete(() {
              _meta.remove(rpcId);
              _coalesceAwaiterByRpcId.remove(rpcId);
              _coalesceAwaiterKeyByRpcId.remove(rpcId);
            }),
      );
      return followerCompleter.future;
    }
    final future = _dispatchAgentsCommand(
      agentId: agentId,
      body: body,
      rpcId: rpcId,
      timeout: timeout,
    );
    _inflightByKey[key] = future;
    _coalesceLeaderRpcIdByKey[key] = rpcId;
    // Always remove the entry once the future settles; do not surface
    // bookkeeping errors as request failures. The cleanup task is
    // intentionally fire-and-forget — callers track `future`, not this.
    unawaited(_clearCoalescingEntryWhenDone(key, future));
    return future;
  }

  Future<void> _clearCoalescingEntryWhenDone(
    String key,
    Future<Map<String, dynamic>> future,
  ) async {
    try {
      await future;
    } on Object {
      // The original future is still returned to callers. This helper only
      // prevents the cleanup task from reporting a second unhandled error.
    } finally {
      final current = _inflightByKey[key];
      if (identical(current, future)) {
        _inflightByKey.remove(key)?.ignore();
        _coalesceLeaderRpcIdByKey.remove(key);
      }
    }
  }

  Future<Map<String, dynamic>> _dispatchAgentsCommand({
    required String agentId,
    required Map<String, Object?> body,
    required String rpcId,
    Duration? timeout,
  }) async {
    try {
      await _connection.connect();
    }
    // ConsumerSocketConnection signals unrecoverable auth/usage errors via
    // StateError on purpose; this is the controlled exception to catch.
    // ignore: avoid_catching_errors
    on StateError catch (e) {
      // Two terminal failures share `StateError` as the wire shape —
      // disambiguate by the message marker the connection layer
      // emits for namespace rejection. Without this distinction the
      // upstream fallback datasource cannot tell "the JWT is bad"
      // from "the hub policy excludes this role" and would not
      // pivot to REST.
      final message = e.message;
      if (message.startsWith('Consumer socket namespace forbidden:')) {
        throw SocketDispatchNamespaceForbidden(
          message: message,
          role: _extractMarker(message, 'role='),
          namespace: _extractMarker(message, 'namespace='),
          cause: e,
        );
      }
      if (message.startsWith('Consumer socket connect cancelled:')) {
        throw SocketDispatchDisconnected(
          message: 'Connect cancelled before dispatch: $e',
          cause: e,
        );
      }
      throw SocketDispatchUnauthorized(
        message: 'Cannot connect to consumer socket: $e',
        cause: e,
      );
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
      await gate.acquire(agentId);
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
    }

    try {
      _connection.raw.emit('agents:command', body);
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
    final followerCompleter = _coalesceAwaiterByRpcId.remove(rpcId);
    if (followerCompleter != null) {
      _coalesceAwaiterKeyByRpcId.remove(rpcId);
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
      // Not pending — could be already settled or never registered.
      // Silent no-op keeps the API idempotent at the dispose-time
      // teardown of controllers that hold many tokens.
      return;
    }
    _correlator.failWith(
      rpcId,
      SocketDispatchCancelled(
        message: 'Request cancelled by caller (reason=$reason)',
      ),
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
    for (final c in _coalesceAwaiterByRpcId.values) {
      if (!c.isCompleted) {
        c.completeError(
          const SocketDispatchDisconnected(message: 'Dispatcher disposed'),
        );
      }
    }
    _coalesceAwaiterByRpcId.clear();
    _coalesceAwaiterKeyByRpcId.clear();
    _coalesceLeaderRpcIdByKey.clear();
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
        ..off(_eventCommandResponse)
        ..off(_eventAppError);
    } on Object catch (_) {
      // Socket is already being torn down; the next connect will attach
      // listeners to the new raw socket instance.
    }
    _attachedSocket = null;
  }

  void _onCommandResponse(Object? raw) {
    final map = _toStringKeyedMap(raw);
    if (map == null) {
      AppLogger.warning(
        'agents:command_response is not a Map',
        context: const <String, Object?>{
          'component': 'SocketCommandDispatcherImpl',
        },
      );
      return;
    }
    final rpcId = _extractRpcId(map);
    if (rpcId == null) {
      AppLogger.warning(
        'agents:command_response missing rpcId',
        context: const <String, Object?>{
          'component': 'SocketCommandDispatcherImpl',
        },
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
    _correlator.completeWith(rpcId, map);
  }

  void _onAppError(Object? raw) {
    final map = _toStringKeyedMap(raw) ?? const <String, dynamic>{};
    final rpcId = _extractRpcId(map);
    final code = (map['code'] as Object?)?.toString() ?? 'app_error';
    final message =
        (map['message'] as Object?)?.toString() ??
        (map['userMessage'] as Object?)?.toString() ??
        code;
    final exception = SocketDispatchAppError(
      message: message,
      serverCode: code,
      retryAfter: extractRetryAfterFromAppError(map),
    );

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

  Map<String, dynamic>? _toStringKeyedMap(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry<String, dynamic>(key.toString(), value),
      );
    }
    return null;
  }

  String? _extractRpcId(Map<String, dynamic> map) {
    final candidates = <Object?>[
      map['rpcId'],
      map['requestId'],
      _read(map, const <String>['response', 'item', 'id']),
      _read(map, const <String>['command', 'id']),
    ];
    for (final candidate in candidates) {
      if (candidate is String && candidate.isNotEmpty) {
        return candidate;
      }
    }
    return null;
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

  /// Pulls a `key=value` token out of the `StateError.message` the
  /// connection layer emits for namespace rejection, e.g.
  /// `... role=client namespace=/consumers ...`. Returns `null` when
  /// the marker is absent or unquoted weirdly so the caller can fall
  /// back to the unparsed original string.
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
