import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/push_event_deduper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PushEventDeduper', () {
    test(
      'revision takes priority over time and survives unversioned events',
      () {
        final deduper = PushEventDeduper();
        final time = DateTime.utc(2026);
        expect(
          deduper.shouldAccept(key: 'a', observedAt: time, revision: 3),
          isTrue,
        );
        expect(
          deduper.shouldAccept(key: 'a', observedAt: time, revision: 4),
          isTrue,
        );
        expect(
          deduper.shouldAccept(
            key: 'a',
            observedAt: time.subtract(const Duration(seconds: 1)),
            revision: 5,
          ),
          isTrue,
        );
        expect(deduper.shouldAccept(key: 'a', observedAt: time), isTrue);
        expect(
          deduper.shouldAccept(
            key: 'a',
            observedAt: time.add(const Duration(seconds: 1)),
            revision: 4,
          ),
          isFalse,
        );
        expect(
          deduper.shouldAccept(key: 'b', observedAt: time, revision: 1),
          isTrue,
        );
        deduper.clear();
        expect(
          deduper.shouldAccept(key: 'a', observedAt: time, revision: 1),
          isTrue,
        );
      },
    );

    test('shouldAccept drops stale and equal observedAt', () {
      final deduper = PushEventDeduper();
      final t0 = DateTime.utc(2026, 1, 1, 12);
      final t1 = DateTime.utc(2026, 1, 1, 13);

      check(deduper.shouldAccept(key: 'agent-a', observedAt: t0)).isTrue();
      check(deduper.shouldAccept(key: 'agent-a', observedAt: t0)).isFalse();
      check(deduper.shouldAccept(key: 'agent-a', observedAt: t1)).isTrue();
      check(deduper.shouldAccept(key: 'agent-b', observedAt: t0)).isTrue();
    });

    test('isObservationAfter compares UTC timestamps', () {
      final earlier = DateTime.utc(2026, 5);
      final later = DateTime.utc(2026, 5, 2);

      check(
        PushEventDeduper.isObservationAfter(
          candidate: later,
          lastObservedAt: earlier,
        ),
      ).isTrue();
      check(
        PushEventDeduper.isObservationAfter(
          candidate: earlier,
          lastObservedAt: later,
        ),
      ).isFalse();
      check(
        PushEventDeduper.isObservationAfter(
          candidate: later,
          lastObservedAt: null,
        ),
      ).isTrue();
    });
  });
}
