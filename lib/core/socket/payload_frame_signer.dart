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
  })  : _hmac = Hmac(sha256, key),
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
