import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:colmeia/core/socket/payload_frame_codec.dart';
import 'package:colmeia/core/socket/push_event_deduper.dart';
import 'package:colmeia/core/socket/socket_wire_utils.dart';
import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';

/// Edge adapter: subscribes the raw socket to `client:agent.profile.updated`
/// (PayloadFrame envelope, available since Phase 2 of the hub) and emits
/// domain-level `AgentPresenceCatalogUpdated` events into the configured
/// `Sink<AgentPresenceEvent>`.
///
/// SRP: this class only **transforms** the wire payload into a domain
/// event via `PayloadFrameCodec`. It never decides what to do with the
/// event — that lives in `ClientAgentsController`. Failures (malformed
/// envelope, unknown agent_id) are logged and dropped silently to avoid
/// killing the presence stream over a single bad frame.
///
/// Lifecycle:
///
/// - `attach()` — idempotent; safe to call after `connection.connect()`
///   has succeeded. Re-attach after a manual `dispose()` is supported.
/// - `dispose()` — idempotent; releases the socket listener.
class ClientAgentProfileUpdatedListener {
  ClientAgentProfileUpdatedListener({
    required this._connection,
    required this._sink,
    PayloadFrameCodec? codec,
    this._acceptLegacyRawJson = false,
  }) : _codec = codec ?? const PayloadFrameCodec() {
    _eventHandler = _onEvent;
  }

  /// Wire event name from `plug_server/docs/socket_client_sdk.md`.
  static const String eventName = 'client:agent.profile.updated';

  final ConsumerSocketConnection _connection;
  final Sink<AgentPresenceEvent> _sink;
  final bool _acceptLegacyRawJson;
  final PayloadFrameCodec _codec;
  final PushEventDeduper _observedAtDeduper = PushEventDeduper();
  late final void Function(Object?) _eventHandler;

  bool _attached = false;

  bool get isAttached => _attached;

  /// Anexa o handler ao socket cru. Idempotente — chamadas duplicadas
  /// são no-op.
  void attach() {
    if (_attached) {
      return;
    }
    try {
      _connection.raw.on(eventName, _eventHandler);
      _attached = true;
    }
    // ConsumerSocketConnection.raw throws StateError when not yet
    // connected; surface as a warning so the caller knows to retry
    // after the next connection:ready.
    // ignore: avoid_catching_errors
    on StateError catch (error, stackTrace) {
      AppLogger.warning(
        '$eventName attach skipped: connection not ready',
        context: const <String, Object?>{
          'component': 'ClientAgentProfileUpdatedListener',
          'operation': 'attach',
        },
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Remove o handler do socket. Idempotente.
  Future<void> dispose() async {
    if (!_attached) {
      return;
    }
    _attached = false;
    try {
      _connection.raw.off(eventName, _eventHandler);
    }
    // The connection may already be torn down (logout / app dispose).
    // ignore: avoid_catching_errors
    on StateError catch (_) {
      // Nothing else to do.
    }
  }

  void _onEvent(Object? raw) {
    unawaited(_onEventAsync(raw));
  }

  Future<void> _onEventAsync(Object? raw) async {
    try {
      final logical = await _decodeLogical(raw);
      if (logical == null) {
        return;
      }
      final agentId = logical['agent_id']?.toString().trim();
      if (agentId == null || agentId.isEmpty) {
        AppLogger.debug(
          '$eventName ignored: missing agent_id',
          context: const <String, Object?>{
            'component': 'ClientAgentProfileUpdatedListener',
          },
        );
        return;
      }
      final observedAt = _parseObservedAt(logical);
      if (!_observedAtDeduper.shouldAccept(
        key: agentId,
        observedAt: observedAt,
      )) {
        AppLogger.debug(
          '$eventName ignored: stale observedAt after reconnect',
          context: <String, Object?>{
            'component': 'ClientAgentProfileUpdatedListener',
            'agentId': agentId,
          },
        );
        return;
      }
      _sink.add(
        AgentPresenceCatalogUpdated(
          agentId: agentId,
          observedAt: observedAt,
          changedFields: _parseChangedFields(logical),
          profileVersion: _asInt(logical['profile_version']),
          source: logical['source']?.toString(),
        ),
      );
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        '$eventName decode failed',
        context: const <String, Object?>{
          'component': 'ClientAgentProfileUpdatedListener',
          'operation': 'decode_failed',
        },
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// The hub serializes this event as PayloadFrame since Phase 2 (see
  /// `socket_client_sdk.md`). PayloadFrame is the default contract. Raw JSON
  /// map remains available only when `acceptLegacyRawJson` is explicitly
  /// enabled for older hub builds.
  ///
  /// 1. PayloadFrame envelope (current hub) - decoded via [PayloadFrameCodec].
  /// 2. Raw JSON map (older hub builds) - used as-is only in legacy mode.
  /// 3. Anything else - returns `null` (caller logs + drops).
  Future<Map<String, Object?>?> _decodeLogical(Object? raw) async {
    switch (PayloadFrame.parseDetailed(raw)) {
      case PayloadFrameParseSuccess(:final frame):
        try {
          final decoded = await _codec.decodeJsonAsync(frame);
          return socketToStringKeyedMap(decoded);
        } on PayloadFrameDecodeException catch (error, stackTrace) {
          AppLogger.warning(
            '$eventName payload frame rejected by codec',
            context: <String, Object?>{
              'component': 'ClientAgentProfileUpdatedListener',
              'operation': 'decode_failed',
              'code': error.code,
            },
            error: error,
            stackTrace: stackTrace,
          );
          return null;
        }
      case final PayloadFrameParseFailure failure:
        if (_looksLikePayloadFrame(raw)) {
          AppLogger.warning(
            '$eventName payload frame parse failed',
            context: <String, Object?>{
              'component': 'ClientAgentProfileUpdatedListener',
              'operation': 'parse_failed',
              'code': failure.code,
              'message': failure.message,
            },
          );
          return null;
        }
    }
    if (!_acceptLegacyRawJson) {
      return null;
    }
    return socketToStringKeyedMap(raw);
  }

  bool _looksLikePayloadFrame(Object? raw) {
    if (raw is PayloadFrame || raw is List<int>) {
      return true;
    }
    if (raw is Map) {
      return raw.containsKey('schemaVersion') ||
          raw.containsKey('payload') ||
          raw.containsKey('cmp');
    }
    if (raw is String) {
      return raw.contains('"schemaVersion"') ||
          raw.contains('"payload"') ||
          raw.contains('"cmp"');
    }
    return false;
  }

  DateTime _parseObservedAt(Map<String, Object?> logical) {
    final raw =
        logical['profileUpdatedAt']?.toString() ??
        logical['profile_updated_at']?.toString() ??
        logical['observedAt']?.toString();
    if (raw == null) {
      return DateTime.now().toUtc();
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return DateTime.now().toUtc();
    }
    if (parsed.isUtc) {
      return parsed;
    }
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
  }

  Set<String> _parseChangedFields(Map<String, Object?> logical) {
    final raw = logical['changed_fields'];
    if (raw is List) {
      return <String>{
        for (final item in raw)
          if (item is String && item.isNotEmpty) item,
      };
    }
    return const <String>{};
  }

  int? _asInt(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw);
    }
    return null;
  }
}
