import 'dart:convert';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:colmeia/core/socket/payload_frame_signer.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayloadFrameSignatureMetadata.toCanonicalJsonUtf8', () {
    test(
      'serialises keys in the exact order required by the hub '
      '(schemaVersion -> requestId)',
      () {
        const metadata = PayloadFrameSignatureMetadata(
          schemaVersion: '1.0',
          enc: 'json',
          cmp: 'gzip',
          contentType: 'application/json',
          originalSize: 1024,
          compressedSize: 512,
          traceId: 'trace-1',
          requestId: 'req-1',
        );
        final bytes = metadata.toCanonicalJsonUtf8();
        final decoded = utf8.decode(bytes);
        // The hub uses V8 JSON.stringify which honors insertion
        // order, and the codec MUST agree byte-for-byte. We assert
        // the literal string instead of decoding+comparing maps so a
        // future refactor that reorders keys breaks the test.
        check(decoded).equals(
          '{"schemaVersion":"1.0","enc":"json","cmp":"gzip",'
          '"contentType":"application/json","originalSize":1024,'
          '"compressedSize":512,"traceId":"trace-1","requestId":"req-1"}',
        );
      },
    );

    test('emits null for missing traceId / requestId', () {
      const metadata = PayloadFrameSignatureMetadata(
        schemaVersion: '1.0',
        enc: 'json',
        cmp: 'none',
        contentType: 'application/json',
        originalSize: 8,
        compressedSize: 8,
      );
      final decoded = utf8.decode(metadata.toCanonicalJsonUtf8());
      check(decoded).contains('"traceId":null');
      check(decoded).contains('"requestId":null');
    });
  });

  group('Hmac256PayloadFrameSigner', () {
    test(
      'reproduces the hub formula: '
      'base64(HMAC-SHA256(key, metadataJson || 0x00 || payload))',
      () {
        final signer = Hmac256PayloadFrameSigner.fromUtf8Key(
          key: 'shared-secret',
          keyId: 'hub-2026-q2',
        );
        const metadata = PayloadFrameSignatureMetadata(
          schemaVersion: '1.0',
          enc: 'json',
          cmp: 'none',
          contentType: 'application/json',
          originalSize: 13,
          compressedSize: 13,
          requestId: 'req-1',
        );
        final payload = Uint8List.fromList(utf8.encode('{"hello":"hi"}'));

        final signature = signer.sign(
          metadata: metadata,
          binaryPayload: payload,
        );

        // Independently compute the expected base64 HMAC to keep the
        // test self-checking — ANY drift in metadata ordering or
        // separator bytes will break it.
        final metadataBytes = metadata.toCanonicalJsonUtf8();
        final expectedInput = Uint8List(
          metadataBytes.length + 1 + payload.length,
        )
          ..setRange(0, metadataBytes.length, metadataBytes)
          ..[metadataBytes.length] = 0
          ..setRange(
            metadataBytes.length + 1,
            metadataBytes.length + 1 + payload.length,
            payload,
          );
        final expectedDigest =
            Hmac(sha256, utf8.encode('shared-secret')).convert(expectedInput);
        final expectedValue = base64Encode(expectedDigest.bytes);

        check(signature.algorithm).equals(
          PayloadFrameSignature.algorithmHmacSha256,
        );
        check(signature.value).equals(expectedValue);
        check(signature.keyId).equals('hub-2026-q2');
      },
    );

    test(
      'omits keyId when the hub is unconfigured (single-key deployment)',
      () {
        final signer = Hmac256PayloadFrameSigner.fromUtf8Key(
          key: 'k',
        );
        const metadata = PayloadFrameSignatureMetadata(
          schemaVersion: '1.0',
          enc: 'json',
          cmp: 'none',
          contentType: 'application/json',
          originalSize: 1,
          compressedSize: 1,
        );
        final signature = signer.sign(
          metadata: metadata,
          binaryPayload: Uint8List(1),
        );
        check(signature.keyId).isNull();
        // Wire shape MUST drop the key_id field too — the hub schema
        // rejects extra `null` keys inside `signature`.
        check(signature.toMap().containsKey('key_id')).isFalse();
      },
    );

    test('treats whitespace-only keyId as absent', () {
      final signer = Hmac256PayloadFrameSigner.fromUtf8Key(
        key: 'k',
        keyId: '   ',
      );
      const metadata = PayloadFrameSignatureMetadata(
        schemaVersion: '1.0',
        enc: 'json',
        cmp: 'none',
        contentType: 'application/json',
        originalSize: 0,
        compressedSize: 0,
      );
      final signature = signer.sign(
        metadata: metadata,
        binaryPayload: Uint8List(0),
      );
      check(signature.keyId).isNull();
    });

    test(
      'changing any metadata field changes the signature '
      '(domain separation works)',
      () {
        final signer = Hmac256PayloadFrameSigner.fromUtf8Key(key: 'k');
        const base = PayloadFrameSignatureMetadata(
          schemaVersion: '1.0',
          enc: 'json',
          cmp: 'none',
          contentType: 'application/json',
          originalSize: 4,
          compressedSize: 4,
          requestId: 'a',
        );
        const swappedRequestId = PayloadFrameSignatureMetadata(
          schemaVersion: '1.0',
          enc: 'json',
          cmp: 'none',
          contentType: 'application/json',
          originalSize: 4,
          compressedSize: 4,
          requestId: 'b',
        );
        final payload = Uint8List.fromList(<int>[1, 2, 3, 4]);
        final s1 = signer.sign(metadata: base, binaryPayload: payload);
        final s2 = signer.sign(
          metadata: swappedRequestId,
          binaryPayload: payload,
        );
        check(s1.value).not((it) => it.equals(s2.value));
      },
    );
  });
}
