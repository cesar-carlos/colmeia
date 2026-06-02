import 'package:colmeia/features/agent_queries/domain/cache/calendar_bucket_closure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarBucketClosure', () {
    test('isCalendarDayClosed is true before today', () {
      final clock = DateTime(2026, 6, 2);
      expect(
        CalendarBucketClosure.isCalendarDayClosed(
          day: DateTime(2026, 6),
          clock: clock,
        ),
        isTrue,
      );
    });

    test('isCalendarDayClosed is false for today', () {
      final clock = DateTime(2026, 6, 2, 15);
      expect(
        CalendarBucketClosure.isCalendarDayClosed(
          day: DateTime(2026, 6, 2),
          clock: clock,
        ),
        isFalse,
      );
    });

    test('isCalendarMonthClosed for prior months', () {
      final clock = DateTime(2026, 6, 2);
      expect(
        CalendarBucketClosure.isCalendarMonthClosed(
          year: 2026,
          month: 5,
          clock: clock,
        ),
        isTrue,
      );
      expect(
        CalendarBucketClosure.isCalendarMonthClosed(
          year: 2026,
          month: 6,
          clock: clock,
        ),
        isFalse,
      );
    });

    test('dayBucketId round-trips via parseDayBucketId', () {
      final day = DateTime(2026, 3, 7);
      final id = CalendarBucketClosure.dayBucketId(day);
      expect(CalendarBucketClosure.parseDayBucketId(id), day);
    });
  });
}
