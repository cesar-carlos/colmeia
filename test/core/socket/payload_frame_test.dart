import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayloadFrame.toMap', () {
    test('round-trips through tryParse with base64 payload', () {
      final bytes = Uint8List.fromList(utf8.encode('{"x":1}'));
      final frame = PayloadFrame(
        payload: bytes,
        originalSize: bytes.length,
        compressedSize: bytes.length,
        requestId: 'req-1',
        traceId: 'trace-1',
      );

      final wire = frame.toMap();

      check(wire['schemaVersion']).equals(PayloadFrame.supportedSchemaVersion);
      check(wire['enc']).equals(PayloadFrame.supportedEncoding);
      check(wire['cmp']).equals(PayloadFrame.compressionNone);
      check(wire['contentType']).equals(PayloadFrame.supportedContentType);
      check(wire['originalSize']).equals(bytes.length);
      check(wire['compressedSize']).equals(bytes.length);
      check(wire['payload']).equals(base64Encode(bytes));
      check(wire['requestId']).equals('req-1');
      check(wire['traceId']).equals('trace-1');
      check(wire.containsKey('signature')).isFalse();

      final parsed = PayloadFrame.tryParse(wire);
      check(parsed).isNotNull();
      check(parsed!.payload).deepEquals(bytes);
      check(parsed.requestId).equals('req-1');
    });

    test('serializes signature when present', () {
      final frame = PayloadFrame(
        payload: Uint8List(0),
        originalSize: 0,
        compressedSize: 0,
        signature: const PayloadFrameSignature(
          algorithm: PayloadFrameSignature.algorithmHmacSha256,
          value: 'abc',
          keyId: 'k-1',
        ),
      );

      final wire = frame.toMap();
      final sig = wire['signature']! as Map<String, Object?>;
      check(sig['alg']).equals('hmac-sha256');
      check(sig['value']).equals('abc');
      check(sig['key_id']).equals('k-1');
    });
  });

  group('PayloadFrame.tryParse', () {
    test('accepts payload as List<int>', () {
      final bytes = utf8.encode('{"x":1}');
      final frame = PayloadFrame.tryParse(<String, Object?>{
        'schemaVersion': '1.0',
        'enc': 'json',
        'cmp': 'none',
        'contentType': 'application/json',
        'originalSize': bytes.length,
        'compressedSize': bytes.length,
        'payload': bytes,
      });
      check(frame).isNotNull();
      check(frame!.payload).deepEquals(Uint8List.fromList(bytes));
    });

    test('accepts a JSON-encoded string envelope', () {
      final raw = jsonEncode(<String, Object?>{
        'schemaVersion': '1.0',
        'enc': 'json',
        'cmp': 'none',
        'contentType': 'application/json',
        'originalSize': 2,
        'compressedSize': 2,
        'payload': base64Encode(<int>[123, 125]),
      });
      final frame = PayloadFrame.tryParse(raw);
      check(frame).isNotNull();
      check(frame!.compressedSize).equals(2);
    });

    test('returns null when required scalar fields are missing', () {
      check(
        PayloadFrame.tryParse(<String, Object?>{
          'schemaVersion': '1.0',
          'enc': 'json',
          'cmp': 'none',
          'contentType': 'application/json',
          'originalSize': 1,
          'payload': base64Encode(<int>[1]),
        }),
      ).isNull();
    });

    test('returns null on negative sizes', () {
      check(
        PayloadFrame.tryParse(<String, Object?>{
          'schemaVersion': '1.0',
          'enc': 'json',
          'cmp': 'none',
          'contentType': 'application/json',
          'originalSize': -1,
          'compressedSize': 1,
          'payload': base64Encode(<int>[1]),
        }),
      ).isNull();
    });

    test('returns null on garbage input', () {
      check(PayloadFrame.tryParse(null)).isNull();
      check(PayloadFrame.tryParse(42)).isNull();
      check(PayloadFrame.tryParse('not json')).isNull();
    });

    test('returns null when envelope contains unknown root keys', () {
      final bytes = utf8.encode('{"x":1}');
      check(
        PayloadFrame.tryParse(<String, Object?>{
          'schemaVersion': '1.0',
          'enc': 'json',
          'cmp': 'none',
          'contentType': 'application/json',
          'originalSize': bytes.length,
          'compressedSize': bytes.length,
          'payload': base64Encode(bytes),
          'unexpected': true,
        }),
      ).isNull();
    });

    test('returns null when signature contains unknown keys', () {
      final bytes = utf8.encode('{"x":1}');
      check(
        PayloadFrame.tryParse(<String, Object?>{
          'schemaVersion': '1.0',
          'enc': 'json',
          'cmp': 'none',
          'contentType': 'application/json',
          'originalSize': bytes.length,
          'compressedSize': bytes.length,
          'payload': base64Encode(bytes),
          'signature': <String, Object?>{
            'alg': 'hmac-sha256',
            'value': 'abc',
            'extra': 'nope',
          },
        }),
      ).isNull();
    });

    test('passes through gzip-compressed envelopes', () {
      final original = utf8.encode(jsonEncode(<String, Object?>{'x': 1}));
      final gz = gzip.encode(original);
      final frame = PayloadFrame.tryParse(<String, Object?>{
        'schemaVersion': '1.0',
        'enc': 'json',
        'cmp': 'gzip',
        'contentType': 'application/json',
        'originalSize': original.length,
        'compressedSize': gz.length,
        'payload': base64Encode(gz),
      });
      check(frame).isNotNull();
      check(frame!.cmp).equals(PayloadFrame.compressionGzip);
    });
  });

  group('PayloadFrame.parseHeaders', () {
    test(
      'extracts requestId from a large base64 payload without materializing '
      'bytes',
      () {
        final huge = base64Encode(Uint8List(64 * 1024));
        final result = PayloadFrame.parseHeaders(<String, Object?>{
          'schemaVersion': '1.0',
          'enc': 'json',
          'cmp': 'none',
          'contentType': 'application/json',
          'originalSize': 64 * 1024,
          'compressedSize': 64 * 1024,
          'payload': huge,
          'requestId': 'req-huge',
          'traceId': 'trace-huge',
        });
        check(result).isA<PayloadFrameHeadersParseSuccess>();
        final headers = (result as PayloadFrameHeadersParseSuccess).headers;
        check(headers.requestId).equals('req-huge');
        check(headers.traceId).equals('trace-huge');
        check(headers.rawPayload).equals(huge);
        check(headers.rawPayload).isA<String>();
      },
    );

    test(
      'accepts invalid base64; parseDetailed still fails that envelope',
      () {
        final raw = <String, Object?>{
          'schemaVersion': '1.0',
          'enc': 'json',
          'cmp': 'none',
          'contentType': 'application/json',
          'originalSize': 2,
          'compressedSize': 2,
          'payload': '!!',
          'requestId': 'req-bad',
        };
        final headersResult = PayloadFrame.parseHeaders(raw);
        check(headersResult).isA<PayloadFrameHeadersParseSuccess>();
        check(
          (headersResult as PayloadFrameHeadersParseSuccess).headers.requestId,
        ).equals('req-bad');

        final detailed = PayloadFrame.parseDetailed(raw);
        check(detailed).isA<PayloadFrameParseFailure>();
        check(
          (detailed as PayloadFrameParseFailure).code,
        ).equals(PayloadFrameParseFailureCodes.invalidPayloadBase64);
      },
    );

    test('parseDetailed remains a headers+materialize round-trip', () {
      final bytes = utf8.encode('{"x":1}');
      final wire = <String, Object?>{
        'schemaVersion': '1.0',
        'enc': 'json',
        'cmp': 'none',
        'contentType': 'application/json',
        'originalSize': bytes.length,
        'compressedSize': bytes.length,
        'payload': base64Encode(bytes),
        'requestId': 'req-1',
      };
      final headers = switch (PayloadFrame.parseHeaders(wire)) {
        PayloadFrameHeadersParseSuccess(:final headers) => headers,
        PayloadFrameParseFailure(:final message) => throw StateError(message),
      };
      final materialized = PayloadFrame.materialize(headers);
      final detailed = PayloadFrame.parseDetailed(wire);
      check(materialized).isA<PayloadFrameParseSuccess>();
      check(detailed).isA<PayloadFrameParseSuccess>();
      check(
        (materialized as PayloadFrameParseSuccess).frame.payload,
      ).deepEquals((detailed as PayloadFrameParseSuccess).frame.payload);
      check(detailed.frame.requestId).equals('req-1');
    });
  });

  group('PayloadFrame.parseDetailed', () {
    String failureCode(Object? raw) {
      final result = PayloadFrame.parseDetailed(raw);
      check(result).isA<PayloadFrameParseFailure>();
      return (result as PayloadFrameParseFailure).code;
    }

    Map<String, Object?> validFrameMap() {
      final bytes = utf8.encode('{"x":1}');
      return <String, Object?>{
        'schemaVersion': '1.0',
        'enc': 'json',
        'cmp': 'none',
        'contentType': 'application/json',
        'originalSize': bytes.length,
        'compressedSize': bytes.length,
        'payload': base64Encode(bytes),
      };
    }

    test('returns a typed success for valid envelopes', () {
      final result = PayloadFrame.parseDetailed(validFrameMap());
      check(result).isA<PayloadFrameParseSuccess>();
      check((result as PayloadFrameParseSuccess).frame.cmp).equals('none');
    });

    test('reports stable codes for invalid envelope shapes', () {
      check(failureCode(null)).equals(PayloadFrameParseFailureCodes.notMap);
      check(
        failureCode('not json'),
      ).equals(PayloadFrameParseFailureCodes.invalidJsonEnvelope);
      check(failureCode(<String, Object?>{'id': 'raw'})).equals(
        PayloadFrameParseFailureCodes.unknownRootKey,
      );
      check(
        failureCode(<String, Object?>{
          'schemaVersion': '1.0',
          'enc': 'json',
          'cmp': 'none',
          'contentType': 'application/json',
          'originalSize': 2,
          'compressedSize': 2,
        }),
      ).equals(PayloadFrameParseFailureCodes.missingPayload);
      check(
        failureCode(<String, Object?>{
          ...validFrameMap(),
          'payload': 'not-base64',
        }),
      ).equals(PayloadFrameParseFailureCodes.invalidPayloadBase64);
      check(
        failureCode(<String, Object?>{
          ...validFrameMap(),
          'originalSize': -1,
        }),
      ).equals(PayloadFrameParseFailureCodes.invalidOriginalSize);
      check(
        failureCode(<String, Object?>{
          ...validFrameMap(),
          'compressedSize': -1,
        }),
      ).equals(PayloadFrameParseFailureCodes.invalidCompressedSize);
      check(
        failureCode(<String, Object?>{
          ...validFrameMap(),
          'schemaVersion': '',
        }),
      ).equals(PayloadFrameParseFailureCodes.missingSchemaFields);
    });

    test('reports stable codes for invalid signatures', () {
      check(
        failureCode(<String, Object?>{...validFrameMap(), 'signature': 'bad'}),
      ).equals(PayloadFrameParseFailureCodes.invalidSignature);
      check(
        failureCode(<String, Object?>{
          ...validFrameMap(),
          'signature': <String, Object?>{
            'alg': 'hmac-sha256',
            'value': 'abc',
            'extra': 'nope',
          },
        }),
      ).equals(PayloadFrameParseFailureCodes.unknownSignatureKey);
      check(
        failureCode(<String, Object?>{
          ...validFrameMap(),
          'signature': <String, Object?>{'alg': 'hmac-sha256'},
        }),
      ).equals(PayloadFrameParseFailureCodes.missingSignatureFields);
    });
  });

  group('PayloadFrameSignature.tryParse', () {
    test('returns null on empty / invalid maps', () {
      check(PayloadFrameSignature.tryParse(null)).isNull();
      check(PayloadFrameSignature.tryParse('not a map')).isNull();
      check(
        PayloadFrameSignature.tryParse(<String, Object?>{
          'alg': '',
          'value': '',
        }),
      ).isNull();
    });

    test('parses dynamic-keyed maps with optional key_id', () {
      final sig = PayloadFrameSignature.tryParse(<dynamic, dynamic>{
        'alg': 'hmac-sha256',
        'value': 'abc',
      });
      check(sig).isNotNull();
      check(sig!.algorithm).equals('hmac-sha256');
      check(sig.value).equals('abc');
      check(sig.keyId).isNull();
    });

    test('returns null when map contains unknown keys', () {
      check(
        PayloadFrameSignature.tryParse(<String, Object?>{
          'alg': 'hmac-sha256',
          'value': 'abc',
          'extra': 'nope',
        }),
      ).isNull();
    });
  });
}
