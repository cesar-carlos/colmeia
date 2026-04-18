import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/connection_ready_payload.dart';
import 'package:colmeia/core/socket/payload_frame_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const decoder = JsonOnlyConnectionReadyDecoder();

  group('JsonOnlyConnectionReadyDecoder', () {
    test('decodes a typed Map<String, Object?>', () {
      final raw = <String, Object?>{
        'id': 'sock-123',
        'message': 'Consumer socket connected successfully',
        'user': <String, Object?>{'sub': 'u-1', 'role': 'client'},
        'hub_instance_id': 'hub-a',
      };
      final result = decoder.decode(raw);
      check(result).isNotNull();
      check(result!.socketId).equals('sock-123');
      check(result.message).equals('Consumer socket connected successfully');
      check(result.userClaims['sub']).equals('u-1');
      check(result.hubInstanceId).equals('hub-a');
    });

    test('decodes a dynamic Map (key not String)', () {
      final raw = <dynamic, dynamic>{
        'id': 'sock-456',
        'message': 'ok',
        'user': <String, Object?>{'sub': 'u-2'},
      };
      final result = decoder.decode(raw);
      check(result).isNotNull();
      check(result!.socketId).equals('sock-456');
      check(result.hubInstanceId).isNull();
    });

    test('decodes a JSON string payload', () {
      const raw =
          '{"id":"sock-789","message":"hi","user":{"sub":"u-3","role":"client"}}';
      final result = decoder.decode(raw);
      check(result).isNotNull();
      check(result!.socketId).equals('sock-789');
    });

    test('returns null when id is missing or empty', () {
      check(decoder.decode(<String, Object?>{'message': 'no id'})).isNull();
      check(decoder.decode(<String, Object?>{'id': '', 'message': 'empty'}))
          .isNull();
    });

    test('returns null on non-JSON string', () {
      check(decoder.decode('not json at all')).isNull();
    });

    test('returns null for unsupported types', () {
      check(decoder.decode(42)).isNull();
      check(decoder.decode(null)).isNull();
      check(decoder.decode(<int>[1, 2, 3])).isNull();
    });

    test('falls back to empty user map when user field is wrong shape', () {
      final raw = <String, Object?>{'id': 'sock-1', 'message': '', 'user': 7};
      final result = decoder.decode(raw);
      check(result).isNotNull();
      check(result!.userClaims).isEmpty();
    });
  });

  group('PayloadFrameConnectionReadyDecoder', () {
    const codec = PayloadFrameCodec();
    final decoder = PayloadFrameConnectionReadyDecoder(codec: codec);

    test('decodes a PayloadFrame envelope wrapping the legacy shape', () {
      final encoded = codec.encodeJson(<String, Object?>{
        'id': 'sock-pf-1',
        'message': 'connected',
        'user': <String, Object?>{'sub': 'u-1', 'role': 'client'},
        'hub_instance_id': 'hub-pf-a',
      });
      final result = decoder.decode(encoded.frame.toMap());
      check(result).isNotNull();
      check(result!.socketId).equals('sock-pf-1');
      check(result.message).equals('connected');
      check(result.userClaims['sub']).equals('u-1');
      check(result.hubInstanceId).equals('hub-pf-a');
    });

    test('returns null when the inner JSON is not a map', () {
      final encoded = codec.encodeJson(<String>['not', 'a', 'map']);
      check(decoder.decode(encoded.frame.toMap())).isNull();
    });

    test('returns null when the envelope is invalid', () {
      check(decoder.decode(<String, Object?>{'not': 'a frame'})).isNull();
      check(decoder.decode('not a json string')).isNull();
    });

    test('returns null when the frame fails strict validation', () {
      // Inflated `compressedSize` — the codec rejects it with
      // `compressed_size_mismatch`, the decoder reports null instead of
      // throwing into the connection layer.
      final raw = <String, Object?>{
        'schemaVersion': '1.0',
        'enc': 'json',
        'cmp': 'none',
        'contentType': 'application/json',
        'originalSize': 2,
        'compressedSize': 999,
        'payload': base64Encode(<int>[123, 125]),
      };
      check(decoder.decode(raw)).isNull();
    });
  });

  group('CompatConnectionReadyDecoder', () {
    const codec = PayloadFrameCodec();

    test('prefers PayloadFrame and reports the chosen shape', () {
      final shapes = <ConnectionReadyShape>[];
      final decoder = CompatConnectionReadyDecoder(
        codec: codec,
        onShape: shapes.add,
      );
      final encoded = codec.encodeJson(<String, Object?>{
        'id': 'sock-compat-1',
        'message': 'ok',
        'user': <String, Object?>{'sub': 'u-1'},
      });
      final result = decoder.decode(encoded.frame.toMap());
      check(result).isNotNull();
      check(result!.socketId).equals('sock-compat-1');
      check(shapes).deepEquals(<ConnectionReadyShape>[
        ConnectionReadyShape.payloadFrame,
      ]);
    });

    test('falls back to raw JSON when the input is not a PayloadFrame', () {
      final shapes = <ConnectionReadyShape>[];
      final decoder = CompatConnectionReadyDecoder(
        codec: codec,
        onShape: shapes.add,
      );
      final result = decoder.decode(<String, Object?>{
        'id': 'sock-compat-2',
        'message': 'legacy',
        'user': <String, Object?>{'sub': 'u-2'},
      });
      check(result).isNotNull();
      check(result!.socketId).equals('sock-compat-2');
      check(shapes).deepEquals(<ConnectionReadyShape>[
        ConnectionReadyShape.rawJson,
      ]);
    });

    test('returns null and emits no shape when both decoders fail', () {
      final shapes = <ConnectionReadyShape>[];
      final decoder = CompatConnectionReadyDecoder(
        codec: codec,
        onShape: shapes.add,
      );
      check(decoder.decode('garbage')).isNull();
      check(shapes).isEmpty();
    });
  });
}
