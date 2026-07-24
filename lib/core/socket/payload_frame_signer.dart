import 'dart:convert';
import 'dart:typed_data';

import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:crypto/crypto.dart';

/// Computes a [PayloadFrameSignature] for an outbound frame.
///
/// Wire contract mirrors `plug_server/src/shared/utils/payload_frame.ts`
/// (`buildSignatureInput`, `signOutboundFrameIfConfigured`):
///
/// ```text
/// HMAC = HMAC-SHA256(
///   key,
///   utf8(JSON.stringify(metadata)) || 0x00 || binaryPayload
/// )
/// signature.value = base64(HMAC)
/// ```
///
/// where `metadata` MUST serialise the keys in this exact order
/// (matches V8's insertion order used by the hub):
///
/// ```text
/// schemaVersion, enc, cmp, contentType,
/// originalSize, compressedSize,
/// traceId, requestId
/// ```
///
/// Missing `traceId` / `requestId` are emitted as JSON `null` (the hub
/// uses `?? null` in the same position).
///
/// `binaryPayload` is the raw bytes carried on the wire — i.e. the
/// gzipped bytes when `cmp: gzip`, or the JSON UTF-8 bytes otherwise.
// Single-method interface kept on purpose so future signing schemes
// (Ed25519, key-rotation aware wrappers) can implement it without
// breaking existing callers — the codec only knows about this surface.
// ignore: one_member_abstracts
abstract interface class PayloadFrameSigner {
  PayloadFrameSignature sign({
    required PayloadFrameSignatureMetadata metadata,
    required Uint8List binaryPayload,
  });
}

/// Pure-data view of the fields the hub serialises to build the
/// signature input. Kept separate from [PayloadFrame] so signers can be
/// exercised by tests without materialising a full frame.
class PayloadFrameSignatureMetadata {
  const PayloadFrameSignatureMetadata({
    required this.schemaVersion,
    required this.enc,
    required this.cmp,
    required this.contentType,
    required this.originalSize,
    required this.compressedSize,
    this.traceId,
    this.requestId,
  });

  final String schemaVersion;
  final String enc;
  final String cmp;
  final String contentType;
  final int originalSize;
  final int compressedSize;
  final String? traceId;
  final String? requestId;

  /// JSON used as the first half of the HMAC input. The key order
  /// here is **load-bearing** — the hub's `JSON.stringify` relies on
  /// V8 insertion order and any divergence breaks verification.
  Uint8List toCanonicalJsonUtf8() {
    final ordered = <String, Object?>{
      'schemaVersion': schemaVersion,
      'enc': enc,
      'cmp': cmp,
      'contentType': contentType,
      'originalSize': originalSize,
      'compressedSize': compressedSize,
      'traceId': traceId,
      'requestId': requestId,
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(ordered)));
  }
}

/// HMAC-SHA256 signer. Holds the shared key bytes and an optional
/// `key_id` propagated into [PayloadFrameSignature.keyId] — required by
/// the hub when `PAYLOAD_SIGNING_KEY_ID` is configured upstream
/// (otherwise frames missing `key_id` are rejected with `-32001`).
class Hmac256PayloadFrameSigner implements PayloadFrameSigner {
  Hmac256PayloadFrameSigner({
    required Uint8List key,
    String? keyId,
  }) : _hmac = Hmac(sha256, key),
       _keyId = (keyId != null && keyId.trim().isNotEmpty) ? keyId : null;

  /// Convenience constructor for keys provided as plain UTF-8 strings
  /// (e.g. coming straight from `.env`). Hub's `PAYLOAD_SIGNING_KEY` is
  /// itself read as a UTF-8 string and passed to `crypto.createHmac`,
  /// so the same encoding ensures byte-for-byte parity.
  factory Hmac256PayloadFrameSigner.fromUtf8Key({
    required String key,
    String? keyId,
  }) {
    return Hmac256PayloadFrameSigner(
      key: Uint8List.fromList(utf8.encode(key)),
      keyId: keyId,
    );
  }

  final Hmac _hmac;
  final String? _keyId;

  @override
  PayloadFrameSignature sign({
    required PayloadFrameSignatureMetadata metadata,
    required Uint8List binaryPayload,
  }) {
    final metadataJson = metadata.toCanonicalJsonUtf8();
    // Layout: <metadata utf8> <0x00> <binary payload>. The 0x00
    // separator matches the hub's `Buffer.concat([..., Buffer.from([0]),
    // binaryPayload])` so the same tampering attack window is closed
    // (no domain-separation collisions between metadata and payload).
    final input = Uint8List(metadataJson.length + 1 + binaryPayload.length)
      ..setRange(0, metadataJson.length, metadataJson)
      ..[metadataJson.length] = 0
      ..setRange(
        metadataJson.length + 1,
        metadataJson.length + 1 + binaryPayload.length,
        binaryPayload,
      );

    final digest = _hmac.convert(input);
    return PayloadFrameSignature(
      algorithm: PayloadFrameSignature.algorithmHmacSha256,
      value: base64Encode(digest.bytes),
      keyId: _keyId,
    );
  }
}

/// Outcome of [PayloadFrameSignatureVerifier.verify]. Stable codes are
/// surfaced so the codec can map them to `PayloadFrameDecodeException`
/// instances with the same identifiers used by the hub
/// (`payload_frame.ts` rejects with `Authentication failed`).
enum PayloadFrameSignatureVerification {
  /// Signature present and matches the configured key.
  valid('signature_valid'),

  /// Frame carries no `signature` block. The verifier reports this
  /// outcome and lets the caller decide between "ignore" (current
  /// hub default — signing is opt-in) and "reject" (when
  /// `SOCKET_PAYLOAD_REQUIRE_SIGNATURE=true`).
  absent('signature_absent'),

  /// `signature.alg` is a string the verifier does not understand
  /// (only `hmac-sha256` is supported today).
  unsupportedAlgorithm('signature_unsupported_algorithm'),

  /// `signature.value` is empty / not valid base64.
  malformed('signature_malformed'),

  /// Hub configured with `PAYLOAD_SIGNING_KEY_ID` and the frame either
  /// omits `key_id` or carries a divergent value. Rejected because
  /// the hub itself rejects the equivalent flow with `-32001`.
  keyIdMismatch('signature_key_id_mismatch'),

  /// HMAC computed locally does not match `signature.value`. Treat as
  /// tampering or key drift.
  invalid('signature_invalid');

  const PayloadFrameSignatureVerification(this.code);

  /// Stable identifier suitable for `PayloadFrameDecodeException.code`
  /// and metrics labels — mirrors the codes the encoder uses.
  final String code;
}

/// Validates an inbound [PayloadFrameSignature] against a shared key.
/// Counterpart to [PayloadFrameSigner].
// Single-method interface kept on purpose so future schemes (Ed25519,
// JWS) can plug in without breaking the codec contract.
// ignore: one_member_abstracts
abstract interface class PayloadFrameSignatureVerifier {
  PayloadFrameSignatureVerification verify({
    required PayloadFrameSignatureMetadata metadata,
    required Uint8List binaryPayload,
    required PayloadFrameSignature? signature,
  });
}

/// HMAC-SHA256 verifier sharing the same wire contract as
/// [Hmac256PayloadFrameSigner]. Uses a constant-time byte comparison
/// so signature mismatches do not leak per-byte timing information.
class Hmac256PayloadFrameSignatureVerifier
    implements PayloadFrameSignatureVerifier {
  Hmac256PayloadFrameSignatureVerifier({
    required Uint8List key,
    String? expectedKeyId,
  }) : _hmac = Hmac(sha256, key),
       _expectedKeyId =
           (expectedKeyId != null && expectedKeyId.trim().isNotEmpty)
           ? expectedKeyId
           : null;

  /// Convenience constructor for keys provided as plain UTF-8
  /// strings (i.e. coming straight from `.env`).
  factory Hmac256PayloadFrameSignatureVerifier.fromUtf8Key({
    required String key,
    String? expectedKeyId,
  }) {
    return Hmac256PayloadFrameSignatureVerifier(
      key: Uint8List.fromList(utf8.encode(key)),
      expectedKeyId: expectedKeyId,
    );
  }

  final Hmac _hmac;
  final String? _expectedKeyId;

  @override
  PayloadFrameSignatureVerification verify({
    required PayloadFrameSignatureMetadata metadata,
    required Uint8List binaryPayload,
    required PayloadFrameSignature? signature,
  }) {
    if (signature == null) {
      return PayloadFrameSignatureVerification.absent;
    }
    if (signature.algorithm != PayloadFrameSignature.algorithmHmacSha256) {
      return PayloadFrameSignatureVerification.unsupportedAlgorithm;
    }
    final providedValue = signature.value.trim();
    if (providedValue.isEmpty) {
      return PayloadFrameSignatureVerification.malformed;
    }
    // The hub enforces `key_id` only when it is itself configured with
    // an expected id. We mirror that policy here so single-key
    // deployments still accept frames without `key_id`.
    final expected = _expectedKeyId;
    if (expected != null) {
      final providedKeyId = signature.keyId?.trim();
      if (providedKeyId == null || providedKeyId.isEmpty) {
        return PayloadFrameSignatureVerification.keyIdMismatch;
      }
      if (providedKeyId != expected) {
        return PayloadFrameSignatureVerification.keyIdMismatch;
      }
    }
    final List<int> providedBytes;
    try {
      providedBytes = base64Decode(providedValue);
    } on FormatException {
      return PayloadFrameSignatureVerification.malformed;
    }

    final metadataJson = metadata.toCanonicalJsonUtf8();
    final input = Uint8List(metadataJson.length + 1 + binaryPayload.length)
      ..setRange(0, metadataJson.length, metadataJson)
      ..[metadataJson.length] = 0
      ..setRange(
        metadataJson.length + 1,
        metadataJson.length + 1 + binaryPayload.length,
        binaryPayload,
      );

    final expectedDigest = _hmac.convert(input).bytes;
    if (!_constantTimeBytesEqual(expectedDigest, providedBytes)) {
      return PayloadFrameSignatureVerification.invalid;
    }
    return PayloadFrameSignatureVerification.valid;
  }
}

/// Constant-time byte comparison. The standard `List` `==` short-circuits
/// on the first mismatch, leaking position info via timing — this loop
/// folds every byte into a running OR so the work is independent of the
/// data, mirroring `crypto.timingSafeEqual` on the hub side.
bool _constantTimeBytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }
  var result = 0;
  for (var i = 0; i < a.length; i++) {
    result |= a[i] ^ b[i];
  }
  return result == 0;
}
