import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/relay/relay_conversation_end_reasons.dart';
import 'package:colmeia/core/socket/relay/relay_conversation_ended_router.dart';
import 'package:colmeia/core/socket/relay/relay_conversation_state.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:colmeia/core/socket/socket_wire_utils.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:uuid/uuid.dart';

/// One conversation against one agent, isolated by `conversationId`. A
/// conversation is the unit of correlation in the relay protocol — every
/// `relay:rpc.request` must reference an open conversation, and every
/// `relay:rpc.chunk` / `complete` flows back through the same id.
///
/// The manager (one level up) owns the lifecycle and decides when to start
/// new conversations. Tests can drive a conversation directly by passing a
/// pre-connected `ConsumerSocketConnection` mock.
///
/// Single conversation is single-flight on `start()` to ensure we never emit
/// two `relay:conversation.start` events on top of each other (the hub would
/// happily open both, but ownership tracking would split).
class RelayConversation {
  RelayConversation({
    required this._connection,
    required this._agentId,
    this._startTimeout = const Duration(seconds: 10),
    this._endTimeout = const Duration(seconds: 5),
    this._uuid = const Uuid(),
    this._conversationEndedRouter,
  });

  final ConsumerSocketConnection _connection;
  final String _agentId;
  final Duration _startTimeout;
  final Duration _endTimeout;
  final Uuid _uuid;
  final RelayConversationEndedRouter? _conversationEndedRouter;

  RelayConversationState _state = const RelayConversationIdle();
  Future<RelayConversationActive>? _inFlightStart;
  Future<void>? _inFlightEnd;
  Completer<void>? _endAckCompleter;
  Completer<RelayConversationActive>? _startAckCompleter;
  io.Socket? _startedSocket;
  io.Socket? _endedSocket;
  int _generation = 0;

  void Function(Object?)? _conversationStartedHandler;
  void Function(Object?)? _conversationEndedHandler;
  ConversationEndedCallback? _routerEndedCallback;

  String get agentId => _agentId;
  RelayConversationState get state => _state;

  bool get isActive => _state is RelayConversationActive;

  String? get conversationId => switch (_state) {
    RelayConversationActive(:final conversationId) => conversationId,
    RelayConversationEnding(:final conversationId) => conversationId,
    RelayConversationEnded(:final conversationId) => conversationId,
    _ => null,
  };

  /// Idempotent + single-flight. Returns the active state, opening the
  /// conversation if needed. Throws [RelayConversationStartFailure] when the
  /// hub answers with `success: false` or the timeout elapses.
  Future<RelayConversationActive> start() {
    final state = _state;
    if (state is RelayConversationActive) {
      return Future<RelayConversationActive>.value(state);
    }
    final inFlight = _inFlightStart;
    if (inFlight != null) {
      return inFlight;
    }
    late final Future<RelayConversationActive> operation;
    operation = _startInternal().whenComplete(() {
      if (identical(_inFlightStart, operation)) {
        _inFlightStart = null;
      }
    });
    _inFlightStart = operation;
    return operation;
  }

  Future<RelayConversationActive> _startInternal() async {
    final generation = _generation;
    _setState(RelayConversationStarting(agentId: _agentId));

    final startRequestId = _uuid.v4();
    final completer = Completer<RelayConversationActive>();
    _startAckCompleter = completer;
    void onStarted(Object? raw) {
      if (completer.isCompleted) {
        return;
      }
      final map = _toMap(raw);
      if (map == null) {
        completer.completeError(
          const RelayConversationStartFailure(
            message: 'relay:conversation.started arrived without a map body',
            code: 'malformed_started',
          ),
        );
        return;
      }
      final echoedRequestId = map['requestId']?.toString();
      if (echoedRequestId != null &&
          echoedRequestId.isNotEmpty &&
          echoedRequestId != startRequestId) {
        // Hub echo for a different start; ignore.
        return;
      }
      final agentInPayload = map['agentId']?.toString();
      if (agentInPayload != null && agentInPayload != _agentId) {
        // Other conversation; ignore (our manager keeps one per agent).
        return;
      }
      final success = map['success'];
      if (success is bool && !success) {
        final error = _toMap(map['error']);
        final code = error?['code']?.toString() ?? 'conversation_rejected';
        final message =
            error?['message']?.toString() ??
            'relay:conversation.start was rejected by the hub';
        completer.completeError(
          RelayConversationStartFailure(message: message, code: code),
        );
        return;
      }
      final conversationId = map['conversationId']?.toString();
      if (conversationId == null || conversationId.isEmpty) {
        completer.completeError(
          const RelayConversationStartFailure(
            message:
                'relay:conversation.started missing conversationId for '
                'success path',
            code: 'missing_conversation_id',
          ),
        );
        return;
      }
      completer.complete(
        RelayConversationActive(
          agentId: _agentId,
          conversationId: conversationId,
          openedAt: DateTime.now().toUtc(),
        ),
      );
    }

    _conversationStartedHandler = onStarted;
    try {
      final socket = _connection.raw;
      _startedSocket = socket;
      socket
        ..on(RelayEventNames.conversationStarted, onStarted)
        ..emit(
          RelayEventNames.conversationStart,
          <String, Object?>{
            'requestId': startRequestId,
            'agentId': _agentId,
          },
        );
    } on Object catch (e, s) {
      _detachConversationStartedListener();
      _setState(
        RelayConversationEnded(agentId: _agentId, reason: 'emit_failed'),
      );
      throw RelayConversationStartFailure(
        message: 'failed to emit relay:conversation.start: $e',
        code: 'emit_failed',
        cause: e,
        stackTrace: s,
      );
    }

    final RelayConversationActive active;
    try {
      active = await completer.future.timeout(_startTimeout);
    } on TimeoutException catch (e, s) {
      _detachConversationStartedListener();
      _setState(
        RelayConversationEnded(agentId: _agentId, reason: 'start_timeout'),
      );
      throw RelayConversationStartFailure(
        message: 'relay:conversation.started not received in $_startTimeout',
        code: 'start_timeout',
        cause: e,
        stackTrace: s,
      );
    } on RelayConversationStartFailure {
      if (generation != _generation) rethrow;
      _detachConversationStartedListener();
      _setState(
        RelayConversationEnded(agentId: _agentId, reason: 'rejected'),
      );
      rethrow;
    } on Object catch (e, s) {
      _detachConversationStartedListener();
      _setState(
        RelayConversationEnded(agentId: _agentId, reason: 'start_error'),
      );
      throw RelayConversationStartFailure(
        message: 'unexpected error while opening conversation: $e',
        code: 'start_error',
        cause: e,
        stackTrace: s,
      );
    }

    if (generation != _generation) {
      throw const RelayConversationStartFailure(
        message: 'Relay conversation start was cancelled',
        code: 'obtain_superseded',
      );
    }
    _detachConversationStartedListener();
    _setState(active);
    AppLogger.debug(
      'Relay conversation opened',
      context: <String, Object?>{
        'component': 'RelayConversation',
        'agentId': _agentId,
        'conversationId': active.conversationId,
      },
    );
    return active;
  }

  /// Closes the conversation; idempotent and single-flight. Errors during
  /// `relay:conversation.ended` are swallowed — the local state always moves
  /// to [RelayConversationEnded] so callers can rely on `isActive == false`.
  Future<void> end({String? reason}) {
    final state = _state;
    if (state is RelayConversationIdle || state is RelayConversationEnded) {
      return Future<void>.value();
    }
    final inFlight = _inFlightEnd;
    if (inFlight != null) {
      return inFlight;
    }
    late final Future<void> operation;
    operation = _endInternal(reason: reason).whenComplete(() {
      if (identical(_inFlightEnd, operation)) {
        _inFlightEnd = null;
      }
    });
    _inFlightEnd = operation;
    return operation;
  }

  Future<void> _endInternal({String? reason}) async {
    final generation = _generation;
    final id = conversationId;
    if (id == null) {
      forceEnd(reason: reason ?? 'no_id');
      return;
    }
    _setState(
      RelayConversationEnding(agentId: _agentId, conversationId: id),
    );

    final endRequestId = _uuid.v4();
    String? hubEndedReason;
    final completer = Completer<void>();
    _endAckCompleter = completer;

    void completeAck({String? hubReason}) {
      if (completer.isCompleted) {
        return;
      }
      hubEndedReason = hubReason;
      completer.complete();
    }

    try {
      final router = _conversationEndedRouter;
      if (router != null) {
        void onEnded({
          required String conversationId,
          String? requestId,
          String? reason,
        }) {
          if (conversationId != id) {
            return;
          }
          if (requestId != null &&
              requestId.isNotEmpty &&
              requestId != endRequestId) {
            return;
          }
          completeAck(hubReason: reason);
        }

        _routerEndedCallback = onEnded;
        router.addListener(onEnded);
      } else {
        void onEnded(Object? raw) {
          if (completer.isCompleted) {
            return;
          }
          final map = _toMap(raw);
          final endedId = map?['conversationId']?.toString();
          if (endedId != null && endedId != id) {
            return;
          }
          final echoedRequestId = map?['requestId']?.toString();
          if (echoedRequestId != null &&
              echoedRequestId.isNotEmpty &&
              echoedRequestId != endRequestId) {
            return;
          }
          completeAck(hubReason: map?['reason']?.toString());
        }

        _conversationEndedHandler = onEnded;
        final socket = _connection.raw;
        _endedSocket = socket;
        socket.on(RelayEventNames.conversationEnded, onEnded);
      }

      _connection.raw.emit(
        RelayEventNames.conversationEnd,
        <String, Object?>{
          'requestId': endRequestId,
          'conversationId': id,
        },
      );
    } on Object catch (e, stackTrace) {
      completeAck();
      AppLogger.warning(
        'failed to emit relay:conversation.end',
        context: <String, Object?>{
          'component': 'RelayConversation',
          'agentId': _agentId,
          'conversationId': id,
        },
        error: e,
        stackTrace: stackTrace,
      );
    }

    try {
      await completer.future.timeout(_endTimeout);
    } on TimeoutException {
      AppLogger.warning(
        'relay:conversation.ended not received before timeout',
        context: <String, Object?>{
          'component': 'RelayConversation',
          'agentId': _agentId,
          'conversationId': id,
          'timeoutMs': _endTimeout.inMilliseconds,
        },
      );
    } finally {
      if (generation == _generation) {
        _detachConversationEndedListener();
        _endAckCompleter = null;
        _setState(
          RelayConversationEnded(
            agentId: _agentId,
            conversationId: id,
            reason: RelayConversationEndReasons.resolve(
              hubReason: hubEndedReason,
              localReason: reason ?? 'closed',
            ),
          ),
        );
      }
    }
  }

  /// Marks the conversation as terminated due to an external event (socket
  /// disconnect, hub `conversation.ended`, app:error). No event is emitted
  /// to the hub.
  void forceEnd({String? reason}) {
    final id = conversationId;
    _generation += 1;
    final startAck = _startAckCompleter;
    if (startAck != null && !startAck.isCompleted) {
      startAck.completeError(
        const RelayConversationStartFailure(
          message: 'Relay conversation start was cancelled',
          code: 'obtain_superseded',
        ),
      );
    }
    _inFlightStart = null;
    _inFlightEnd = null;
    final endAck = _endAckCompleter;
    if (endAck != null && !endAck.isCompleted) {
      endAck.complete();
    }
    _endAckCompleter = null;
    _detachConversationStartedListener();
    _detachConversationEndedListener();
    _setState(
      RelayConversationEnded(
        agentId: _agentId,
        conversationId: id,
        reason: reason,
      ),
    );
  }

  void _detachConversationStartedListener() {
    final handler = _conversationStartedHandler;
    if (handler != null) {
      _startedSocket?.off(RelayEventNames.conversationStarted, handler);
      _conversationStartedHandler = null;
    }
    _startedSocket = null;
    _startAckCompleter = null;
  }

  void _detachConversationEndedListener() {
    final routerCallback = _routerEndedCallback;
    if (routerCallback != null) {
      _conversationEndedRouter?.removeListener(routerCallback);
      _routerEndedCallback = null;
    }
    final handler = _conversationEndedHandler;
    if (handler != null) {
      _endedSocket?.off(RelayEventNames.conversationEnded, handler);
      _conversationEndedHandler = null;
    }
    _endedSocket = null;
  }

  // Setters do not compose with the sealed-class state pattern as cleanly
  // as a private mutator named alongside the public state getter.
  // ignore: use_setters_to_change_properties
  void _setState(RelayConversationState next) {
    _state = next;
  }

  static Map<String, dynamic>? _toMap(Object? raw) =>
      socketToStringKeyedMap(raw);
}
