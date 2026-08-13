import 'dart:convert';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/payload_frame_codec_worker.dart';
import 'package:colmeia/core/socket/payload_frame_signer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayloadFrameCodecWorker', () {
    late PayloadFrameCodecWorker worker;

    setUp(() {
      worker = PayloadFrameCodecWorker();
    });

    tearDown(() {
      worker.dispose();
    });

    test('round-trips gzip and json', () async {
      final jsonBytes = Uint8List.fromList(
        utf8.encode(jsonEncode(<String, Object?>{'ok': true, 'n': 7})),
      );
      final compressed = await worker.gzipEncode(jsonBytes);
      final inflated = await worker.gzipDecode(compressed);
      check(inflated).deepEquals(jsonBytes);
      final decoded = await worker.jsonDecodeUtf8(jsonBytes);
      if (decoded is! Map) {
        fail('expected Map, got $decoded');
      }
      check(decoded['ok']).equals(true);
      final encoded = await worker.jsonEncodeUtf8(<String, Object?>{'ok': true});
      check(jsonDecode(utf8.decode(encoded))).isA<Map<Object?, Object?>>();
    });

    test('dispose is idempotent', () {
      worker
        ..dispose()
        ..dispose();
    });

    test('jobs after dispose fail so callers can fall back', () async {
      await worker.ensureStarted();
      worker.dispose();
      await expectLater(
        worker.gzipEncode(Uint8List(4)),
        throwsA(isA<PayloadFrameCodecWorkerUnavailable>()),
      );
    });
  });

  group('PayloadFrameCodecWorker HMAC', () {
    test('sign then verify with the same key', () async {
      final key = Uint8List.fromList(utf8.encode('test-signing-key'));
      final worker = PayloadFrameCodecWorker(hmacKey: key, hmacKeyId: 'k1');
      addTearDown(worker.dispose);

      const metadata = PayloadFrameSignatureMetadata(
        schemaVersion: '1.0',
        enc: 'json',
        cmp: 'none',
        contentType: 'application/json',
        originalSize: 2,
        compressedSize: 2,
      );
      final payload = Uint8List.fromList(utf8.encode('{}'));
      final signature = await worker.hmacSign(
        metadata: metadata,
        binaryPayload: payload,
      );
      check(signature.keyId).equals('k1');
      final outcome = await worker.hmacVerify(
        metadata: metadata,
        binaryPayload: payload,
        signature: signature,
      );
      check(outcome).equals(PayloadFrameSignatureVerification.valid);
    });
  });
}
