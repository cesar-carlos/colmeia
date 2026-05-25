import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/relay/relay_conversation_state.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:colmeia/core/socket/socket_wire_utils.dart';

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
    required ConsumerSocketConnection connection,
    required String agentId,
    Duration startTimeout = const Duration(seconds: 10),
    Duration endTimeout = const Duration(seconds: 5),
  }) : _connection = connection,
       _agentId = agentId,
       _startTimeout = startTimeout,
       _endTimeout = endTimeout;

  final ConsumerSocketConnection _connection;
  final String _agentId;
  final Duration _startTimeout;
  final Duration _endTimeout;

  RelayConversationState _state = const RelayConversationIdle();
  Future<RelayConversationActive>? _inFlightStart;
  Future<void>? _inFlightEnd;

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
    final operation = _startInternal().whenComplete(() {
      _inFlightStart = null;
    });
    _inFlightStart = operation;
    return operation;
  }

  Future<RelayConversationActive> _startInternal() async {
    _setState(RelayConversationStarting(agentId: _agentId));

    final completer = Completer<RelayConversationActive>();
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

    _connection.raw.on(RelayEventNames.conversationStarted, onStarted);
    try {
      _connection.raw.emit(
        RelayEventNames.conversationStart,
        <String, Object?>{'agentId': _agentId},
      );
    } on Object catch (e, s) {
      _connection.raw.off(RelayEventNames.conversationStarted, onStarted);
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
      _connection.raw.off(RelayEventNames.conversationStarted, onStarted);
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
      _connection.raw.off(RelayEventNames.conversationStarted, onStarted);
      _setState(
        RelayConversationEnded(agentId: _agentId, reason: 'rejected'),
      );
      rethrow;
    } on Object catch (e, s) {
      _connection.raw.off(RelayEventNames.conversationStarted, onStarted);
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

    _connection.raw.off(RelayEventNames.conversationStarted, onStarted);
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
    final operation = _endInternal(reason: reason).whenComplete(() {
      _inFlightEnd = null;
    });
    _inFlightEnd = operation;
    return operation;
  }

  Future<void> _endInternal({String? reason}) async {
    final id = conversationId;
    if (id == null) {
      _setState(
        RelayConversationEnded(agentId: _agentId, reason: reason ?? 'no_id'),
      );
      return;
    }
    _setState(
      RelayConversationEnding(agentId: _agentId, conversationId: id),
    );

    final completer = Completer<void>();
    void onEnded(Object? raw) {
      if (completer.isCompleted) {
        return;
      }
      final map = _toMap(raw);
      final endedId = map?['conversationId']?.toString();
      if (endedId != null && endedId != id) {
        // Different conversation; not ours.
        return;
      }
      completer.complete();
    }

    _connection.raw.on(RelayEventNames.conversationEnded, onEnded);
    try {
      _connection.raw.emit(
        RelayEventNames.conversationEnd,
        <String, Object?>{'conversationId': id},
      );
    } on Object catch (e) {
      AppLogger.warning(
        'failed to emit relay:conversation.end',
        context: <String, Object?>{
          'component': 'RelayConversation',
          'agentId': _agentId,
          'conversationId': id,
          'error': e.toString(),
        },
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
      _connection.raw.off(RelayEventNames.conversationEnded, onEnded);
      _setState(
        RelayConversationEnded(
          agentId: _agentId,
          conversationId: id,
          reason: reason ?? 'closed',
        ),
      );
    }
  }

  /// Marks the conversation as terminated due to an external event (socket
  /// disconnect, app:error). No event is emitted to the hub.
  void forceEnd({String? reason}) {
    final id = conversationId;
    _inFlightStart = null;
    _inFlightEnd = null;
    _setState(
      RelayConversationEnded(
        agentId: _agentId,
        conversationId: id,
        reason: reason,
      ),
    );
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
