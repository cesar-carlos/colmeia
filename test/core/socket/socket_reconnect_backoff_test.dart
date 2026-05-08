import 'dart:math' as math;

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/socket_reconnect_backoff.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SocketReconnectBackoff.nextCeiling', () {
    test('doubles the current delay when below max', () {
      final next = SocketReconnectBackoff.nextCeiling(
        current: const Duration(seconds: 2),
        maxDelay: const Duration(seconds: 30),
      );
      check(next).equals(const Duration(seconds: 4));
    });

    test('caps the delay at maxDelay when doubling would exceed it', () {
      final next = SocketReconnectBackoff.nextCeiling(
        current: const Duration(seconds: 20),
        maxDelay: const Duration(seconds: 30),
      );
      check(next).equals(const Duration(seconds: 30));
    });

    test('returns maxDelay when current already equals max', () {
      final next = SocketReconnectBackoff.nextCeiling(
        current: const Duration(seconds: 30),
        maxDelay: const Duration(seconds: 30),
      );
      check(next).equals(const Duration(seconds: 30));
    });

    test('handles zero current as zero (still cannot exceed max)', () {
      final next = SocketReconnectBackoff.nextCeiling(
        current: Duration.zero,
        maxDelay: const Duration(seconds: 30),
      );
      check(next).equals(Duration.zero);
    });
  });

  group('SocketReconnectBackoff.jittered', () {
    test('returns Duration.zero when ceiling is zero', () {
      final result = SocketReconnectBackoff.jittered(
        ceiling: Duration.zero,
        random: math.Random(0),
      );
      check(result).equals(Duration.zero);
    });

    test('returns Duration.zero for negative ceilings (defensive)', () {
      final result = SocketReconnectBackoff.jittered(
        ceiling: const Duration(milliseconds: -10),
        random: math.Random(0),
      );
      check(result).equals(Duration.zero);
    });

    test('every sample falls inside [0, ceiling] inclusive', () {
      const ceiling = Duration(milliseconds: 1000);
      final random = math.Random(42);
      for (var i = 0; i < 256; i++) {
        final result = SocketReconnectBackoff.jittered(
          ceiling: ceiling,
          random: random,
        );
        check(result.inMilliseconds).isGreaterOrEqual(0);
        check(result.inMilliseconds).isLessOrEqual(ceiling.inMilliseconds);
      }
    });

    test('seeded Random produces deterministic sequence', () {
      final a = math.Random(123);
      final b = math.Random(123);
      const ceiling = Duration(milliseconds: 500);
      for (var i = 0; i < 10; i++) {
        final ra = SocketReconnectBackoff.jittered(
          ceiling: ceiling,
          random: a,
        );
        final rb = SocketReconnectBackoff.jittered(
          ceiling: ceiling,
          random: b,
        );
        check(ra).equals(rb);
      }
    });

    test(
      'distribution covers low, mid and high portions over many samples',
      () {
        const ceiling = Duration(milliseconds: 100);
        final random = math.Random(7);
        var lowBucket = 0; // 0..33
        var midBucket = 0; // 34..66
        var highBucket = 0; // 67..100
        for (var i = 0; i < 500; i++) {
          final ms = SocketReconnectBackoff.jittered(
            ceiling: ceiling,
            random: random,
          ).inMilliseconds;
          if (ms <= 33) {
            lowBucket++;
          } else if (ms <= 66) {
            midBucket++;
          } else {
            highBucket++;
          }
        }
        // Each bucket must have at least some hits — proves we are not
        // collapsing on a single value (regression for plain exponential).
        check(lowBucket).isGreaterThan(50);
        check(midBucket).isGreaterThan(50);
        check(highBucket).isGreaterThan(50);
      },
    );
  });
}
