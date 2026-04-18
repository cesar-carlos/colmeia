import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:colmeia/core/socket/payload_frame_codec.dart';
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
    required ConsumerSocketConnection connection,
    required Sink<AgentPresenceEvent> sink,
    PayloadFrameCodec? codec,
  }) : _connection = connection,
       _sink = sink,
       _codec = codec ?? const PayloadFrameCodec();

  /// Wire event name from `plug_server/docs/socket_client_sdk.md`.
  static const String eventName = 'client:agent.profile.updated';

  final ConsumerSocketConnection _connection;
  final Sink<AgentPresenceEvent> _sink;
  final PayloadFrameCodec _codec;

  bool _attached = false;

  bool get isAttached => _attached;

  /// Anexa o handler ao socket cru. Idempotente — chamadas duplicadas
  /// são no-op.
  void attach() {
    if (_attached) {
      return;
    }
    try {
      _connection.raw.on(eventName, _onEvent);
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
      // Single-arg off() clears every handler for this event. Safe
      // because the listener is the sole consumer of
      // `client:agent.profile.updated` in the app.
      _connection.raw.off(eventName);
    }
    // The connection may already be torn down (logout / app dispose).
    // ignore: avoid_catching_errors
    on StateError catch (_) {
      // Nothing else to do.
    }
  }

  void _onEvent(Object? raw) {
    try {
      final logical = _decodeLogical(raw);
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
      _sink.add(
        AgentPresenceCatalogUpdated(
          agentId: agentId,
          observedAt: _parseObservedAt(logical),
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
  /// `socket_client_sdk.md`). We accept three shapes for forward/backward
  /// compatibility:
  ///
  /// 1. PayloadFrame envelope (post-2026 hub) — decoded via
  ///    [PayloadFrameCodec].
  /// 2. Raw JSON map (older hub builds) — used as-is.
  /// 3. Anything else — returns `null` (caller logs + drops).
  Map<String, Object?>? _decodeLogical(Object? raw) {
    final frame = PayloadFrame.tryParse(raw);
    if (frame != null) {
      try {
        final decoded = _codec.decodeJson(frame);
        if (decoded is Map) {
          return decoded.map(
            (key, value) =>
                MapEntry<String, Object?>(key.toString(), value),
          );
        }
        return null;
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
    }
    if (raw is Map<String, Object?>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry<String, Object?>(key.toString(), value),
      );
    }
    return null;
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
    return (parsed ?? DateTime.now()).toUtc();
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
