import 'dart:convert';
import 'dart:typed_data';

/// PayloadFrame envelope used by the `/consumers` namespace for binary RPC
/// transport (Phase 2 of `docs/Features/socket_consumer_channel_plan.md`).
///
/// Source contract: `plug_server/docs/socket_client_sdk.md` and
/// `socket_relay_protocol.md` (`PayloadFrame v1.0`, JSON-only payload, optional
/// gzip + HMAC signature).
///
/// This class is **pure data**: encode/decode + size limits live in
/// `PayloadFrameCodec` so the envelope itself stays cheap to construct, copy
/// and compare in tests.
class PayloadFrame {
  const PayloadFrame({
    required this.payload,
    required this.originalSize,
    required this.compressedSize,
    this.schemaVersion = supportedSchemaVersion,
    this.enc = supportedEncoding,
    this.cmp = compressionNone,
    this.contentType = supportedContentType,
    this.requestId,
    this.traceId,
    this.signature,
  });

  /// Schema version supported by Colmeia. The hub validates `1.0` only.
  static const String supportedSchemaVersion = '1.0';

  /// Wire encoding supported by both ends.
  static const String supportedEncoding = 'json';

  /// MIME for the inner JSON document.
  static const String supportedContentType = 'application/json';

  /// Identity compression marker.
  static const String compressionNone = 'none';

  /// Gzip compression marker.
  static const String compressionGzip = 'gzip';

  /// Raw bytes either compressed (`cmp == gzip`) or the JSON UTF-8 payload
  /// itself (`cmp == none`). See `PayloadFrameCodec.decodeJson`.
  final Uint8List payload;

  /// Length in bytes of the **uncompressed** JSON UTF-8 representation.
  final int originalSize;

  /// Length in bytes of [payload] as carried on the wire.
  final int compressedSize;

  final String schemaVersion;
  final String enc;
  final String cmp;
  final String contentType;

  /// Hub-supplied id used to correlate request/response/chunks. When relaying
  /// a request the consumer SHOULD include the JSON-RPC `id` here.
  final String? requestId;

  /// OpenTelemetry trace identifier (omitted in high-throughput stream events).
  final String? traceId;

  /// Optional HMAC-SHA256 envelope signature. The server validates it when
  /// `PAYLOAD_SIGNING_KEY` is configured upstream.
  final PayloadFrameSignature? signature;

  /// Wire-format JSON representation. Bytes are base64-encoded so the same
  /// envelope can travel both as a Socket.IO binary attachment and as a
  /// nested JSON value (e.g. inside `relay:rpc.request`).
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'enc': enc,
      'cmp': cmp,
      'contentType': contentType,
      'originalSize': originalSize,
      'compressedSize': compressedSize,
      'payload': base64Encode(payload),
      if (requestId != null) 'requestId': requestId,
      if (traceId != null) 'traceId': traceId,
      if (signature != null) 'signature': signature!.toMap(),
    };
  }

  /// Decodes an inbound envelope without validating its semantic limits — that
  /// belongs to `PayloadFrameCodec.decodeJson`. Returns `null` when [raw] is
  /// not a valid JSON map structure.
  ///
  /// [raw] may be a `Map`, a JSON-encoded `String`, a `Uint8List` of UTF-8
  /// JSON bytes, or already a [PayloadFrame] (no-op).
  static PayloadFrame? tryParse(Object? raw) {
    final map = _toMap(raw);
    if (map == null) {
      return null;
    }
    final payload = _decodePayloadField(map['payload']);
    if (payload == null) {
      return null;
    }
    final originalSize = _asInt(map['originalSize']);
    final compressedSize = _asInt(map['compressedSize']);
    if (originalSize == null || originalSize < 0) {
      return null;
    }
    if (compressedSize == null || compressedSize < 0) {
      return null;
    }
    final schemaVersion = map['schemaVersion']?.toString();
    final enc = map['enc']?.toString();
    final cmp = map['cmp']?.toString();
    final contentType = map['contentType']?.toString();
    if (schemaVersion == null ||
        enc == null ||
        cmp == null ||
        contentType == null) {
      return null;
    }
    return PayloadFrame(
      schemaVersion: schemaVersion,
      enc: enc,
      cmp: cmp,
      contentType: contentType,
      originalSize: originalSize,
      compressedSize: compressedSize,
      payload: payload,
      requestId: map['requestId']?.toString(),
      traceId: map['traceId']?.toString(),
      signature: PayloadFrameSignature.tryParse(map['signature']),
    );
  }

  static Map<String, Object?>? _toMap(Object? raw) {
    if (raw is PayloadFrame) {
      return raw.toMap();
    }
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
        return decoded is Map ? _toMap(decoded) : null;
      } on FormatException {
        return null;
      }
    }
    if (raw is List<int>) {
      try {
        final decoded = jsonDecode(utf8.decode(raw));
        return decoded is Map ? _toMap(decoded) : null;
      } on FormatException {
        return null;
      } on Object {
        return null;
      }
    }
    return null;
  }

  static Uint8List? _decodePayloadField(Object? raw) {
    if (raw is Uint8List) {
      return raw;
    }
    if (raw is List<int>) {
      return Uint8List.fromList(raw);
    }
    if (raw is String) {
      try {
        return base64Decode(raw);
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  static int? _asInt(Object? raw) {
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

/// Optional HMAC-SHA256 signature block inside a [PayloadFrame].
class PayloadFrameSignature {
  const PayloadFrameSignature({
    required this.algorithm,
    required this.value,
    this.keyId,
  });

  static const String algorithmHmacSha256 = 'hmac-sha256';

  final String algorithm;
  final String value;
  final String? keyId;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'alg': algorithm,
      'value': value,
      if (keyId != null) 'key_id': keyId,
    };
  }

  static PayloadFrameSignature? tryParse(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is! Map) {
      return null;
    }
    final map = raw.map(
      (key, value) => MapEntry<String, Object?>(key.toString(), value),
    );
    final alg = map['alg']?.toString();
    final value = map['value']?.toString();
    if (alg == null || value == null || alg.isEmpty || value.isEmpty) {
      return null;
    }
    return PayloadFrameSignature(
      algorithm: alg,
      value: value,
      keyId: map['key_id']?.toString(),
    );
  }
}
