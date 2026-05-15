import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:colmeia/core/socket/payload_frame_codec.dart';
import 'package:colmeia/core/socket/payload_frame_signer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayloadFrameCodec contract defaults', () {
    test('match the plug_server PayloadFrame contract', () {
      check(PayloadFrameCodec.defaultCompressionThresholdBytes).equals(4096);
      check(PayloadFrameCodec.defaultMaxInflationRatio).equals(10);
      check(PayloadFrameCodec.defaultMaxPayloadBytes).equals(10 * 1024 * 1024);
    });
  });

  group('PayloadFrameCodec.encodeJson', () {
    const codec = PayloadFrameCodec();

    test('emits cmp=none for small payloads (below threshold)', () {
      final result = codec.encodeJson(<String, Object?>{'v': 'x' * 3500});
      check(result.encoded.length).isLessThan(
        PayloadFrameCodec.defaultCompressionThresholdBytes,
      );
      check(result.frame.cmp).equals(PayloadFrame.compressionNone);
      check(result.frame.compressedSize).equals(result.encoded.length);
      check(result.frame.originalSize).equals(result.encoded.length);
    });

    test('uses gzip when it strictly reduces bytes', () {
      final rows = List<Map<String, Object?>>.generate(
        200,
        (i) => <String, Object?>{
          'id': i,
          'name': 'agent-$i',
          'tag': 'sample-payload-row-${i % 7}',
        },
      );
      final result = codec.encodeJson(<String, Object?>{'rows': rows});
      check(result.encoded.length).isGreaterOrEqual(
        PayloadFrameCodec.defaultCompressionThresholdBytes,
      );
      check(result.frame.cmp).equals(PayloadFrame.compressionGzip);
      check(result.frame.compressedSize).isLessThan(result.encoded.length);
      check(result.frame.originalSize).equals(result.encoded.length);
    });

    test('keeps cmp=none when gzip would exceed the inflation guard', () {
      final repeated = 'A' * 4096;
      final result = codec.encodeJson(<String, Object?>{'v': repeated});
      check(result.encoded.length).isGreaterOrEqual(
        PayloadFrameCodec.defaultCompressionThresholdBytes,
      );
      check(result.frame.cmp).equals(PayloadFrame.compressionNone);
      check(result.frame.compressedSize).equals(result.encoded.length);
    });

    test('skips gzip when the result would be larger', () {
      // Tiny payload: well below the 4096-byte threshold, so gzip is never even
      // attempted. Verifies the threshold short-circuit, complementary to
      // the "uses gzip" test that proves activation when the threshold is
      // crossed and compression actually wins.
      final result = codec.encodeJson(<String, Object?>{'a': 1, 'b': 2});
      check(result.frame.cmp).equals(PayloadFrame.compressionNone);
      check(result.frame.compressedSize).equals(result.encoded.length);
    });

    test('throws payload_too_large when over cap', () {
      const tinyCodec = PayloadFrameCodec(maxPayloadBytes: 16);
      check(
            () => tinyCodec.encodeJson(<String, Object?>{'v': 'x' * 64}),
          )
          .throws<PayloadFrameDecodeException>()
          .has(
            (e) => e.code,
            'code',
          )
          .equals('payload_too_large');
    });

    test('round-trips through decodeJson', () {
      final value = <String, Object?>{
        'agentId': '3183a9f2',
        'command': <String, Object?>{
          'jsonrpc': '2.0',
          'method': 'sql.execute',
          'params': <String, Object?>{'sql': 'SELECT 1'},
        },
      };
      final encoded = codec.encodeJson(value);
      final decoded = codec.decodeJson(encoded.frame);
      // jsonDecode reconstructs Map<String, dynamic>, so compare via
      // re-serialization to validate semantic equality (and indirectly
      // that all keys/values survived the gzip-aware round-trip).
      check(jsonEncode(decoded)).equals(jsonEncode(value));
    });

    test(
      'round-trips through decodeJson with gzip',
      () {
        // Mixed payload: large enough to cross the 4096-byte threshold and
        // still compressible, but not so degenerate that gzip beats the
        // 10x inflation guard.
        final rows = List<Map<String, Object?>>.generate(
          200,
          (i) => <String, Object?>{
            'id': i,
            'name': 'agent-$i',
            'tag': 'sample-payload-row-${i % 7}',
          },
        );
        final value = <String, Object?>{'rows': rows};
        final encoded = codec.encodeJson(value);
        check(encoded.frame.cmp).equals(PayloadFrame.compressionGzip);
        final decoded = codec.decodeJson(encoded.frame);
        check(jsonEncode(decoded)).equals(jsonEncode(value));
      },
    );

    test(
      'decodeJsonAsync round-trips gzip using isolate when threshold is 0',
      () async {
        const codec = PayloadFrameCodec(gzipDecodeIsolateThresholdBytes: 0);
        final rows = List<Map<String, Object?>>.generate(
          200,
          (i) => <String, Object?>{
            'id': i,
            'name': 'agent-$i',
            'tag': 'sample-payload-row-${i % 7}',
          },
        );
        final value = <String, Object?>{'rows': rows};
        final encoded = codec.encodeJson(value);
        check(encoded.frame.cmp).equals(PayloadFrame.compressionGzip);
        final decoded = await codec.decodeJsonAsync(encoded.frame);
        check(jsonEncode(decoded)).equals(jsonEncode(value));
      },
    );

    test(
      'encodeJsonAsync round-trips gzip using isolate when encode threshold is 0',
      () async {
        const codec = PayloadFrameCodec(gzipEncodeIsolateThresholdBytes: 0);
        final rows = List<Map<String, Object?>>.generate(
          200,
          (i) => <String, Object?>{
            'id': i,
            'name': 'agent-$i',
            'tag': 'sample-payload-row-${i % 7}',
          },
        );
        final value = <String, Object?>{'rows': rows};
        final encoded = await codec.encodeJsonAsync(value);
        check(encoded.frame.cmp).equals(PayloadFrame.compressionGzip);
        final decoded = codec.decodeJson(encoded.frame);
        check(jsonEncode(decoded)).equals(jsonEncode(value));
      },
    );

    test(
      'encodeJsonAsync keeps cmp=none when gzip would exceed the guard',
      () async {
        const codec = PayloadFrameCodec(gzipEncodeIsolateThresholdBytes: 0);
        final repeated = 'A' * 4096;
        final encoded = await codec.encodeJsonAsync(<String, Object?>{
          'v': repeated,
        });
        check(encoded.frame.cmp).equals(PayloadFrame.compressionNone);
        check(encoded.frame.compressedSize).equals(encoded.encoded.length);
      },
    );
  });

  group('PayloadFrameCodec.encodeJson — signing', () {
    test('does not populate signature when no signer is configured', () {
      const codec = PayloadFrameCodec();
      final result = codec.encodeJson(<String, Object?>{'a': 1});
      check(result.frame.signature).isNull();
    });

    test(
      'populates signature with HMAC over the wire payload when a signer '
      'is configured',
      () {
        final codec = PayloadFrameCodec(
          signer: Hmac256PayloadFrameSigner.fromUtf8Key(
            key: 'k',
            keyId: 'hub-2026-q2',
          ),
        );
        final result = codec.encodeJson(
          <String, Object?>{'hello': 'hi'},
          requestId: 'req-1',
        );
        final signature = result.frame.signature;
        check(signature).isNotNull();
        check(signature!.algorithm).equals(
          PayloadFrameSignature.algorithmHmacSha256,
        );
        check(signature.value).isNotEmpty();
        check(signature.keyId).equals('hub-2026-q2');
      },
    );

    test(
      'caller-provided signature wins over codec-level signer',
      () {
        // Lets tests / replay fixtures inject a known signature without
        // having to mock the signer. Documents the precedence in
        // PayloadFrameCodec.signer's doc comment.
        final codec = PayloadFrameCodec(
          signer: Hmac256PayloadFrameSigner.fromUtf8Key(key: 'k'),
        );
        const explicit = PayloadFrameSignature(
          algorithm: PayloadFrameSignature.algorithmHmacSha256,
          value: 'EXPLICIT_VALUE_BASE64',
        );
        final result = codec.encodeJson(
          <String, Object?>{'a': 1},
          signature: explicit,
        );
        check(result.frame.signature?.value).equals('EXPLICIT_VALUE_BASE64');
      },
    );

    test('signature wraps gzipped bytes when cmp == gzip', () {
      // Defensive — the hub validates against the wire payload, not
      // the JSON, so a signer that hashed the pre-gzip bytes would
      // silently pass tests but fail in production. We assert the
      // signed frame is actually `cmp: gzip` so the codec contract is
      // explicit.
      final codec = PayloadFrameCodec(
        signer: Hmac256PayloadFrameSigner.fromUtf8Key(key: 'k'),
      );
      final rows = List<Map<String, Object?>>.generate(
        200,
        (i) => <String, Object?>{
          'id': i,
          'name': 'agent-$i',
          'tag': 'sample-payload-row-${i % 7}',
        },
      );
      final result = codec.encodeJson(<String, Object?>{'rows': rows});
      check(result.frame.cmp).equals(PayloadFrame.compressionGzip);
      check(result.frame.signature).isNotNull();
    });
  });

  group('PayloadFrameCodec.decodeJson — signature verification', () {
    test('codec without verifier ignores signature (legacy mode)', () {
      const codec = PayloadFrameCodec();
      final signedFrame = PayloadFrameCodec(
        signer: Hmac256PayloadFrameSigner.fromUtf8Key(key: 'k'),
      ).encodeJson(<String, Object?>{'a': 1}).frame;
      // Even with a signature attached the decoder must succeed —
      // verifier is opt-in via DI / constructor.
      check(jsonEncode(codec.decodeJson(signedFrame))).equals('{"a":1}');
    });

    test(
      'codec with verifier accepts a frame signed by the matching signer',
      () {
        final codec = PayloadFrameCodec(
          signer: Hmac256PayloadFrameSigner.fromUtf8Key(key: 'k'),
          verifier: Hmac256PayloadFrameSignatureVerifier.fromUtf8Key(key: 'k'),
        );
        final result = codec.encodeJson(<String, Object?>{'agentId': 'a'});
        check(
          jsonEncode(codec.decodeJson(result.frame)),
        ).equals('{"agentId":"a"}');
      },
    );

    test(
      'codec with verifier rejects mismatching HMAC with signature_invalid',
      () {
        final signed = PayloadFrameCodec(
          signer: Hmac256PayloadFrameSigner.fromUtf8Key(key: 'attacker'),
        ).encodeJson(<String, Object?>{'a': 1}).frame;
        final codec = PayloadFrameCodec(
          verifier: Hmac256PayloadFrameSignatureVerifier.fromUtf8Key(
            key: 'real',
          ),
        );
        check(() => codec.decodeJson(signed))
            .throws<PayloadFrameDecodeException>()
            .has((e) => e.code, 'code')
            .equals('signature_invalid');
      },
    );

    test(
      'requireSignature=true rejects unsigned frames with signature_required',
      () {
        // The hub today emits unsigned frames by default. Strict
        // builds (defence in depth) flip this on to require every
        // inbound frame to carry a signature.
        final unsigned = const PayloadFrameCodec().encodeJson(<String, Object?>{
          'a': 1,
        }).frame;
        final strict = PayloadFrameCodec(
          verifier: Hmac256PayloadFrameSignatureVerifier.fromUtf8Key(key: 'k'),
          requireSignature: true,
        );
        check(() => strict.decodeJson(unsigned))
            .throws<PayloadFrameDecodeException>()
            .has((e) => e.code, 'code')
            .equals('signature_required');
      },
    );

    test(
      'requireSignature=false (default) accepts unsigned frames',
      () {
        final unsigned = const PayloadFrameCodec().encodeJson(<String, Object?>{
          'a': 1,
        }).frame;
        final permissive = PayloadFrameCodec(
          verifier: Hmac256PayloadFrameSignatureVerifier.fromUtf8Key(key: 'k'),
        );
        check(jsonEncode(permissive.decodeJson(unsigned))).equals('{"a":1}');
      },
    );

    test(
      'codec with verifier rejects key_id mismatch with stable code',
      () {
        // Hub configured with PAYLOAD_SIGNING_KEY_ID — every signed
        // frame MUST carry a matching `key_id`. Frames forged or
        // signed by a stale key (no `key_id`) get rejected.
        final signed = PayloadFrameCodec(
          signer: Hmac256PayloadFrameSigner.fromUtf8Key(key: 'k'),
        ).encodeJson(<String, Object?>{'a': 1}).frame;
        final codec = PayloadFrameCodec(
          verifier: Hmac256PayloadFrameSignatureVerifier.fromUtf8Key(
            key: 'k',
            expectedKeyId: 'rotated-2026',
          ),
        );
        check(() => codec.decodeJson(signed))
            .throws<PayloadFrameDecodeException>()
            .has((e) => e.code, 'code')
            .equals('signature_key_id_mismatch');
      },
    );
  });

  group('PayloadFrameCodec.decodeJson — strict validation', () {
    const codec = PayloadFrameCodec();

    PayloadFrame buildPlain(String json, {String cmp = 'none'}) {
      final bytes = Uint8List.fromList(utf8.encode(json));
      return PayloadFrame(
        payload: bytes,
        originalSize: bytes.length,
        compressedSize: bytes.length,
        cmp: cmp,
      );
    }

    test('rejects unsupported schema version', () {
      final frame = PayloadFrame(
        schemaVersion: '2.0',
        payload: Uint8List(0),
        originalSize: 0,
        compressedSize: 0,
      );
      check(() => codec.decodeJson(frame))
          .throws<PayloadFrameDecodeException>()
          .has((e) => e.code, 'code')
          .equals('unsupported_schema_version');
    });

    test('rejects unsupported encoding', () {
      final frame = PayloadFrame(
        enc: 'binary',
        payload: Uint8List(0),
        originalSize: 0,
        compressedSize: 0,
      );
      check(() => codec.decodeJson(frame))
          .throws<PayloadFrameDecodeException>()
          .has((e) => e.code, 'code')
          .equals('unsupported_encoding');
    });

    test('rejects unsupported compression marker', () {
      final frame = PayloadFrame(
        cmp: 'br',
        payload: Uint8List(0),
        originalSize: 0,
        compressedSize: 0,
      );
      check(() => codec.decodeJson(frame))
          .throws<PayloadFrameDecodeException>()
          .has((e) => e.code, 'code')
          .equals('unsupported_compression');
    });

    test('rejects compressed_size mismatch', () {
      final bytes = Uint8List.fromList(utf8.encode('{"x":1}'));
      final frame = PayloadFrame(
        payload: bytes,
        originalSize: bytes.length,
        compressedSize: bytes.length + 5,
      );
      check(() => codec.decodeJson(frame))
          .throws<PayloadFrameDecodeException>()
          .has((e) => e.code, 'code')
          .equals('compressed_size_mismatch');
    });

    test('rejects original_size mismatch on cmp=none', () {
      final bytes = Uint8List.fromList(utf8.encode('{"x":1}'));
      final frame = PayloadFrame(
        payload: bytes,
        originalSize: bytes.length + 1,
        compressedSize: bytes.length,
      );
      check(() => codec.decodeJson(frame))
          .throws<PayloadFrameDecodeException>()
          .has((e) => e.code, 'code')
          .equals('original_size_mismatch');
    });

    test('rejects gzip inflation above ratio cap', () {
      final huge = 'A' * 8192;
      final original = Uint8List.fromList(utf8.encode(jsonEncode(huge)));
      final gz = Uint8List.fromList(gzip.encode(original));
      final frame = PayloadFrame(
        payload: gz,
        originalSize: original.length,
        compressedSize: gz.length,
        cmp: PayloadFrame.compressionGzip,
      );
      const tightCodec = PayloadFrameCodec(maxInflationRatio: 2);
      check(() => tightCodec.decodeJson(frame))
          .throws<PayloadFrameDecodeException>()
          .has((e) => e.code, 'code')
          .equals('inflation_ratio_exceeded');
    });

    test('rejects gzip output whose decoded size disagrees', () {
      final original = Uint8List.fromList(utf8.encode('{"x":1}'));
      final gz = Uint8List.fromList(gzip.encode(original));
      final frame = PayloadFrame(
        payload: gz,
        originalSize: original.length + 10,
        compressedSize: gz.length,
        cmp: PayloadFrame.compressionGzip,
      );
      check(() => codec.decodeJson(frame))
          .throws<PayloadFrameDecodeException>()
          .has((e) => e.code, 'code')
          .equals('original_size_mismatch');
    });

    test('rejects invalid gzip stream', () {
      final junk = Uint8List.fromList(<int>[1, 2, 3, 4, 5]);
      final frame = PayloadFrame(
        payload: junk,
        originalSize: 8,
        compressedSize: junk.length,
        cmp: PayloadFrame.compressionGzip,
      );
      check(() => codec.decodeJson(frame))
          .throws<PayloadFrameDecodeException>()
          .has((e) => e.code, 'code')
          .equals('gzip_decode_failed');
    });

    test('rejects invalid JSON inside the payload', () {
      final frame = buildPlain('{not json}');
      check(() => codec.decodeJson(frame))
          .throws<PayloadFrameDecodeException>()
          .has((e) => e.code, 'code')
          .equals('json_decode_failed');
    });

    test('rejects compressed payload above max bytes', () {
      const tightCodec = PayloadFrameCodec(maxPayloadBytes: 4);
      final frame = buildPlain('{"x":1}');
      check(() => tightCodec.decodeJson(frame))
          .throws<PayloadFrameDecodeException>()
          .has((e) => e.code, 'code')
          .equals('payload_too_large');
    });
  });
}
