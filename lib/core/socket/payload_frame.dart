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

  static const Set<String> _wireKeys = <String>{
    'schemaVersion',
    'enc',
    'cmp',
    'contentType',
    'originalSize',
    'compressedSize',
    'payload',
    'requestId',
    'traceId',
    'signature',
  };

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

  /// Parses envelope metadata without decoding [payload] bytes.
  ///
  /// The `payload` field is kept as the wire value (`String` base64 or
  /// `List<int>`). Call [materialize] (or [parseDetailed]) before codec
  /// decode. Use this on socket handlers that only need `requestId` /
  /// `traceId` to route.
  static PayloadFrameHeadersParseResult parseHeaders(Object? raw) {
    if (raw is PayloadFrame) {
      return PayloadFrameHeadersParseSuccess(
        PayloadFrameHeaders.fromFrame(raw),
      );
    }
    final mapResult = _toMapDetailed(raw);
    final mapFailure = mapResult.failure;
    if (mapFailure != null) {
      return mapFailure;
    }
    final map = mapResult.map!;
    if (!_hasOnlyKeys(map, _wireKeys)) {
      final unknownKey = map.keys.firstWhere((key) => !_wireKeys.contains(key));
      return PayloadFrameParseFailure(
        PayloadFrameParseFailureCodes.unknownRootKey,
        'PayloadFrame contains unknown root key "$unknownKey"',
      );
    }
    if (!map.containsKey('payload')) {
      return const PayloadFrameParseFailure(
        PayloadFrameParseFailureCodes.missingPayload,
        'PayloadFrame is missing payload',
      );
    }
    final rawPayload = map['payload'];
    if (!_isRawPayloadField(rawPayload)) {
      return const PayloadFrameParseFailure(
        PayloadFrameParseFailureCodes.invalidPayloadBase64,
        'PayloadFrame payload is not valid base64 or bytes',
      );
    }
    final payloadField = rawPayload!;
    final originalSize = _asInt(map['originalSize']);
    final compressedSize = _asInt(map['compressedSize']);
    if (originalSize == null || originalSize < 0) {
      return const PayloadFrameParseFailure(
        PayloadFrameParseFailureCodes.invalidOriginalSize,
        'PayloadFrame originalSize is missing, invalid, or negative',
      );
    }
    if (compressedSize == null || compressedSize < 0) {
      return const PayloadFrameParseFailure(
        PayloadFrameParseFailureCodes.invalidCompressedSize,
        'PayloadFrame compressedSize is missing, invalid, or negative',
      );
    }
    final schemaVersion = map['schemaVersion']?.toString();
    final enc = map['enc']?.toString();
    final cmp = map['cmp']?.toString();
    final contentType = map['contentType']?.toString();
    if (schemaVersion == null ||
        schemaVersion.isEmpty ||
        enc == null ||
        enc.isEmpty ||
        cmp == null ||
        cmp.isEmpty ||
        contentType == null ||
        contentType.isEmpty) {
      return const PayloadFrameParseFailure(
        PayloadFrameParseFailureCodes.missingSchemaFields,
        'PayloadFrame schemaVersion, enc, cmp, and contentType are required',
      );
    }
    final rawSignature = map['signature'];
    final PayloadFrameSignature? signature;
    if (rawSignature == null) {
      signature = null;
    } else {
      final signatureResult = PayloadFrameSignature._parseDetailed(
        rawSignature,
      );
      if (signatureResult case _PayloadFrameSignatureParseFailure()) {
        return PayloadFrameParseFailure(
          signatureResult.code,
          signatureResult.message,
        );
      }
      signature =
          (signatureResult as _PayloadFrameSignatureParseSuccess).signature;
    }

    return PayloadFrameHeadersParseSuccess(
      PayloadFrameHeaders(
        schemaVersion: schemaVersion,
        enc: enc,
        cmp: cmp,
        contentType: contentType,
        originalSize: originalSize,
        compressedSize: compressedSize,
        rawPayload: payloadField,
        requestId: map['requestId']?.toString(),
        traceId: map['traceId']?.toString(),
        signature: signature,
      ),
    );
  }

  /// Decodes the wire payload field into a [PayloadFrame]. Invalid base64
  /// fails here rather than in [parseHeaders].
  static PayloadFrameParseResult materialize(PayloadFrameHeaders headers) {
    final payload = _decodePayloadField(headers.rawPayload);
    if (payload == null) {
      return const PayloadFrameParseFailure(
        PayloadFrameParseFailureCodes.invalidPayloadBase64,
        'PayloadFrame payload is not valid base64 or bytes',
      );
    }
    return PayloadFrameParseSuccess(
      PayloadFrame(
        schemaVersion: headers.schemaVersion,
        enc: headers.enc,
        cmp: headers.cmp,
        contentType: headers.contentType,
        originalSize: headers.originalSize,
        compressedSize: headers.compressedSize,
        payload: payload,
        requestId: headers.requestId,
        traceId: headers.traceId,
        signature: headers.signature,
      ),
    );
  }

  /// Decodes an inbound envelope without validating its semantic limits — that
  /// belongs to `PayloadFrameCodec.decodeJson`. Returns `null` when [raw] is
  /// not a valid JSON map structure.
  ///
  /// [raw] may be a `Map`, a JSON-encoded `String`, a `Uint8List` of UTF-8
  /// JSON bytes, or already a [PayloadFrame] (no-op).
  static PayloadFrame? tryParse(Object? raw) {
    return switch (parseDetailed(raw)) {
      PayloadFrameParseSuccess(:final frame) => frame,
      PayloadFrameParseFailure() => null,
    };
  }

  /// Eager parse: [parseHeaders] plus [materialize]. Socket handlers that
  /// only need `requestId` should call [parseHeaders] instead.
  static PayloadFrameParseResult parseDetailed(Object? raw) {
    if (raw is PayloadFrame) {
      return PayloadFrameParseSuccess(raw);
    }
    switch (parseHeaders(raw)) {
      case PayloadFrameHeadersParseSuccess(:final headers):
        return materialize(headers);
      case final PayloadFrameParseFailure failure:
        return failure;
    }
  }

  static ({
    Map<String, Object?>? map,
    PayloadFrameParseFailure? failure,
  })
  _toMapDetailed(Object? raw) {
    if (raw is Map<String, Object?>) {
      return (map: raw, failure: null);
    }
    if (raw is Map) {
      return (
        map: raw.map(
          (key, value) => MapEntry<String, Object?>(key.toString(), value),
        ),
        failure: null,
      );
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        return decoded is Map
            ? _toMapDetailed(decoded)
            : (
                map: null,
                failure: const PayloadFrameParseFailure(
                  PayloadFrameParseFailureCodes.notMap,
                  'PayloadFrame envelope JSON is not an object',
                ),
              );
      } on FormatException catch (error) {
        return (
          map: null,
          failure: PayloadFrameParseFailure(
            PayloadFrameParseFailureCodes.invalidJsonEnvelope,
            'PayloadFrame envelope is not valid JSON: ${error.message}',
          ),
        );
      }
    }
    if (raw is List<int>) {
      try {
        final decoded = jsonDecode(utf8.decode(raw));
        return decoded is Map
            ? _toMapDetailed(decoded)
            : (
                map: null,
                failure: const PayloadFrameParseFailure(
                  PayloadFrameParseFailureCodes.notMap,
                  'PayloadFrame envelope JSON is not an object',
                ),
              );
      } on FormatException catch (error) {
        return (
          map: null,
          failure: PayloadFrameParseFailure(
            PayloadFrameParseFailureCodes.invalidJsonEnvelope,
            'PayloadFrame envelope bytes are not valid JSON: ${error.message}',
          ),
        );
      } on Object {
        return (
          map: null,
          failure: const PayloadFrameParseFailure(
            PayloadFrameParseFailureCodes.invalidJsonEnvelope,
            'PayloadFrame envelope bytes are not valid UTF-8 JSON',
          ),
        );
      }
    }
    return (
      map: null,
      failure: PayloadFrameParseFailure(
        PayloadFrameParseFailureCodes.notMap,
        'PayloadFrame envelope must be a map, JSON string, or bytes; got '
        '${raw.runtimeType}',
      ),
    );
  }

  static bool _isRawPayloadField(Object? raw) {
    return raw is String || raw is List<int>;
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
      if (!raw.isFinite) {
        return null;
      }
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw);
    }
    return null;
  }

  static bool _hasOnlyKeys(
    Map<String, Object?> map,
    Set<String> allowedKeys,
  ) {
    return map.keys.every(allowedKeys.contains);
  }
}

/// Envelope metadata without decoded payload bytes. Produced by
/// [PayloadFrame.parseHeaders]; turn into a [PayloadFrame] via
/// [PayloadFrame.materialize].
final class PayloadFrameHeaders {
  const PayloadFrameHeaders({
    required this.schemaVersion,
    required this.enc,
    required this.cmp,
    required this.contentType,
    required this.originalSize,
    required this.compressedSize,
    required this.rawPayload,
    this.requestId,
    this.traceId,
    this.signature,
  });

  factory PayloadFrameHeaders.fromFrame(PayloadFrame frame) {
    return PayloadFrameHeaders(
      schemaVersion: frame.schemaVersion,
      enc: frame.enc,
      cmp: frame.cmp,
      contentType: frame.contentType,
      originalSize: frame.originalSize,
      compressedSize: frame.compressedSize,
      rawPayload: frame.payload,
      requestId: frame.requestId,
      traceId: frame.traceId,
      signature: frame.signature,
    );
  }

  final String schemaVersion;
  final String enc;
  final String cmp;
  final String contentType;
  final int originalSize;
  final int compressedSize;

  /// Wire `payload` field: base64 [String] or raw [List<int>] bytes.
  final Object rawPayload;

  final String? requestId;
  final String? traceId;
  final PayloadFrameSignature? signature;
}

sealed class PayloadFrameParseResult {
  const PayloadFrameParseResult();
}

sealed class PayloadFrameHeadersParseResult {
  const PayloadFrameHeadersParseResult();
}

final class PayloadFrameParseSuccess extends PayloadFrameParseResult {
  const PayloadFrameParseSuccess(this.frame);

  final PayloadFrame frame;
}

final class PayloadFrameHeadersParseSuccess
    extends PayloadFrameHeadersParseResult {
  const PayloadFrameHeadersParseSuccess(this.headers);

  final PayloadFrameHeaders headers;
}

final class PayloadFrameParseFailure
    implements PayloadFrameParseResult, PayloadFrameHeadersParseResult {
  const PayloadFrameParseFailure(this.code, this.message);

  final String code;
  final String message;
}

abstract final class PayloadFrameParseFailureCodes {
  static const String notMap = 'not_map';
  static const String invalidJsonEnvelope = 'invalid_json_envelope';
  static const String unknownRootKey = 'unknown_root_key';
  static const String missingPayload = 'missing_payload';
  static const String invalidPayloadBase64 = 'invalid_payload_base64';
  static const String invalidOriginalSize = 'invalid_original_size';
  static const String invalidCompressedSize = 'invalid_compressed_size';
  static const String missingSchemaFields = 'missing_schema_fields';
  static const String invalidSignature = 'invalid_signature';
  static const String unknownSignatureKey = 'unknown_signature_key';
  static const String missingSignatureFields = 'missing_signature_fields';
}

/// Optional HMAC-SHA256 signature block inside a [PayloadFrame].
class PayloadFrameSignature {
  const PayloadFrameSignature({
    required this.algorithm,
    required this.value,
    this.keyId,
  });

  static const String algorithmHmacSha256 = 'hmac-sha256';

  static const Set<String> _wireKeys = <String>{
    'alg',
    'value',
    'key_id',
  };

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
    return switch (_parseDetailed(raw)) {
      _PayloadFrameSignatureParseSuccess(:final signature) => signature,
      _PayloadFrameSignatureParseFailure() => null,
    };
  }

  static _PayloadFrameSignatureParseResult _parseDetailed(Object? raw) {
    if (raw == null) {
      return const _PayloadFrameSignatureParseFailure(
        PayloadFrameParseFailureCodes.invalidSignature,
        'PayloadFrame signature is missing',
      );
    }
    if (raw is! Map) {
      return const _PayloadFrameSignatureParseFailure(
        PayloadFrameParseFailureCodes.invalidSignature,
        'PayloadFrame signature must be an object',
      );
    }
    final map = raw.map(
      (key, value) => MapEntry<String, Object?>(key.toString(), value),
    );
    if (!map.keys.every(_wireKeys.contains)) {
      final unknownKey = map.keys.firstWhere(
        (key) => !_wireKeys.contains(key),
      );
      return _PayloadFrameSignatureParseFailure(
        PayloadFrameParseFailureCodes.unknownSignatureKey,
        'PayloadFrame signature contains unknown key "$unknownKey"',
      );
    }
    final alg = map['alg']?.toString();
    final value = map['value']?.toString();
    if (alg == null || value == null || alg.isEmpty || value.isEmpty) {
      return const _PayloadFrameSignatureParseFailure(
        PayloadFrameParseFailureCodes.missingSignatureFields,
        'PayloadFrame signature alg and value are required',
      );
    }
    return _PayloadFrameSignatureParseSuccess(
      PayloadFrameSignature(
        algorithm: alg,
        value: value,
        keyId: map['key_id']?.toString(),
      ),
    );
  }
}

sealed class _PayloadFrameSignatureParseResult {
  const _PayloadFrameSignatureParseResult();
}

final class _PayloadFrameSignatureParseSuccess
    extends _PayloadFrameSignatureParseResult {
  const _PayloadFrameSignatureParseSuccess(this.signature);

  final PayloadFrameSignature signature;
}

final class _PayloadFrameSignatureParseFailure
    extends _PayloadFrameSignatureParseResult {
  const _PayloadFrameSignatureParseFailure(this.code, this.message);

  final String code;
  final String message;
}
