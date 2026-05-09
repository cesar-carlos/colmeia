import 'dart:async';
import 'dart:math' as math;

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/app_socket_url_resolver.dart';
import 'package:colmeia/core/socket/connection_ready_payload.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/socket_app_error_retry_after.dart';
import 'package:colmeia/core/socket/socket_auth_token_provider.dart';
import 'package:colmeia/core/socket/socket_io_client_factory.dart';
import 'package:colmeia/core/socket/socket_reconnect_backoff.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Single Socket.IO connection to the `/consumers` namespace.
///
/// Phase 1 (PR-A) responsibilities:
///
/// 1. Single instance shared via `get_it`.
/// 2. Drives the handshake with the current JWT.
/// 3. Confirms `connection:ready` (decoded by [ConnectionReadyDecoder]).
/// 4. Exposes the [state] as a sealed class + broadcast [Stream].
/// 5. Reconnect policy with exponential backoff + **full jitter** and a hard
///    cap on attempts.
/// 6. Refreshes the access token once on auth-like `connect_error`; second
///    failure transitions to [ConsumerSocketUnauthorized] (terminal).
/// 7. Reacts to [SocketAuthTokenProvider.sessionInvalidations] by
///    disconnecting.
/// 8. `pause()` / `resume()` hooks for the app lifecycle (mobile economy).
///
/// Detailed contract: `docs/Features/consumer_socket_connection_design.md`.
class ConsumerSocketConnection {
  ConsumerSocketConnection({
    required AppSocketUrlResolver urlResolver,
    required SocketAuthTokenProvider tokenProvider,
    required SocketIoClientFactory factory,
    required ConnectionReadyDecoder readyDecoder,
    Duration handshakeTimeout = const Duration(seconds: 10),
    int maxReconnectAttempts = 5,
    Duration reconnectInitialDelay = const Duration(seconds: 1),
    Duration reconnectMaxDelay = const Duration(seconds: 30),
    math.Random? random,
  }) : _urlResolver = urlResolver,
       _tokenProvider = tokenProvider,
       _factory = factory,
       _readyDecoder = readyDecoder,
       _handshakeTimeout = handshakeTimeout,
       _maxReconnectAttempts = maxReconnectAttempts,
       _reconnectInitialDelay = reconnectInitialDelay,
       _reconnectMaxDelay = reconnectMaxDelay,
       _random = random ?? math.Random() {
    _sessionInvalidationSub = _tokenProvider.sessionInvalidations().listen(
      (_) => unawaited(disconnect(reason: 'session_invalidated')),
    );
  }

  final AppSocketUrlResolver _urlResolver;
  final SocketAuthTokenProvider _tokenProvider;
  final SocketIoClientFactory _factory;
  final ConnectionReadyDecoder _readyDecoder;
  final Duration _handshakeTimeout;
  final int _maxReconnectAttempts;
  final Duration _reconnectInitialDelay;
  final Duration _reconnectMaxDelay;
  final math.Random _random;

  io.Socket? _socket;
  StreamSubscription<void>? _sessionInvalidationSub;

  final StreamController<ConsumerSocketConnectionState> _states =
      StreamController<ConsumerSocketConnectionState>.broadcast();
  ConsumerSocketConnectionState _state = const ConsumerSocketDisconnected();

  Future<ConsumerSocketConnected>? _inFlightConnect;
  Completer<_ConnectOutcome>? _connectAbortCompleter;
  bool _isDisposed = false;

  // ----- Public API -----

  ConsumerSocketConnectionState get state => _state;

  bool get isConnected => _state is ConsumerSocketConnected;

  Stream<ConsumerSocketConnectionState> states() => _states.stream;

  /// Restricted access for adapters living in `core/socket/*` and
  /// `features/.../data/socket/*`. Presentation must never read this.
  io.Socket get raw {
    final socket = _socket;
    if (socket == null) {
      throw StateError(
        'ConsumerSocketConnection.raw read before connect()',
      );
    }
    return socket;
  }

  /// Idempotent + single-flight. Concurrent callers share the same Future and
  /// never open a second socket. Returns immediately when already connected.
  Future<ConsumerSocketConnected> connect() async {
    if (_isDisposed) {
      throw StateError('ConsumerSocketConnection used after dispose');
    }
    final inFlight = _inFlightConnect;
    if (inFlight != null) {
      return inFlight;
    }
    if (_state is ConsumerSocketConnected) {
      return _state as ConsumerSocketConnected;
    }
    final abortCompleter = Completer<_ConnectOutcome>();
    _connectAbortCompleter = abortCompleter;
    late final Future<ConsumerSocketConnected> operation;
    operation = _connectInternal(abortCompleter.future).whenComplete(() {
      if (identical(_inFlightConnect, operation)) {
        _inFlightConnect = null;
      }
      if (identical(_connectAbortCompleter, abortCompleter)) {
        _connectAbortCompleter = null;
      }
    });
    _inFlightConnect = operation;
    return operation;
  }

  /// Idempotent. Tears down the underlying socket without firing the auth
  /// invalidation stream — call [SocketAuthTokenProvider.sessionInvalidations]
  /// listeners only on real session loss.
  Future<void> disconnect({String? reason}) async {
    _cancelInFlightConnect(reason ?? 'disconnect');
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      try {
        _detachHandshakeListeners(socket, includeDisconnect: true);
        socket
          ..disconnect()
          ..dispose();
      } on Object catch (_) {
        // Swallow: state still transitions to disconnected below.
      }
    }
    _setState(ConsumerSocketDisconnected(reason: reason));
  }

  Future<ConsumerSocketConnected> reconnect({String? reason}) async {
    await disconnect(reason: reason);
    return connect();
  }

  /// App-lifecycle hooks: invoke from the root `WidgetsBindingObserver`.
  Future<void> pause() => disconnect(reason: 'app_paused');
  Future<ConsumerSocketConnected> resume() => connect();

  Future<void> dispose() async {
    _isDisposed = true;
    await _sessionInvalidationSub?.cancel();
    _sessionInvalidationSub = null;
    await disconnect(reason: 'disposed');
    if (!_states.isClosed) {
      await _states.close();
    }
  }

  // ----- Internals -----

  Future<ConsumerSocketConnected> _connectInternal(
    Future<_ConnectOutcome> abortSignal,
  ) async {
    var attempt = 0;
    var delay = _reconnectInitialDelay;

    while (true) {
      attempt += 1;
      _setState(ConsumerSocketConnecting(attempt: attempt));

      final outcome = await _connectOnce(abortSignal);
      switch (outcome) {
        case _ConnectSuccess():
          _setState(outcome.connectedState);
          return outcome.connectedState;

        case _ConnectCancelled():
          _setState(ConsumerSocketDisconnected(reason: outcome.reason));
          throw StateError(
            'Consumer socket connect cancelled: ${outcome.reason}',
          );

        case _ConnectAuthFailure():
          _setState(const ConsumerSocketUnauthorized());
          throw StateError(
            'Consumer socket unauthorized: ${outcome.reason}',
          );

        case _ConnectNamespaceForbidden():
          // Permanent: the hub's `SOCKET_CONSUMER_ROLES` does not
          // include the JWT's role. Retrying / refreshing does not
          // help — the upstream `SocketWithRestFallback…DataSource`
          // pivots to REST permanently for the rest of the
          // session. We surface a `StateError` here (same shape as
          // the other terminal failures) carrying the namespace +
          // role so the dispatcher's exception mapper can build a
          // `SocketDispatchNamespaceForbidden` with the parsed bits.
          AppLogger.warning(
            'Consumer socket handshake rejected by hub role policy',
            context: <String, Object?>{
              'operation': 'consumerSocketConnect',
              'hubOrigin': _urlResolver.hubOrigin,
              'socketNamespace': _urlResolver.namespace,
              'jwtRole': outcome.role,
              'hubMessage': outcome.message,
            },
          );
          _setState(const ConsumerSocketUnauthorized());
          throw StateError(
            'Consumer socket namespace forbidden: '
            'role=${outcome.role ?? "<unknown>"} '
            'namespace=${outcome.namespace ?? "<unknown>"} '
            'message=${outcome.message}',
          );

        case _ConnectTransientFailure():
          if (attempt >= _maxReconnectAttempts) {
            _setState(
              ConsumerSocketError(
                message: 'Max reconnect attempts reached ($attempt)',
                transient: false,
                cause: outcome.error,
              ),
            );
            throw StateError(
              'Consumer socket reconnect exhausted: ${outcome.error}',
            );
          }
          _setState(
            ConsumerSocketError(
              message: 'Transient socket failure (attempt $attempt)',
              transient: true,
              cause: outcome.error,
            ),
          );
          // Prefer the server hint when present: the hub explicitly told
          // us how long to wait (e.g. `SERVICE_UNAVAILABLE` shed-load on
          // `/consumers`). Falling back to our jittered backoff would
          // amplify the very congestion the hub is trying to drain.
          final serverHint = outcome.retryAfter;
          if (serverHint != null && serverHint > Duration.zero) {
            final cancelled = await _waitForCancellationOrDelay(
              abortSignal: abortSignal,
              delay: _clampServerHint(serverHint),
            );
            if (cancelled != null) {
              _setState(ConsumerSocketDisconnected(reason: cancelled.reason));
              throw StateError(
                'Consumer socket connect cancelled: ${cancelled.reason}',
              );
            }
            // Reset the local backoff floor — the next failure starts
            // from `reconnectInitialDelay` again so a single overload
            // window does not poison subsequent reconnects.
            delay = _reconnectInitialDelay;
          } else {
            final cancelled = await _waitForCancellationOrDelay(
              abortSignal: abortSignal,
              delay: SocketReconnectBackoff.jittered(
                ceiling: delay,
                random: _random,
              ),
            );
            if (cancelled != null) {
              _setState(ConsumerSocketDisconnected(reason: cancelled.reason));
              throw StateError(
                'Consumer socket connect cancelled: ${cancelled.reason}',
              );
            }
            delay = SocketReconnectBackoff.nextCeiling(
              current: delay,
              maxDelay: _reconnectMaxDelay,
            );
          }
      }
    }
  }

  /// Caps the server-provided hint to [_reconnectMaxDelay] so a buggy /
  /// adversarial hub cannot pin the client offline indefinitely.
  Duration _clampServerHint(Duration hint) {
    if (hint > _reconnectMaxDelay) {
      return _reconnectMaxDelay;
    }
    return hint;
  }

  Future<_ConnectCancelled?> _waitForCancellationOrDelay({
    required Future<_ConnectOutcome> abortSignal,
    required Duration delay,
  }) async {
    final result = await Future.any<Object?>(<Future<Object?>>[
      Future<void>.delayed(delay),
      abortSignal,
    ]);
    return result is _ConnectCancelled ? result : null;
  }

  Future<_ConnectOutcome> _connectOnce(
    Future<_ConnectOutcome> abortSignal,
  ) async {
    final token = await _tokenProvider.readAccessToken();
    if (token == null) {
      return const _ConnectAuthFailure(reason: 'no_token');
    }

    final url = _urlResolver.consumersUrl;
    if (url.isEmpty) {
      return const _ConnectTransientFailure(
        error: 'consumer_socket_url_empty',
      );
    }

    final socket = _factory.create(url: url, accessToken: token);
    _socket = socket;

    final readyCompleter = Completer<ConsumerSocketConnected>();
    final errorCompleter = Completer<_ConnectOutcome>();

    void resolveError(_ConnectOutcome outcome) {
      if (!errorCompleter.isCompleted) {
        errorCompleter.complete(outcome);
      }
    }

    socket
      ..on('connection:ready', (raw) {
        final decoded = _readyDecoder.decode(raw);
        if (decoded == null) {
          resolveError(
            const _ConnectTransientFailure(
              error: 'connection_ready_decode_failed',
            ),
          );
          return;
        }
        if (!readyCompleter.isCompleted) {
          readyCompleter.complete(
            ConsumerSocketConnected(
              socketId: decoded.socketId,
              handshakeAt: DateTime.now().toUtc(),
              hubInstanceId: decoded.hubInstanceId,
            ),
          );
        }
      })
      // The hub may emit `app:error` during the handshake window when
      // `/consumers` is shedding load
      // (`SOCKET_RELAY_OUTBOUND_OVERLOAD_BACKLOG`) or when an event quota
      // burns before `connection:ready`. Capture the `retryAfterMs` hint
      // so the reconnect loop can wait the requested window instead of
      // running its own (faster) jittered backoff and amplifying the
      // congestion. See `docs/socket_relay_protocol.md` (*Shed load*).
      ..on('app:error', (raw) {
        resolveError(_buildHandshakeAppErrorOutcome(raw));
      })
      ..onConnectError((err) async {
        // Distinguish hub-side namespace policy rejection ("Role
        // 'X' is not allowed to connect to /Y") from a real auth
        // failure: refresh / re-login does NOT fix a server-side
        // role allow-list, so we MUST NOT loop refreshing — emit
        // a permanent terminal state with the right semantics so
        // the upstream fallback (REST datasource) can take over.
        final namespaceRejection = _tryParseNamespaceForbidden(err);
        if (namespaceRejection != null) {
          resolveError(namespaceRejection);
          return;
        }
        if (_isAuthFailure(err)) {
          try {
            final refreshed = await _tokenProvider.refreshAccessToken();
            if (refreshed != null && refreshed.isNotEmpty) {
              resolveError(
                const _ConnectTransientFailure(
                  error: 'auth_refreshed_retry',
                ),
              );
              return;
            }
          } on Object catch (_) {
            // Treat refresh failure same as missing refresh below.
          }
          resolveError(const _ConnectAuthFailure(reason: 'refresh_failed'));
          return;
        }
        resolveError(
          _ConnectTransientFailure(error: (err as Object?) ?? 'connect_error'),
        );
      })
      ..onDisconnect((reason) {
        final reasonText = reason?.toString();
        if (identical(_socket, socket)) {
          _socket = null;
        }
        if (_state is ConsumerSocketConnecting && !readyCompleter.isCompleted) {
          resolveError(
            _ConnectTransientFailure(
              error:
                  'handshake_disconnected'
                  '${reasonText == null ? '' : ': $reasonText'}',
            ),
          );
          return;
        }
        // If the disconnect happens after we already moved to `connected`,
        // emit a clean disconnected state so callers can react.
        if (_state is! ConsumerSocketConnecting) {
          AppLogger.warning(
            'Consumer socket disconnected by remote peer',
            context: <String, Object?>{
              'component': 'ConsumerSocketConnection',
              'reason': reasonText,
            },
          );
          _setState(ConsumerSocketDisconnected(reason: reasonText));
        }
      })
      ..connect();

    final outcome = await Future.any<_ConnectOutcome>(<Future<_ConnectOutcome>>[
      readyCompleter.future.then(
        (state) => _ConnectSuccess(connectedState: state),
      ),
      errorCompleter.future,
      _timeoutFuture(),
      abortSignal,
    ]);

    if (outcome is! _ConnectSuccess) {
      try {
        _detachHandshakeListeners(socket, includeDisconnect: true);
        socket
          ..disconnect()
          ..dispose();
      } on Object catch (_) {
        // Already in shutdown path; nothing else to do.
      }
      _socket = null;
    } else {
      _detachHandshakeListeners(socket, includeDisconnect: false);
    }
    return outcome;
  }

  void _cancelInFlightConnect(String reason) {
    final abortCompleter = _connectAbortCompleter;
    if (abortCompleter != null && !abortCompleter.isCompleted) {
      abortCompleter.complete(_ConnectCancelled(reason: reason));
    }
    _connectAbortCompleter = null;
    _inFlightConnect = null;
  }

  void _detachHandshakeListeners(
    io.Socket socket, {
    required bool includeDisconnect,
  }) {
    socket
      ..off('connection:ready')
      ..off('app:error')
      ..off('connect_error');
    if (includeDisconnect) {
      socket.off('disconnect');
    }
  }

  /// Maps an `app:error` payload received during the handshake into a
  /// transient failure carrying the optional `retryAfterMs` the hub
  /// surfaces in shed-load / rate-limit responses. Mapping is permissive
  /// — anything we cannot parse is still treated as transient with a
  /// stable error code, so the reconnect loop keeps making progress
  /// instead of stalling on a malformed envelope.
  _ConnectTransientFailure _buildHandshakeAppErrorOutcome(Object? raw) {
    final map = _toStringKeyedMap(raw);
    if (map == null) {
      return const _ConnectTransientFailure(
        error: 'handshake_app_error_invalid_shape',
      );
    }
    final code = map['code']?.toString() ?? 'handshake_app_error';
    final retryAfter = extractRetryAfterFromAppError(map);
    return _ConnectTransientFailure(
      error: code,
      retryAfter: retryAfter,
    );
  }

  Map<String, Object?>? _toStringKeyedMap(Object? raw) {
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

  Future<_ConnectOutcome> _timeoutFuture() {
    return Future<_ConnectOutcome>.delayed(
      _handshakeTimeout,
      () => const _ConnectTransientFailure(error: 'handshake_timeout'),
    );
  }

  bool _isAuthFailure(Object? err) {
    if (err == null) {
      return false;
    }
    final message = err.toString().toLowerCase();
    return message.contains('401') ||
        message.contains('403') ||
        message.contains('unauthorized') ||
        message.contains('forbidden');
  }

  /// Detects the hub's namespace-policy rejection that ships in the
  /// `connect_error` payload as `{message: "Role 'X' is not allowed
  /// to connect to /Y"}`. Returns a `_ConnectNamespaceForbidden` with
  /// the parsed role/namespace so the loop can move to a permanent
  /// terminal state, OR `null` when the payload does not look like a
  /// namespace rejection (caller falls through to the generic auth /
  /// transient handling).
  _ConnectNamespaceForbidden? _tryParseNamespaceForbidden(Object? err) {
    if (err == null) {
      return null;
    }
    String? messageText;
    if (err is Map) {
      final candidate = err['message'];
      if (candidate is String) {
        messageText = candidate;
      }
    } else if (err is String) {
      messageText = err;
    } else {
      messageText = err.toString();
    }
    if (messageText == null) {
      return null;
    }
    // The hub uses this exact phrasing — see
    // `plug_server` consumers namespace handler. Tolerant to
    // surrounding whitespace / different quoting.
    // Triple-quoted raw string so the inner `'` and `"` do not need
    // escaping (a regular raw string can't contain its own delimiter).
    final pattern = RegExp(
      r'''role\s+['"](?<role>[^'"]+)['"]\s+is\s+not\s+allowed\s+to\s+connect\s+to\s+(?<ns>/?\S+)''',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(messageText);
    if (match == null) {
      return null;
    }
    return _ConnectNamespaceForbidden(
      message: messageText,
      role: match.namedGroup('role'),
      namespace: match.namedGroup('ns'),
    );
  }

  void _setState(ConsumerSocketConnectionState newState) {
    if (_isDisposed) {
      return;
    }
    _state = newState;
    AppLogger.debug(
      'ConsumerSocketConnection state changed',
      context: <String, Object?>{
        'component': 'ConsumerSocketConnection',
        'stateType': newState.runtimeType.toString(),
      },
    );
    if (!_states.isClosed) {
      _states.add(newState);
    }
  }
}

sealed class _ConnectOutcome {
  const _ConnectOutcome();
}

final class _ConnectSuccess extends _ConnectOutcome {
  const _ConnectSuccess({required this.connectedState});
  final ConsumerSocketConnected connectedState;
}

final class _ConnectCancelled extends _ConnectOutcome {
  const _ConnectCancelled({required this.reason});
  final String reason;
}

final class _ConnectAuthFailure extends _ConnectOutcome {
  const _ConnectAuthFailure({required this.reason});
  final String reason;
}

/// Hub rejected the handshake because the JWT's `role` is not in
/// `SOCKET_CONSUMER_ROLES`. Permanent until a server-side env edit
/// + restart — refresh / re-login does NOT help.
final class _ConnectNamespaceForbidden extends _ConnectOutcome {
  const _ConnectNamespaceForbidden({
    required this.message,
    this.role,
    this.namespace,
  });

  final String message;
  final String? role;
  final String? namespace;
}

final class _ConnectTransientFailure extends _ConnectOutcome {
  const _ConnectTransientFailure({required this.error, this.retryAfter});
  final Object error;

  /// Hint extracted from a server-emitted `app:error` (e.g.
  /// `SERVICE_UNAVAILABLE` shed-load on `/consumers`). When present the
  /// reconnect loop honors it as the next delay instead of running the
  /// jittered exponential backoff. Same semantics as
  /// `NetworkFailure.retryAfter` and `SocketDispatchAppError.retryAfter`
  /// — see `core/errors/app_failure.dart` and
  /// `socket_app_error_retry_after.dart`.
  final Duration? retryAfter;
}
