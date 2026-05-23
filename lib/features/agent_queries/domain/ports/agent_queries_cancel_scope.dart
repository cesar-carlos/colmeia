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
    final relayIds = List<String>.of(
      _pendingRelayClientRequestIds,
      growable: false,
    );
    final socketIds = List<String>.of(_pendingSocketRpcIds, growable: false);
    _pendingRelayClientRequestIds.clear();
    _pendingSocketRpcIds.clear();
    final streams = List<AgentStreamingSqlCancelTarget>.of(
      _streamingCancelTargets,
      growable: false,
    );
    _streamingCancelTargets.clear();
    _pendingStreamingKeys.clear();
    relayCancelHandler?.call(relayIds);
    socketRpcCancelHandler?.call(socketIds);
    streamingSqlCancelHandler?.call(streams);
  }

  bool get isCancelled => _cancelled;
}

/// Binds [AgentQueriesCancelScope] to relay transport (DI / presentation edge).
typedef AgentQueriesRelayCancelScopeBinder = void Function(
  AgentQueriesCancelScope scope,
);
