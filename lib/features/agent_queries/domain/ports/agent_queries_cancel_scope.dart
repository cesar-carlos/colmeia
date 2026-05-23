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
  final Set<String> _pendingClientRequestIds = <String>{};
  final Set<String> _pendingStreamingKeys = <String>{};
  final List<AgentStreamingSqlCancelTarget> _streamingCancelTargets =
      <AgentStreamingSqlCancelTarget>[];

  /// Fail-fast pending relay RPCs ([RelayCommandDispatcher.cancel]).
  void Function(Iterable<String> clientRequestIds)? relayCancelHandler;

  /// Fail-fast pending `agents:command` RPCs ([SocketCommandDispatcher.cancel]).
  void Function(Iterable<String> rpcIds)? socketRpcCancelHandler;

  /// Best-effort hub `sql.cancel` for open streams.
  void Function(Iterable<AgentStreamingSqlCancelTarget> targets)?
  streamingSqlCancelHandler;

  void trackPending(String clientRequestId) {
    if (_cancelled) {
      return;
    }
    _pendingClientRequestIds.add(clientRequestId);
  }

  void untrackPending(String clientRequestId) {
    _pendingClientRequestIds.remove(clientRequestId);
  }

  /// Registers a hub stream id once known (first relay chunk).
  void trackStreamingSql(AgentStreamingSqlCancelTarget target) {
    if (_cancelled) {
      return;
    }
    final key = '${target.agentId}|${target.streamId}';
    if (_pendingStreamingKeys.add(key)) {
      _streamingCancelTargets.add(target);
    }
  }

  void cancelAll() {
    if (_cancelled) {
      return;
    }
    _cancelled = true;
    final ids = List<String>.of(_pendingClientRequestIds, growable: false);
    _pendingClientRequestIds.clear();
    final streams = List<AgentStreamingSqlCancelTarget>.of(
      _streamingCancelTargets,
      growable: false,
    );
    _streamingCancelTargets.clear();
    _pendingStreamingKeys.clear();
    relayCancelHandler?.call(ids);
    socketRpcCancelHandler?.call(ids);
    streamingSqlCancelHandler?.call(streams);
  }

  bool get isCancelled => _cancelled;
}

/// Binds [AgentQueriesCancelScope] to relay transport (DI / presentation edge).
typedef AgentQueriesRelayCancelScopeBinder = void Function(
  AgentQueriesCancelScope scope,
);
