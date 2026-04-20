import 'package:checks/checks.dart';
import 'package:colmeia/core/config/connection_ready_compat_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConnectionReadyCompatMode.parse', () {
    test('returns compat by default for null / empty / unknown', () {
      check(ConnectionReadyCompatMode.parse(null))
          .equals(ConnectionReadyCompatMode.compat);
      check(ConnectionReadyCompatMode.parse(''))
          .equals(ConnectionReadyCompatMode.compat);
      check(ConnectionReadyCompatMode.parse('garbage'))
          .equals(ConnectionReadyCompatMode.compat);
    });

    test('parses payload_frame_only and aliases', () {
      check(ConnectionReadyCompatMode.parse('payload_frame_only'))
          .equals(ConnectionReadyCompatMode.payloadFrameOnly);
      check(ConnectionReadyCompatMode.parse('payloadFrameOnly'))
          .equals(ConnectionReadyCompatMode.payloadFrameOnly);
      check(ConnectionReadyCompatMode.parse('payload-frame'))
          .equals(ConnectionReadyCompatMode.payloadFrameOnly);
    });

    test('parses raw_json_only and aliases', () {
      check(ConnectionReadyCompatMode.parse('raw_json_only'))
          .equals(ConnectionReadyCompatMode.rawJsonOnly);
      check(ConnectionReadyCompatMode.parse('rawJsonOnly'))
          .equals(ConnectionReadyCompatMode.rawJsonOnly);
      check(ConnectionReadyCompatMode.parse('raw-json'))
          .equals(ConnectionReadyCompatMode.rawJsonOnly);
    });

    test('honors fallback override', () {
      check(
        ConnectionReadyCompatMode.parse(
          'unknown',
          fallback: ConnectionReadyCompatMode.payloadFrameOnly,
        ),
      ).equals(ConnectionReadyCompatMode.payloadFrameOnly);
    });
  });
}
