import 'dart:convert';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/agents_wire_payload.dart';
import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:colmeia/core/socket/payload_frame_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('decodeAgentsWirePayload', () {
    test('decodes PayloadFrame envelope to logical JSON', () {
      final encoded = const PayloadFrameCodec().encodeJson(<String, Object?>{
        'success': true,
        'requestId': 'req-1',
        'response': <String, Object?>{'ok': true},
      });
      final decoded = decodeAgentsWirePayloadMap(encoded.frame.toMap());
      check(decoded).isNotNull();
      check(decoded!['success']).equals(true);
      check(decoded['requestId']).equals('req-1');
    });

    test('accepts plain JSON map (legacy raw_json shim)', () {
      final decoded = decodeAgentsWirePayloadMap(<String, Object?>{
        'success': true,
        'requestId': 'plain-1',
      });
      check(decoded).isNotNull();
      check(decoded!['requestId']).equals('plain-1');
    });

    test('throws when PayloadFrame-shaped payload is malformed', () {
      check(
        () => decodeAgentsWirePayload(<String, Object?>{
          'schemaVersion': '1.0',
          'enc': 'json',
          'cmp': 'none',
          'contentType': 'application/json',
          'originalSize': 2,
          'compressedSize': 2,
          'payload': '!!',
        }),
      ).throws<PayloadFrameDecodeException>();
    });

    test('async decode round-trips gzip PayloadFrame', () async {
      final rows = List<Map<String, Object?>>.generate(
        200,
        (i) => <String, Object?>{
          'id': i,
          'name': 'agent-$i',
          'tag': 'sample-payload-row-${i % 7}',
        },
      );
      final encoded = const PayloadFrameCodec().encodeJson(<String, Object?>{
        'success': true,
        'rows': rows,
      });
      check(encoded.frame.cmp).equals(PayloadFrame.compressionGzip);
      final decoded = await decodeAgentsWirePayloadAsync(encoded.frame.toMap());
      check(decoded).isA<Map<Object?, Object?>>();
    });

    test('round-trips gzip PayloadFrame', () {
      final rows = List<Map<String, Object?>>.generate(
        200,
        (i) => <String, Object?>{
          'id': i,
          'name': 'agent-$i',
          'tag': 'sample-payload-row-${i % 7}',
        },
      );
      final encoded = const PayloadFrameCodec().encodeJson(<String, Object?>{
        'success': true,
        'rows': rows,
      });
      check(encoded.frame.cmp).equals(PayloadFrame.compressionGzip);
      final decoded = decodeAgentsWirePayload(encoded.frame.toMap());
      check(decoded).isA<Map<Object?, Object?>>();
    });

    test('rejects legacy when acceptLegacyRawJson is false', () {
      final decoded = decodeAgentsWirePayloadMap(
        <String, Object?>{'success': true},
        acceptLegacyRawJson: false,
      );
      check(decoded).isNull();
    });

    test('decodes binary payload bytes', () {
      final jsonBytes = Uint8List.fromList(
        utf8.encode(jsonEncode(<String, Object?>{'success': true})),
      );
      final frame = PayloadFrame(
        payload: jsonBytes,
        originalSize: jsonBytes.length,
        compressedSize: jsonBytes.length,
      );
      final decoded = decodeAgentsWirePayloadMap(frame);
      check(decoded?['success']).equals(true);
    });
  });
}
