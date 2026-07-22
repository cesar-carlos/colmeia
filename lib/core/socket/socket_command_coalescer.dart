import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';

/// Owns in-flight coalesce maps for `SocketCommandDispatcherImpl`.
///
/// Concurrent identical `agents:command` sends share one hub Future: the
/// first caller is the leader; later callers become followers with their
/// own client Completer so cancel can target a follower without aborting
/// the shared hub request.
class SocketCommandCoalescer {
  SocketCommandCoalescer({void Function()? onCoalesced})
    : _onCoalesced = onCoalesced;

  final void Function()? _onCoalesced;

  /// Maps coalesce key → in-flight hub Future.
  final Map<String, Future<Map<String, dynamic>>> _inflightByKey =
      <String, Future<Map<String, dynamic>>>{};

  /// Leader `rpcId` for each active coalesce key.
  final Map<String, String> _leaderRpcIdByKey = <String, String>{};

  /// Leader client-facing completer — cancel leader without failing hub.
  final Map<String, Completer<Map<String, dynamic>>>
  _leaderClientCompleterByRpcId = <String, Completer<Map<String, dynamic>>>{};

  /// Follower Completers keyed by follower `rpcId`.
  final Map<String, Completer<Map<String, dynamic>>> _awaiterByRpcId =
      <String, Completer<Map<String, dynamic>>>{};

  /// Follower `rpcId` → coalesce key.
  final Map<String, String> _awaiterKeyByRpcId = <String, String>{};

  /// When [key] already has an in-flight hub Future, registers [rpcId] as a
  /// follower and returns its client Future. Otherwise returns `null` so the
  /// caller can become the leader.
  Future<Map<String, dynamic>>? tryJoinAsFollower({
    required String key,
    required String rpcId,
    required String agentId,
    void Function(Completer<Map<String, dynamic>> completer)? onJoined,
  }) {
    final existing = _inflightByKey[key];
    if (existing == null) {
      return null;
    }
    _onCoalesced?.call();
    final leaderRpcId = _leaderRpcIdByKey[key];
    AppLogger.debug(
      'Coalesced agents:command into in-flight request',
      context: <String, Object?>{
        'component': 'SocketCommandCoalescer',
        'agentId': agentId,
        'followerRpcId': rpcId,
        'leaderRpcId': leaderRpcId,
      },
    );
    final followerCompleter = Completer<Map<String, dynamic>>();
    _awaiterByRpcId[rpcId] = followerCompleter;
    _awaiterKeyByRpcId[rpcId] = key;
    onJoined?.call(followerCompleter);
    unawaited(
      existing
          .then<void>(
            (value) {
              if (!followerCompleter.isCompleted) {
                followerCompleter.complete(value);
              }
            },
            onError: (Object error, StackTrace stack) {
              if (!followerCompleter.isCompleted) {
                followerCompleter.completeError(error, stack);
              }
            },
          )
          .whenComplete(() {
            _awaiterByRpcId.remove(rpcId);
            _awaiterKeyByRpcId.remove(rpcId);
          }),
    );
    return followerCompleter.future;
  }

  /// Registers [rpcId] as the leader for [key] backed by [hubFuture].
  /// Returns the client-facing Future (may diverge from hub on leader cancel).
  Future<Map<String, dynamic>> beginLead({
    required String key,
    required String rpcId,
    required Future<Map<String, dynamic>> hubFuture,
  }) {
    final leaderClient = Completer<Map<String, dynamic>>();
    _leaderClientCompleterByRpcId[rpcId] = leaderClient;
    final tracked = hubFuture.then(
      (value) {
        if (!leaderClient.isCompleted) {
          leaderClient.complete(value);
        }
        return value;
      },
      onError: (Object error, StackTrace stack) {
        if (!leaderClient.isCompleted) {
          leaderClient.completeError(error, stack);
        }
        return Future<Map<String, dynamic>>.error(error, stack);
      },
    );
    _inflightByKey[key] = tracked;
    _leaderRpcIdByKey[key] = rpcId;
    unawaited(_clearEntryWhenDone(key, tracked));
    return leaderClient.future;
  }

  Future<void> _clearEntryWhenDone(
    String key,
    Future<Map<String, dynamic>> future,
  ) async {
    try {
      await future;
    } on Object {
      // Callers still observe the original future; this only cleans maps.
    } finally {
      final current = _inflightByKey[key];
      if (identical(current, future)) {
        _inflightByKey.remove(key)?.ignore();
        final leaderRpcId = _leaderRpcIdByKey.remove(key);
        if (leaderRpcId != null) {
          _leaderClientCompleterByRpcId.remove(leaderRpcId);
        }
      }
    }
  }

  /// Removes a follower Completer if [rpcId] is a follower. Returns it so
  /// the dispatcher can complete with cancel / emit metrics.
  Completer<Map<String, dynamic>>? takeFollower(String rpcId) {
    final completer = _awaiterByRpcId.remove(rpcId);
    if (completer != null) {
      _awaiterKeyByRpcId.remove(rpcId);
    }
    return completer;
  }

  String? leaderKeyForRpcId(String rpcId) {
    for (final entry in _leaderRpcIdByKey.entries) {
      if (entry.value == rpcId) {
        return entry.key;
      }
    }
    return null;
  }

  bool hasFollowersForKey(String key) {
    return _awaiterKeyByRpcId.values.any((awaiterKey) => awaiterKey == key);
  }

  Completer<Map<String, dynamic>>? takeLeaderClientCompleter(String rpcId) {
    return _leaderClientCompleterByRpcId.remove(rpcId);
  }

  /// Drops in-flight keys and fails follower Completers (socket drop).
  void failFollowersAndClearInflight(Object error) {
    _inflightByKey.clear();
    _leaderRpcIdByKey.clear();
    for (final c in _awaiterByRpcId.values) {
      if (!c.isCompleted) {
        c.completeError(error);
      }
    }
    _awaiterByRpcId.clear();
    _awaiterKeyByRpcId.clear();
    _leaderClientCompleterByRpcId.clear();
  }

  /// Fails remaining follower Completers on dispatcher dispose.
  void dispose({
    Object error = const SocketDispatchDisconnected(
      message: 'Dispatcher disposed',
    ),
  }) {
    for (final c in _awaiterByRpcId.values) {
      if (!c.isCompleted) {
        c.completeError(error);
      }
    }
    _awaiterByRpcId.clear();
    _awaiterKeyByRpcId.clear();
    _leaderClientCompleterByRpcId.clear();
    _inflightByKey.clear();
    _leaderRpcIdByKey.clear();
  }
}
