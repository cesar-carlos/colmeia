import 'package:colmeia/core/socket/socket_command_dispatcher.dart';

/// Bundle of in-flight `agents:command` rpcIds whose [cancelAll] is
/// invoked from a `dispose()` boundary (e.g. presentation controller,
/// route leaving) to fail-fast every pending dispatch with a
/// `SocketDispatchCancelled` exception.
///
/// Why a token instead of asking the controller to track ids itself:
///
/// - Controllers do not know how to cancel — they only know the lifecycle.
///   Encapsulating the dispatcher reference + idempotent bookkeeping
///   here keeps `SRP` clean: the controller calls `cancelAll()` and is
///   done.
/// - The same token can pool ids from multiple call sites (e.g. parallel
///   waves of an `AgentQueryExecutor.mergeAll`) and cancel them as a
///   group on a single tap.
///
/// Lifecycle:
///
/// - [register] adds an rpcId. Cheap to call once per
///   `sendAgentsCommand`.
/// - [unregister] removes a single rpcId — typically called from the
///   `Future.whenComplete` of a successful settle to keep the bag tidy.
/// - [cancelAll] fires `dispatcher.cancel(rpcId, reason)` for every
///   currently-tracked id and clears the bag. Idempotent.
/// - [dispose] is an alias for `cancelAll(reason: 'token_disposed')`.
class SocketCommandCancelToken {
  SocketCommandCancelToken({
    required SocketCommandDispatcher dispatcher,
    String defaultReason = 'caller_cancelled',
  }) : _dispatcher = dispatcher,
       _defaultReason = defaultReason;

  final SocketCommandDispatcher _dispatcher;
  final String _defaultReason;
  final Set<String> _pending = <String>{};
  bool _isDisposed = false;

  /// Currently tracked rpcId count. Useful for tests and metrics.
  int get pendingCount => _pending.length;

  /// True after [dispose] / [cancelAll]; further calls are no-op.
  bool get isDisposed => _isDisposed;

  /// Adds [rpcId] to the bag. Returns the id so callers can chain it
  /// next to the `sendAgentsCommand(rpcId: token.register(uuid))`.
  /// No-op once disposed.
  String register(String rpcId) {
    if (!_isDisposed) {
      _pending.add(rpcId);
    }
    return rpcId;
  }

  /// Removes [rpcId] from the bag. Use in
  /// `future.whenComplete(() => token.unregister(rpcId))` so completed
  /// requests do not get re-cancelled by a late `cancelAll`.
  void unregister(String rpcId) {
    _pending.remove(rpcId);
  }

  /// Fires `dispatcher.cancel(rpcId, reason)` for every tracked id and
  /// clears the bag. Subsequent calls are no-op.
  void cancelAll({String? reason}) {
    if (_pending.isEmpty) {
      return;
    }
    final ids = _pending.toList(growable: false);
    _pending.clear();
    for (final id in ids) {
      _dispatcher.cancel(id, reason: reason ?? _defaultReason);
    }
  }

  /// Convenience for `cancelAll(reason: 'token_disposed')`. Marks the
  /// token as disposed so [register] becomes a no-op.
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    cancelAll(reason: 'token_disposed');
  }
}
