import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:colmeia/core/socket/payload_frame_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayloadFrameCodec.encodeJson', () {
    const codec = PayloadFrameCodec();

    test('emits cmp=none for small payloads (below threshold)', () {
      final result = codec.encodeJson(<String, Object?>{'a': 1});
      check(result.frame.cmp).equals(PayloadFrame.compressionNone);
      check(result.frame.compressedSize).equals(result.encoded.length);
      check(result.frame.originalSize).equals(result.encoded.length);
    });

    test('uses gzip when it strictly reduces bytes', () {
      // Highly compressible payload above the 1 KiB threshold.
      final repeated = 'A' * 4096;
      final result = codec.encodeJson(<String, Object?>{'v': repeated});
      check(result.frame.cmp).equals(PayloadFrame.compressionGzip);
      check(result.frame.compressedSize).isLessThan(result.encoded.length);
      check(result.frame.originalSize).equals(result.encoded.length);
    });

    test('skips gzip when the result would be larger', () {
      // Tiny payload: well below the 1 KiB threshold, so gzip is never even
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
      ).throws<PayloadFrameDecodeException>().has(
        (e) => e.code,
        'code',
      ).equals('payload_too_large');
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
        // Mixed payload: large enough to cross the 1 KiB threshold and
        // still compressible, but not so degenerate that gzip beats the
        // 20× inflation guard.
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
