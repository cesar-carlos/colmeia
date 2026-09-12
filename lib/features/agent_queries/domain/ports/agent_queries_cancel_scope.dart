import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher.dart';
import 'package:uuid/uuid.dart';

/// Target for hub-side `sql.cancel` when a streaming SQL load is abandoned.
class AgentStreamingSqlCancelTarget {
  const AgentStreamingSqlCancelTarget({
    required this.agentId,
    required this.streamId,
    this.clientToken,
  });

  final String agentId;
  final String streamId;
  final String? clientToken;
}

/// Cooperative cancellation for agent SQL loads (navigation, superseding
/// refresh). Call [cancelAll] when the UI abandons an in-flight load.
///
/// [traceId] is stable for the lifetime of the scope (one logical load) and
/// can be forwarded to bridge / relay metadata for hub correlation.
class AgentQueriesCancelScope {
  AgentQueriesCancelScope({String? traceId})
    : traceId = traceId ?? const Uuid().v4();

  /// Correlates all SQL commands issued under this load (relay `meta.trace_id`).
  final String traceId;

  bool _cancelled = false;
  final Set<String> _pendingRelayClientRequestIds = <String>{};
  final Set<String> _pendingSocketRpcIds = <String>{};
  final Set<void Function()> _pendingRestCancellations = <void Function()>{};
  final Map<String, AgentStreamingSqlCancelTarget> _streamingCancelTargets =
      <String, AgentStreamingSqlCancelTarget>{};
  final Set<void Function()> _localCancellationHandlers = <void Function()>{};

  /// Fail-fast pending relay RPCs ([RelayCommandDispatcher.cancel]).
  void Function(Iterable<String> clientRequestIds)? relayCancelHandler;

  /// Fail-fast pending `agents:command` RPCs ([SocketCommandDispatcher.cancel]).
  void Function(Iterable<String> rpcIds)? socketRpcCancelHandler;

  /// Best-effort hub `sql.cancel` for open streams.
  void Function(Iterable<AgentStreamingSqlCancelTarget> targets)?
  streamingSqlCancelHandler;

  void trackRelayPending(String clientRequestId) {
    if (_cancelled) {
      return;
    }
    _pendingRelayClientRequestIds.add(clientRequestId);
  }

  void untrackRelayPending(String clientRequestId) {
    _pendingRelayClientRequestIds.remove(clientRequestId);
  }

  void trackSocketPending(String rpcId) {
    if (_cancelled) {
      return;
    }
    _pendingSocketRpcIds.add(rpcId);
  }

  void untrackSocketPending(String rpcId) {
    _pendingSocketRpcIds.remove(rpcId);
  }

  /// Fail-fast pending REST bridge POSTs (Dio HTTP cancellation).
  void trackRestPending(void Function() cancelRequest) {
    if (_cancelled) {
      return;
    }
    _pendingRestCancellations.add(cancelRequest);
  }

  void untrackRestPending(void Function() cancelRequest) {
    _pendingRestCancellations.remove(cancelRequest);
  }

  /// Registers a hub stream id once known. Repeated observations of the same
  /// agent/stream pair are idempotent.
  void trackStreamingSql(AgentStreamingSqlCancelTarget target) {
    if (_cancelled) {
      return;
    }
    _streamingCancelTargets.putIfAbsent(_streamingKey(target), () => target);
  }

  /// Removes a stream that completed normally, so a later scope cancellation
  /// never sends a stale `sql.cancel` for already-finished work.
  void untrackStreamingSql(AgentStreamingSqlCancelTarget target) {
    _streamingCancelTargets.remove(_streamingKey(target));
  }

  /// Cancels exactly one tracked stream, at most once. This is used when the
  /// consumer aborts a stream due to a local collector/protocol failure.
  void cancelStreamingSql(AgentStreamingSqlCancelTarget target) {
    final tracked = _streamingCancelTargets.remove(_streamingKey(target));
    if (tracked == null) {
      return;
    }
    streamingSqlCancelHandler?.call(<AgentStreamingSqlCancelTarget>[tracked]);
  }

  /// Registers local work that has not reached a transport yet (for example,
  /// an item waiting in a per-agent queue). Returns an idempotent disposer.
  ///
  /// If the scope is already cancelled, [onCancel] runs immediately and the
  /// returned disposer is a no-op.
  void Function() registerLocalCancellation(void Function() onCancel) {
    if (_cancelled) {
      onCancel();
      return _noop;
    }
    _localCancellationHandlers.add(onCancel);
    var removed = false;
    return () {
      if (removed) {
        return;
      }
      removed = true;
      _localCancellationHandlers.remove(onCancel);
    };
  }

  void cancelAll() {
    if (_cancelled) {
      return;
    }
    _cancelled = true;
    final relayIds = List<String>.of(
      _pendingRelayClientRequestIds,
      growable: false,
    );
    final socketIds = List<String>.of(_pendingSocketRpcIds, growable: false);
    final restCancellations = List<void Function()>.of(
      _pendingRestCancellations,
      growable: false,
    );
    _pendingRelayClientRequestIds.clear();
    _pendingSocketRpcIds.clear();
    _pendingRestCancellations.clear();
    final streams = List<AgentStreamingSqlCancelTarget>.of(
      _streamingCancelTargets.values,
      growable: false,
    );
    _streamingCancelTargets.clear();
    final localCancellations = List<void Function()>.of(
      _localCancellationHandlers,
      growable: false,
    );
    _localCancellationHandlers.clear();

    // Start the remote stream cancellation before releasing the relay slot.
    // The emitter is best-effort and asynchronous, but starts its own send
    // synchronously; releasing the slot immediately after lets that send pass
    // through a shared per-agent gate instead of racing a replacement query.
    streamingSqlCancelHandler?.call(streams);
    for (final cancelLocal in localCancellations) {
      cancelLocal();
    }
    relayCancelHandler?.call(relayIds);
    socketRpcCancelHandler?.call(socketIds);
    for (final cancelRequest in restCancellations) {
      cancelRequest();
    }
  }

  bool get isCancelled => _cancelled;

  static String _streamingKey(AgentStreamingSqlCancelTarget target) =>
      '${target.agentId}|${target.streamId}';

  static void _noop() {}
}

/// Binds [AgentQueriesCancelScope] to relay transport (DI / presentation edge).
typedef AgentQueriesRelayCancelScopeBinder = void Function(
  AgentQueriesCancelScope scope,
);
