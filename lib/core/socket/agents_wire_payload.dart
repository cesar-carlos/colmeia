import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:colmeia/core/socket/payload_frame_codec.dart';
import 'package:colmeia/core/socket/socket_wire_utils.dart';

/// Decodes hub outbound wire payloads that may arrive as [PayloadFrame]
/// (default since hub migration) or plain JSON maps (legacy `raw_json`
/// shim until 2026-09-30).
///
/// Mirrors `decodeAgentsWirePayload` in
/// `docs/plug_server/socket/socket_client_sdk.md`.
Object? decodeAgentsWirePayload(
  Object? raw, {
  PayloadFrameCodec codec = const PayloadFrameCodec(),
  bool acceptLegacyRawJson = true,
}) {
  switch (PayloadFrame.parseDetailed(raw)) {
    case PayloadFrameParseSuccess(:final frame):
      return codec.decodeJson(frame);
    case final PayloadFrameParseFailure failure:
      if (_looksLikePayloadFrame(raw)) {
        throw PayloadFrameDecodeException(failure.code, failure.message);
      }
  }
  if (!acceptLegacyRawJson) {
    return null;
  }
  return raw;
}

/// Same as [decodeAgentsWirePayload], but returns a string-keyed map or
/// `null` when the logical payload is not an object.
Map<String, dynamic>? decodeAgentsWirePayloadMap(
  Object? raw, {
  PayloadFrameCodec codec = const PayloadFrameCodec(),
  bool acceptLegacyRawJson = true,
}) {
  final decoded = decodeAgentsWirePayload(
    raw,
    codec: codec,
    acceptLegacyRawJson: acceptLegacyRawJson,
  );
  return socketToStringKeyedMap(decoded);
}

bool _looksLikePayloadFrame(Object? raw) {
  if (raw is PayloadFrame || raw is List<int>) {
    return true;
  }
  if (raw is Map) {
    return raw.containsKey('schemaVersion') || raw.containsKey('payload');
  }
  return false;
}
