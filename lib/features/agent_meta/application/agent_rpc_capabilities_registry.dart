import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_meta/application/usecases/discover_agent_rpc_methods_use_case.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_rpc_descriptor.dart';
import 'package:flutter/foundation.dart';

/// In-memory cache of `rpc.discover` results indexed by agent id.
///
/// The overview boot pre-fetches a descriptor for every approved agent so
/// other surfaces (overview cards, agent detail, query banners) can gate
/// features in O(1) without paying a network round-trip per render.
///
/// The registry is intentionally fire-and-forget — failures are logged
/// at `info` and the affected agent stays absent from the cache. Callers
/// MUST treat a missing entry as "capabilities unknown" (same UX as if
/// the call had not been made yet) rather than as "no support". This
/// keeps us forward-compatible with agents that disable the meta RPCs
/// or with hubs that briefly mask them under load.
///
/// Thread-safety: every method runs on the same isolate (Flutter UI),
/// but concurrent prefetches are deduplicated through a per-agent
/// in-flight `Future` so multiple callers waiting on the same agent get
/// exactly one network call.
class AgentRpcCapabilitiesRegistry extends ChangeNotifier {
  AgentRpcCapabilitiesRegistry({
    required DiscoverAgentRpcMethodsUseCase discoverAgentRpcMethodsUseCase,
  }) : _discover = discoverAgentRpcMethodsUseCase;

  final DiscoverAgentRpcMethodsUseCase _discover;

  final Map<String, AgentRpcDescriptor> _byAgentId =
      <String, AgentRpcDescriptor>{};
  final Map<String, Future<AgentRpcDescriptor?>> _inFlight =
      <String, Future<AgentRpcDescriptor?>>{};
  bool _disposed = false;

  /// Returns the cached descriptor for [agentId], or `null` when
  /// nothing has been fetched yet or the last fetch failed.
  AgentRpcDescriptor? descriptorFor(String agentId) {
    final id = _normalize(agentId);
    if (id == null) {
      return null;
    }
    return _byAgentId[id];
  }

  /// Convenience helper for the common case ("does this agent expose
  /// this RPC?"). Returns `null` when capabilities are unknown so
  /// callers can choose between optimistic ("show the action and let
  /// the bridge reject it") and pessimistic ("hide until we know")
  /// strategies.
  bool? supports({required String agentId, required String method}) {
    final descriptor = descriptorFor(agentId);
    if (descriptor == null) {
      return null;
    }
    return descriptor.supportsMethod(method);
  }

  /// Returns the count of agents we currently have a descriptor for.
  /// Mostly useful for logging/diagnostics.
  int get cachedAgentCount => _byAgentId.length;

  /// Replaces the cached descriptor for [agentId] (e.g. after the
  /// detail page calls `rpc.discover` itself and wants to share the
  /// result). Notifies listeners only when the entry actually changes.
  void put(String agentId, AgentRpcDescriptor descriptor) {
    final id = _normalize(agentId);
    if (id == null || _disposed) {
      return;
    }
    final previous = _byAgentId[id];
    if (identical(previous, descriptor)) {
      return;
    }
    _byAgentId[id] = descriptor;
    notifyListeners();
  }

  /// Drops cached descriptors for [agentIds]. Useful when the user
  /// removes access to an agent — keeps the cache from leaking stale
  /// capabilities indefinitely.
  void invalidate(Iterable<String> agentIds) {
    if (_disposed) {
      return;
    }
    var removed = false;
    for (final raw in agentIds) {
      final id = _normalize(raw);
      if (id == null) continue;
      if (_byAgentId.remove(id) != null) {
        removed = true;
      }
    }
    if (removed) {
      notifyListeners();
    }
  }

  /// Clears every cached descriptor. Hooked to logout / session change.
  void clear() {
    if (_disposed || _byAgentId.isEmpty) {
      return;
    }
    _byAgentId.clear();
    notifyListeners();
  }

  /// Pre-fetches descriptors for every id in [agentIds] that does not
  /// yet have one cached. Returns a [Future] that completes once every
  /// requested fetch settles — resilient to per-agent failures (they
  /// are logged and the loop continues).
  ///
  /// Safe to call repeatedly; ids that already have a descriptor or
  /// an in-flight request are skipped.
  Future<void> prefetch(Iterable<String> agentIds) async {
    if (_disposed) {
      return;
    }
    final unique = <String>{};
    for (final raw in agentIds) {
      final id = _normalize(raw);
      if (id == null) continue;
      if (_byAgentId.containsKey(id)) continue;
      unique.add(id);
    }
    if (unique.isEmpty) {
      return;
    }
    AppLogger.debug(
      'Prefetching agent RPC capabilities',
      context: <String, Object?>{
        'operation': 'prefetchAgentRpcCapabilities',
        'agentCount': unique.length,
      },
    );
    await Future.wait(<Future<void>>[
      for (final id in unique) _fetchOne(id).then((_) {}),
    ]);
  }

  /// Same as [prefetch] but for a single id, returning the descriptor
  /// (or `null` on failure). Reuses any in-flight request so concurrent
  /// callers share the same network round-trip.
  Future<AgentRpcDescriptor?> ensure(String agentId) {
    final id = _normalize(agentId);
    if (id == null) {
      return Future<AgentRpcDescriptor?>.value();
    }
    final cached = _byAgentId[id];
    if (cached != null) {
      return Future<AgentRpcDescriptor?>.value(cached);
    }
    return _fetchOne(id);
  }

  Future<AgentRpcDescriptor?> _fetchOne(String agentId) {
    final pending = _inFlight[agentId];
    if (pending != null) {
      return pending;
    }
    // Chain `whenComplete` into the same future we expose so concurrent
    // callers share both the result AND the cleanup. The cleanup uses
    // `unawaited` because `Map.remove` returns the erased entry (the
    // future itself), which would otherwise trip the
    // `discarded_futures` lint.
    final future = _doFetch(agentId).whenComplete(() {
      final removed = _inFlight.remove(agentId);
      if (removed != null) {
        unawaited(removed);
      }
    });
    _inFlight[agentId] = future;
    return future;
  }

  Future<AgentRpcDescriptor?> _doFetch(String agentId) async {
    try {
      final result = await _discover(agentId: agentId);
      if (_disposed) {
        return null;
      }
      final descriptor = result.getOrNull();
      if (descriptor != null) {
        _byAgentId[agentId] = descriptor;
        notifyListeners();
        return descriptor;
      }
      final failure = result.exceptionOrNull();
      // Discovery is best-effort — log at info so it does not pollute
      // crash reporters with expected "agent on older firmware" cases.
      AppLogger.info(
        'Agent rpc.discover failed during capability prefetch',
        context: <String, Object?>{
          'operation': 'prefetchAgentRpcCapabilities',
          'agentId': agentId,
          'failureType': failure?.runtimeType.toString(),
          'message': failure?.message,
        },
      );
      return null;
    } on Object catch (error, stackTrace) {
      // Catch-all here is intentional — the registry is a best-effort
      // capability cache and MUST NOT propagate exceptions back into
      // the overview's load path. Anything unusual is logged so the
      // failure is still visible in monitoring.
      AppLogger.warning(
        'Unexpected error while prefetching agent rpc capabilities',
        context: <String, Object?>{
          'operation': 'prefetchAgentRpcCapabilities',
          'agentId': agentId,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  String? _normalize(String agentId) {
    final trimmed = agentId.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  @override
  void dispose() {
    _disposed = true;
    _byAgentId.clear();
    _inFlight.clear();
    super.dispose();
  }
}
