import 'dart:async';
import 'dart:math' as math;

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/app_socket_url_resolver.dart';
import 'package:colmeia/core/socket/connection_ready_payload.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
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
    final operation = _connectInternal().whenComplete(() {
      _inFlightConnect = null;
    });
    _inFlightConnect = operation;
    return operation;
  }

  /// Idempotent. Tears down the underlying socket without firing the auth
  /// invalidation stream — call [SocketAuthTokenProvider.sessionInvalidations]
  /// listeners only on real session loss.
  Future<void> disconnect({String? reason}) async {
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      try {
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

  Future<ConsumerSocketConnected> _connectInternal() async {
    var attempt = 0;
    var delay = _reconnectInitialDelay;

    while (true) {
      attempt += 1;
      _setState(ConsumerSocketConnecting(attempt: attempt));

      final outcome = await _connectOnce();
      switch (outcome) {
        case _ConnectSuccess():
          _setState(outcome.connectedState);
          return outcome.connectedState;

        case _ConnectAuthFailure():
          _setState(const ConsumerSocketUnauthorized());
          throw StateError(
            'Consumer socket unauthorized: ${outcome.reason}',
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
          await Future<void>.delayed(
            SocketReconnectBackoff.jittered(
              ceiling: delay,
              random: _random,
            ),
          );
          delay = SocketReconnectBackoff.nextCeiling(
            current: delay,
            maxDelay: _reconnectMaxDelay,
          );
      }
    }
  }

  Future<_ConnectOutcome> _connectOnce() async {
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
      ..onConnectError((err) async {
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
        // If the disconnect happens after we already moved to `connected`,
        // emit a clean disconnected state so callers can react.
        if (_state is! ConsumerSocketConnecting) {
          _setState(ConsumerSocketDisconnected(reason: reason?.toString()));
        }
      })
      ..connect();

    final outcome = await Future.any<_ConnectOutcome>(<Future<_ConnectOutcome>>[
      readyCompleter.future.then(
        (state) => _ConnectSuccess(connectedState: state),
      ),
      errorCompleter.future,
      _timeoutFuture(),
    ]);

    if (outcome is! _ConnectSuccess) {
      try {
        socket
          ..disconnect()
          ..dispose();
      } on Object catch (_) {
        // Already in shutdown path; nothing else to do.
      }
      _socket = null;
    }
    socket
      ..off('connection:ready')
      ..off('connect_error')
      ..off('disconnect');
    return outcome;
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

final class _ConnectAuthFailure extends _ConnectOutcome {
  const _ConnectAuthFailure({required this.reason});
  final String reason;
}

final class _ConnectTransientFailure extends _ConnectOutcome {
  const _ConnectTransientFailure({required this.error});
  final Object error;
}
