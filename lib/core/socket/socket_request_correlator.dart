import 'dart:async';

import 'package:colmeia/core/socket/socket_dispatch_exception.dart';

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
  }) : _sweepInterval = sweepInterval {
    _sweepTimer = Timer.periodic(_sweepInterval, (_) => _sweepStale());
  }

  final Duration _sweepInterval;
  Timer? _sweepTimer;

  final Map<String, _PendingRequest> _pending = <String, _PendingRequest>{};
  bool _isDisposed = false;

  /// Returns the pending count. Useful for metrics and tests.
  int get pendingCount => _pending.length;

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
            message:
                'No response for rpcId=$rpcId after ${timeout.inSeconds}s',
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
  /// Late responses (timeout already fired) are silently dropped.
  void completeWith(String rpcId, Map<String, dynamic> response) {
    final entry = _pending.remove(rpcId);
    if (entry == null) {
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
