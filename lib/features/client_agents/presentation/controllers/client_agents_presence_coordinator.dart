import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/push_event_deduper.dart';
import 'package:colmeia/features/client_agents/application/services/agent_presence_poller.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/observe_agent_presence_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';

/// Surface the [ClientAgentsPresenceCoordinator] needs from its owner to apply
/// realtime presence to the in-memory approved-agents list and to read the
/// current session. Implemented by `ClientAgentsController`, which keeps
/// ownership of the canonical state while the coordinator owns the socket
/// subscriptions, hint timers and the visibility-gated REST poller.
abstract interface class ClientAgentsPresenceHost {
  bool get isDisposed;

  String? get currentUserId;

  PaginatedResult<ClientAgent>? get approvedAgentsSnapshot;

  /// Replaces the approved-agents page in place (used to flip a single
  /// agent's connection status from an `AgentPresenceHint`).
  void replaceApprovedAgents(PaginatedResult<ClientAgent> value);

  /// Merges freshly fetched agents into the in-memory approved list.
  void upsertApprovedAgentsInMemory(List<ClientAgent> agents);

  void notifyPresenceChanged();
}

/// Owns the realtime presence concern for the client-agents screen:
///
/// - subscribes to the push presence stream (catalog updates + hints);
/// - debounces hint confirmation via a per-agent REST refresh;
/// - gates the optional REST fallback poller by screen visibility AND socket
///   connectivity (poll only when visible and the socket is down).
///
/// All dependencies are optional: when the build does not opt into the socket
/// transport the use case / poller / connection are `null` and every method is
/// a no-op, preserving the legacy `Refresh`-only UX.
class ClientAgentsPresenceCoordinator {
  ClientAgentsPresenceCoordinator({
    required ClientAgentsPresenceHost host,
    required LoadClientAgentDetailUseCase loadClientAgentDetailUseCase,
    required Duration hintConfirmDelay,
    ObserveAgentPresenceUseCase? observeAgentPresenceUseCase,
    AgentPresencePoller? agentPresencePoller,
    ConsumerSocketConnection? consumerSocketConnection,
  }) : _host = host,
       _loadClientAgentDetailUseCase = loadClientAgentDetailUseCase,
       _hintConfirmDelay = hintConfirmDelay,
       _observeAgentPresenceUseCase = observeAgentPresenceUseCase,
       _agentPresencePoller = agentPresencePoller,
       _consumerSocketConnection = consumerSocketConnection;

  final ClientAgentsPresenceHost _host;
  final LoadClientAgentDetailUseCase _loadClientAgentDetailUseCase;
  final Duration _hintConfirmDelay;
  final ObserveAgentPresenceUseCase? _observeAgentPresenceUseCase;
  final AgentPresencePoller? _agentPresencePoller;
  final ConsumerSocketConnection? _consumerSocketConnection;

  StreamSubscription<AgentPresenceEvent>? _presenceSub;
  StreamSubscription<ConsumerSocketConnectionState>? _socketStateSub;

  final Map<String, _PresenceObservation> _lastPresenceObservedByAgentId =
      <String, _PresenceObservation>{};
  final Map<String, Timer> _hintConfirmTimers = <String, Timer>{};

  bool _isScreenVisible = false;
  bool _isSocketConnected = false;

  /// Subscribes to realtime presence. Idempotent and a no-op when the presence
  /// use case is not wired. Call after the first approved-agents load so the
  /// first hints/catalog events have a populated list to upsert into.
  void subscribe() {
    final useCase = _observeAgentPresenceUseCase;
    if (useCase == null) {
      return;
    }
    if (_presenceSub != null) {
      return;
    }
    _presenceSub = useCase().listen(
      _onPresence,
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.warning(
          'Agent presence stream error',
          context: const <String, Object?>{
            'component': 'ClientAgentsController',
            'operation': 'presence_stream',
          },
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
    _maybeSubscribeToSocketState();
  }

  void _maybeSubscribeToSocketState() {
    final connection = _consumerSocketConnection;
    if (connection == null) {
      return;
    }
    if (_socketStateSub != null) {
      return;
    }
    // Seed with the current state so the first visibility transition
    // does not race against the first state event.
    _isSocketConnected = connection.isConnected;
    _socketStateSub = connection.states().listen((state) {
      if (_host.isDisposed) {
        return;
      }
      _isSocketConnected = state is ConsumerSocketConnected;
      _reconcilePollerGate();
    });
  }

  /// Reconciles the REST poller (Camada 3) with the current socket
  /// state and screen visibility. The contract is: poll **only** when
  /// the screen is visible AND the socket is NOT connected. As soon
  /// as the socket comes back, push events take over and the poller
  /// stops to avoid double-counting.
  void _reconcilePollerGate() {
    final poller = _agentPresencePoller;
    if (poller == null) {
      return;
    }
    final userId = _host.currentUserId;
    if (userId == null || userId.isEmpty) {
      poller.stop();
      return;
    }
    final shouldPoll = _isScreenVisible && !_isSocketConnected;
    if (shouldPoll) {
      poller.start(userId: userId);
    } else {
      poller.stop();
    }
  }

  /// Page-level hook (RouteAware): the `client_agents` screen visibility
  /// changed. Only effective when the poller + connection were wired —
  /// no-op otherwise so the legacy build behaves identically.
  void setScreenVisible({required bool isVisible}) {
    _isScreenVisible = isVisible;
    _reconcilePollerGate();
  }

  void _onPresence(AgentPresenceEvent event) {
    if (_host.isDisposed) {
      return;
    }
    final last = _lastPresenceObservedByAgentId[event.agentId];
    if (!_shouldAcceptPresenceEvent(event: event, last: last)) {
      AppLogger.debug(
        'Discarded stale presence event',
        context: <String, Object?>{
          'component': 'ClientAgentsController',
          'operation': 'presence_dedup',
          'agentId': event.agentId,
        },
      );
      return;
    }
    _lastPresenceObservedByAgentId[event.agentId] = _PresenceObservation(
      observedAt: event.observedAt,
      profileVersion: switch (event) {
        AgentPresenceCatalogUpdated(:final profileVersion) => profileVersion,
        AgentPresenceHint() => last?.profileVersion,
      },
    );

    final userId = _host.currentUserId;
    if (userId == null || userId.isEmpty) {
      return;
    }

    switch (event) {
      case AgentPresenceCatalogUpdated():
        unawaited(
          _refreshAgentDetailFromPresence(
            userId: userId,
            agentId: event.agentId,
          ),
        );
      case AgentPresenceHint():
        _applyHintInMemory(
          agentId: event.agentId,
          online: event.online,
        );
        _scheduleHintConfirm(userId: userId, agentId: event.agentId);
    }
  }

  bool _shouldAcceptPresenceEvent({
    required AgentPresenceEvent event,
    required _PresenceObservation? last,
  }) {
    if (last == null) {
      return true;
    }
    if (event case AgentPresenceCatalogUpdated(:final profileVersion?)) {
      final lastVersion = last.profileVersion;
      if (lastVersion != null) {
        if (profileVersion > lastVersion) {
          return true;
        }
        if (profileVersion < lastVersion) {
          return false;
        }
      }
    }
    return PushEventDeduper.isObservationAfter(
      candidate: event.observedAt,
      lastObservedAt: last.observedAt,
    );
  }

  Future<void> _refreshAgentDetailFromPresence({
    required String userId,
    required String agentId,
  }) async {
    final result = await _loadClientAgentDetailUseCase(
      userId: userId,
      agentId: agentId,
    );
    if (_host.isDisposed) {
      return;
    }
    result.fold(
      (agent) {
        _host
          ..upsertApprovedAgentsInMemory(<ClientAgent>[agent])
          ..notifyPresenceChanged();
      },
      (failure) {
        AppLogger.warning(
          'Refresh after presence event failed',
          context: <String, Object?>{
            'component': 'ClientAgentsController',
            'operation': 'refreshAfterPresence',
            'agentId': agentId,
            'technicalMessage': failure.message,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
      },
    );
  }

  void _applyHintInMemory({
    required String agentId,
    required bool online,
  }) {
    final current = _host.approvedAgentsSnapshot;
    if (current == null) {
      // No approved list yet — the next refresh will reconcile presence
      // with the server. Hints are a UI optimisation, not the truth.
      return;
    }
    var changed = false;
    final updatedItems = current.items
        .map((agent) {
          if (agent.agentId != agentId) {
            return agent;
          }
          final desired = online
              ? AgentConnectionStatus.online
              : AgentConnectionStatus.offline;
          if (agent.connectionStatus == desired) {
            return agent;
          }
          changed = true;
          return agent.copyWith(connectionStatus: desired);
        })
        .toList(growable: false);
    if (!changed) {
      return;
    }
    _host
      ..replaceApprovedAgents(
        PaginatedResult<ClientAgent>(
          items: updatedItems,
          count: current.count,
          total: current.total,
          page: current.page,
          pageSize: current.pageSize,
        ),
      )
      ..notifyPresenceChanged();
  }

  void _scheduleHintConfirm({
    required String userId,
    required String agentId,
  }) {
    _hintConfirmTimers[agentId]?.cancel();
    _hintConfirmTimers[agentId] = Timer(_hintConfirmDelay, () {
      _hintConfirmTimers.remove(agentId);
      if (_host.isDisposed) {
        return;
      }
      unawaited(
        _refreshAgentDetailFromPresence(
          userId: userId,
          agentId: agentId,
        ),
      );
    });
  }

  void dispose() {
    for (final timer in _hintConfirmTimers.values) {
      timer.cancel();
    }
    _hintConfirmTimers.clear();
    unawaited(_presenceSub?.cancel());
    _presenceSub = null;
    unawaited(_socketStateSub?.cancel());
    _socketStateSub = null;
    _agentPresencePoller?.stop();
    _lastPresenceObservedByAgentId.clear();
  }
}

class _PresenceObservation {
  const _PresenceObservation({
    required this.observedAt,
    required this.profileVersion,
  });

  final DateTime observedAt;
  final int? profileVersion;
}
