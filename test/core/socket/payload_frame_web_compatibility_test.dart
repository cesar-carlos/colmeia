import 'dart:convert';
import 'dart:typed_data';

import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:colmeia/core/socket/payload_frame_codec.dart';
import 'package:colmeia/core/socket/payload_frame_signer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes an externally compressed gzip frame without native APIs', () {
    final bytes = Uint8List.fromList(
      base64Decode(
        'H4sIAAAAAAACCqtWyk0tLk5MT1WyUkoqyi8vTi1S0lFKzi/NK1GyMq8FAP4odIcfAAAA',
      ),
    );
    final frame = PayloadFrame(
      payload: bytes,
      originalSize: 31,
      compressedSize: bytes.length,
      cmp: PayloadFrame.compressionGzip,
    );
    const codec = PayloadFrameCodec(workerIsolatesEnabled: false);
    expect(codec.decodeJson(frame), {'message': 'browser', 'count': 7});
  });

  test(
    'round-trips signed compressed payloads without worker isolates',
    () async {
      final codec = PayloadFrameCodec(
        workerIsolatesEnabled: false,
        compressionThresholdBytes: 1,
        maxInflationRatio: 1000,
        signer: Hmac256PayloadFrameSigner.fromUtf8Key(key: 'test-key'),
        verifier: Hmac256PayloadFrameSignatureVerifier.fromUtf8Key(
          key: 'test-key',
        ),
        requireSignature: true,
      );
      final value = {
        'rows': List.generate(200, (i) => {'id': i, 'name': 'store'}),
      };
      final result = await codec.encodeJsonAsync(value);
      expect(result.frame.cmp, PayloadFrame.compressionGzip);
      expect(await codec.decodeJsonAsync(result.frame), value);
    },
  );
}
