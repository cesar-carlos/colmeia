import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';

/// Notified when a wire response targets an [rpcId] that no longer has a
/// pending registration (typically the client timeout fired first).
typedef SocketCorrelatorOrphanWireCallback =
    void Function({
      required String rpcId,
      required String operation,
      required int responseFieldCount,
    });

/// Maps `rpcId` → pending [Completer]. Owns timers and a periodic stale
/// sweep as defense-in-depth (e.g., when a [Timer] is delayed by an OS
/// suspend in background).
///
/// Does not know anything about Socket.IO; the dispatcher feeds responses
/// in (already decoded) and listens to the resolved [Future]s.
///
/// See `docs/Features/socket_command_dispatcher_design.md` §4.
class SocketRequestCorrelator {
  SocketRequestCorrelator({
    Duration sweepInterval = const Duration(minutes: 1),
    SocketCorrelatorOrphanWireCallback? onOrphanWireResponse,
  }) : _sweepInterval = sweepInterval,
       _onOrphanWireResponse = onOrphanWireResponse {
    _sweepTimer = Timer.periodic(_sweepInterval, (_) => _sweepStale());
  }

  final Duration _sweepInterval;
  final SocketCorrelatorOrphanWireCallback? _onOrphanWireResponse;
  Timer? _sweepTimer;

  final Map<String, _PendingRequest> _pending = <String, _PendingRequest>{};
  bool _isDisposed = false;

  /// Returns the pending count. Useful for metrics and tests.
  int get pendingCount => _pending.length;

  /// The only in-flight RPC id when [pendingCount] is exactly `1`;
  /// otherwise `null`.
  ///
  /// Used when the hub mirrors REST-only `sql.executeBatch` bodies on
  /// `agents:command_response` without `rpcId` / `requestId` / JSON-RPC `id`.
  String? get solePendingRpcIdWhenUnambiguous =>
      _pending.length == 1 ? _pending.keys.single : null;

  /// Registers a new request with [rpcId] and arms a timeout. Throws
  /// [SocketDispatchDuplicateId] when [rpcId] is already pending.
  Future<Map<String, dynamic>> register(
    String rpcId, {
    required Duration timeout,
  }) {
    if (_isDisposed) {
      throw const SocketDispatchDisconnected(
        message: 'Correlator disposed',
      );
    }
    if (_pending.containsKey(rpcId)) {
      throw SocketDispatchDuplicateId(
        message: 'rpcId already pending: $rpcId',
      );
    }
    final completer = Completer<Map<String, dynamic>>();
    final timer = Timer(timeout, () {
      final entry = _pending.remove(rpcId);
      if (entry == null) {
        return;
      }
      entry.timer.cancel();
      if (!entry.completer.isCompleted) {
        entry.completer.completeError(
          SocketDispatchTimeout(
            message: 'No response for rpcId=$rpcId after ${timeout.inSeconds}s',
          ),
        );
      }
    });
    _pending[rpcId] = _PendingRequest(
      completer: completer,
      timer: timer,
      registeredAt: DateTime.now(),
      timeout: timeout,
    );
    return completer.future;
  }

  /// Resolves the pending request with the normalized JSON response.
  /// Late responses (timeout already fired) are dropped after debug logging
  /// and invoking the orphan-wire callback (when wired).
  void completeWith(String rpcId, Map<String, dynamic> response) {
    final entry = _pending.remove(rpcId);
    if (entry == null) {
      _emitOrphanWire(
        rpcId: rpcId,
        operation: 'completeWith',
        responseFieldCount: response.length,
      );
      return;
    }
    entry.timer.cancel();
    if (!entry.completer.isCompleted) {
      entry.completer.complete(response);
    }
  }

  /// Resolves the pending request with [error].
  void failWith(String rpcId, Object error, [StackTrace? stack]) {
    final entry = _pending.remove(rpcId);
    if (entry == null) {
      _emitOrphanWire(
        rpcId: rpcId,
        operation: 'failWith',
        responseFieldCount: 0,
      );
      return;
    }
    entry.timer.cancel();
    if (!entry.completer.isCompleted) {
      entry.completer.completeError(error, stack);
    }
  }

  /// Cancels every pending request with [error]. Used on disconnect.
  void failAll(Object error, [StackTrace? stack]) {
    final entries = _pending.values.toList(growable: false);
    _pending.clear();
    for (final entry in entries) {
      entry.timer.cancel();
      if (!entry.completer.isCompleted) {
        entry.completer.completeError(error, stack);
      }
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _sweepTimer?.cancel();
    _sweepTimer = null;
    failAll(
      const SocketDispatchDisconnected(message: 'Correlator disposed'),
    );
  }

  /// Defense-in-depth: catches pendings whose [Timer] never fired (e.g.
  /// background suspend). Anything older than `2 * timeout` gets a
  /// synthetic timeout error.
  void _sweepStale() {
    if (_isDisposed) {
      return;
    }
    final now = DateTime.now();
    final stale = <String>[];
    for (final entry in _pending.entries) {
      final age = now.difference(entry.value.registeredAt);
      if (age > entry.value.timeout * 2) {
        stale.add(entry.key);
      }
    }
    for (final id in stale) {
      failWith(
        id,
        SocketDispatchTimeout(message: 'Stale request swept: rpcId=$id'),
      );
    }
  }

  void _emitOrphanWire({
    required String rpcId,
    required String operation,
    required int responseFieldCount,
  }) {
    AppLogger.debug(
      'Socket correlator dropped wire response (no pending rpcId)',
      context: <String, Object?>{
        'component': 'SocketRequestCorrelator',
        'operation': operation,
        'rpcId': rpcId,
        'responseFieldCount': responseFieldCount,
      },
    );
    final hook = _onOrphanWireResponse;
    if (hook != null) {
      hook(
        rpcId: rpcId,
        operation: operation,
        responseFieldCount: responseFieldCount,
      );
    }
  }
}

class _PendingRequest {
  _PendingRequest({
    required this.completer,
    required this.timer,
    required this.registeredAt,
    required this.timeout,
  });
  final Completer<Map<String, dynamic>> completer;
  final Timer timer;
  final DateTime registeredAt;
  final Duration timeout;
}
