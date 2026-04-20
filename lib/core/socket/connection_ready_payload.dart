import 'dart:convert';

import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:colmeia/core/socket/payload_frame_codec.dart';

/// Logical payload carried by the `connection:ready` event after handshake.
///
/// Hub source (today): JSON object with `id`, `message`, `user`. Future:
/// `PayloadFrame` envelope (Phase 2). The decoder below tolerates both
/// shapes during the compatibility window — see
/// `docs/Features/consumer_socket_connection_design.md` §10.
class ConnectionReadyPayload {
  const ConnectionReadyPayload({
    required this.socketId,
    required this.message,
    required this.userClaims,
    this.hubInstanceId,
  });

  final String socketId;
  final String message;
  final Map<String, Object?> userClaims;
  final String? hubInstanceId;
}

/// Port: returns `null` when the input cannot be interpreted. Callers
/// treat `null` as a handshake failure (transient).
// PR-A keeps a single method; Phase 2 will add `decodeStrict()` when
// PayloadFrame becomes mandatory.
// ignore: one_member_abstracts
abstract interface class ConnectionReadyDecoder {
  ConnectionReadyPayload? decode(Object? raw);
}

/// Shared logic that turns a logical `connection:ready` map into a
/// [ConnectionReadyPayload]. Both the legacy raw-JSON decoder and the
/// PayloadFrame-aware decoder funnel into this builder.
ConnectionReadyPayload? _buildFromLogicalMap(Map<String, Object?> logical) {
  final id = logical['id']?.toString();
  if (id == null || id.isEmpty) {
    return null;
  }
  final user = logical['user'];
  return ConnectionReadyPayload(
    socketId: id,
    message: logical['message']?.toString() ?? '',
    userClaims: user is Map<String, Object?>
        ? user
        : (user is Map
              ? user.map(
                  (key, value) =>
                      MapEntry<String, Object?>(key.toString(), value),
                )
              : const <String, Object?>{}),
    hubInstanceId: logical['hub_instance_id']?.toString(),
  );
}

/// Decoder that accepts only the legacy raw JSON shape (no PayloadFrame
/// envelope). Useful in tests and as the strict mode controlled by
/// `SOCKET_CONNECTION_READY_COMPAT_MODE=raw_json_only`.
class JsonOnlyConnectionReadyDecoder implements ConnectionReadyDecoder {
  const JsonOnlyConnectionReadyDecoder();

  @override
  ConnectionReadyPayload? decode(Object? raw) {
    final logical = _toLogicalMap(raw);
    if (logical == null) {
      return null;
    }
    return _buildFromLogicalMap(logical);
  }

  Map<String, Object?>? _toLogicalMap(Object? raw) {
    if (raw is Map<String, Object?>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry<String, Object?>(key.toString(), value),
      );
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return decoded.map(
            (key, value) => MapEntry<String, Object?>(key.toString(), value),
          );
        }
      } on FormatException {
        return null;
      }
    }
    return null;
  }
}

/// PR-K: decoder that interprets `connection:ready` strictly as a
/// [PayloadFrame] envelope (the post-2026-09-30 contract). Unwraps the
/// inner JSON via [PayloadFrameCodec] and reuses the legacy field shape
/// (`id`, `message`, `user`).
class PayloadFrameConnectionReadyDecoder implements ConnectionReadyDecoder {
  PayloadFrameConnectionReadyDecoder({PayloadFrameCodec? codec})
    : _codec = codec ?? const PayloadFrameCodec();

  final PayloadFrameCodec _codec;

  @override
  ConnectionReadyPayload? decode(Object? raw) {
    final frame = PayloadFrame.tryParse(raw);
    if (frame == null) {
      return null;
    }
    Object? decoded;
    try {
      decoded = _codec.decodeJson(frame);
    } on PayloadFrameDecodeException {
      return null;
    }
    if (decoded is! Map) {
      return null;
    }
    final logical = decoded.map(
      (key, value) => MapEntry<String, Object?>(key.toString(), value),
    );
    return _buildFromLogicalMap(logical);
  }
}

/// PR-K: compatibility decoder used during the migration window.
///
/// Tries the `PayloadFrame` envelope first (the supported contract) and
/// falls back to the raw JSON shape so older hub builds still work. Logs the
/// path chosen via the `onShape` callback when provided so observability can
/// track when the legacy fallback can finally be removed.
class CompatConnectionReadyDecoder implements ConnectionReadyDecoder {
  CompatConnectionReadyDecoder({
    PayloadFrameCodec? codec,
    void Function(ConnectionReadyShape shape)? onShape,
  }) : _payloadFrameDecoder = PayloadFrameConnectionReadyDecoder(codec: codec),
       _rawJsonDecoder = const JsonOnlyConnectionReadyDecoder(),
       _onShape = onShape;

  final PayloadFrameConnectionReadyDecoder _payloadFrameDecoder;
  final JsonOnlyConnectionReadyDecoder _rawJsonDecoder;
  final void Function(ConnectionReadyShape shape)? _onShape;

  @override
  ConnectionReadyPayload? decode(Object? raw) {
    final framed = _payloadFrameDecoder.decode(raw);
    if (framed != null) {
      _onShape?.call(ConnectionReadyShape.payloadFrame);
      return framed;
    }
    final legacy = _rawJsonDecoder.decode(raw);
    if (legacy != null) {
      _onShape?.call(ConnectionReadyShape.rawJson);
      return legacy;
    }
    return null;
  }
}

/// Path actually used by [CompatConnectionReadyDecoder] for a given input.
enum ConnectionReadyShape { payloadFrame, rawJson }
