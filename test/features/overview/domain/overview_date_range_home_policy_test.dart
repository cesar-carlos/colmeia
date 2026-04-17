import 'package:checks/checks.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OverviewDateRangeHomePolicy', () {
    test('inclusiveCalendarDayCount is one for a single day', () {
      final r = OverviewDateRange.fromOrderedEndpoints(
        DateTime(2026, 3, 15),
        DateTime(2026, 3, 15),
      );
      check(r.inclusiveCalendarDayCount).equals(1);
      check(r.withinHomeDashboardMaxInclusiveDays).isTrue();
    });

    test('inclusiveCalendarDayCount spans months correctly', () {
      final r = OverviewDateRange.fromOrderedEndpoints(
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 2),
      );
      check(r.inclusiveCalendarDayCount).equals(3);
    });

    test('full leap-year span 2024-01-01..2024-12-31 is 366 days (at cap)', () {
      final r = OverviewDateRange.fromOrderedEndpoints(
        DateTime(2024),
        DateTime(2024, 12, 31),
      );
      check(r.inclusiveCalendarDayCount).equals(366);
      check(r.withinHomeDashboardMaxInclusiveDays).isTrue();
    });

    test('367 inclusive days exceeds home dashboard cap', () {
      final r = OverviewDateRange.fromOrderedEndpoints(
        DateTime(2024),
        DateTime(2025),
      );
      check(r.inclusiveCalendarDayCount).equals(367);
      check(r.withinHomeDashboardMaxInclusiveDays).isFalse();
    });
  });
}
