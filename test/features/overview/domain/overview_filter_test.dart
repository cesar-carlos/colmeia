import 'package:checks/checks.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OverviewDateRange clamps', () {
    test('clampedToPickerCalendarBounds narrows to window', () {
      final r = OverviewDateRange.fromOrderedEndpoints(
        DateTime(1990),
        DateTime(2030, 12, 31),
      );
      final c = r.clampedToPickerCalendarBounds(
        firstInclusive: DateTime(2020),
        lastInclusive: DateTime(2020, 12, 31),
      );
      check(c.startInclusive).equals(DateTime(2020));
      check(c.endInclusive).equals(DateTime(2020, 12, 31));
    });

    test('clampedToMaxInclusiveCalendarDays keeps end fixed', () {
      final r = OverviewDateRange.fromOrderedEndpoints(
        DateTime(2020),
        DateTime(2020, 1, 10),
      );
      final c = r.clampedToMaxInclusiveCalendarDays(3);
      check(c.endInclusive).equals(DateTime(2020, 1, 10));
      check(c.startInclusive).equals(DateTime(2020, 1, 8));
      check(c.inclusiveCalendarDayCount).equals(3);
    });
  });

  group('OverviewFilter', () {
    test('isDefault is false when referenceRange is set', () {
      const f = OverviewFilter(
        yearMonth: OverviewYearMonth(year: 2020, month: 1),
      );
      final withRange = f.copyWith(
        referenceRange: OverviewDateRange.fromOrderedEndpoints(
          DateTime(2020, 1, 5),
          DateTime(2020, 1, 15),
        ),
      );
      check(withRange.isDefault).isFalse();
    });

    test('copyWith can clear referenceRange', () {
      final f = OverviewFilter.initial().copyWith(
        referenceRange: OverviewDateRange.fromOrderedEndpoints(
          DateTime(2026, 1, 2),
          DateTime(2026, 1, 10),
        ),
      );
      final cleared = f.copyWith(referenceRange: null);
      check(cleared.referenceRange).isNull();
    });

    test('normalizedForHomeDashboardReferenceRange clamps end to today', () {
      final now = DateTime(2026, 6, 15);
      final f = OverviewFilter(
        yearMonth: OverviewYearMonth.fromDate(now),
        referenceRange: OverviewDateRange.fromOrderedEndpoints(
          DateTime(2026, 6),
          DateTime(2030),
        ),
      );
      final n = f.normalizedForHomeDashboardReferenceRange(now: now);
      final last = DateTime(now.year, now.month, now.day);
      check(n.referenceRange!.startInclusive).equals(DateTime(2026, 6));
      check(n.referenceRange!.endInclusive).equals(last);
      check(n.yearMonth).equals(OverviewYearMonth.fromDate(last));
    });
  });
}
