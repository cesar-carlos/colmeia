import 'package:checks/checks.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_trend_date_preset.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations l10n;

  setUp(() {
    l10n = lookupAppLocalizations(const Locale('en'));
  });

  group('salesTrendFullMonthInclusiveRange', () {
    test('covers every day in a 31-day month', () {
      final range = salesTrendFullMonthInclusiveRange(DateTime(2026, 3, 15));

      check(range.start).equals(DateTime(2026, 3));
      check(range.end).equals(DateTime(2026, 3, 31));
      check(salesTrendInclusiveDayCount(range)).equals(31);
    });

    test('covers leap-year February', () {
      final range = salesTrendFullMonthInclusiveRange(DateTime(2024, 2, 10));

      check(range.start).equals(DateTime(2024, 2));
      check(range.end).equals(DateTime(2024, 2, 29));
      check(salesTrendInclusiveDayCount(range)).equals(29);
    });
  });

  group('salesTrendPreviousMonthInclusiveRange', () {
    test('steps back within the same year', () {
      final range = salesTrendPreviousMonthInclusiveRange(DateTime(2026, 3, 9));

      check(range.start).equals(DateTime(2026, 2));
      check(range.end).equals(DateTime(2026, 2, 28));
    });

    test('crosses year boundary from January', () {
      final range = salesTrendPreviousMonthInclusiveRange(DateTime(2026));

      check(range.start).equals(DateTime(2025, 12));
      check(range.end).equals(DateTime(2025, 12, 31));
    });
  });

  group('salesTrendCurrentRangeForPreset', () {
    final anchor = DateTime(2026, 3, 15);

    test('currentMonth matches full month helper', () {
      final range = salesTrendCurrentRangeForPreset(
        SalesTrendDatePreset.currentMonth,
        anchor: anchor,
      );

      check(
        salesTrendSameRange(range, salesTrendFullMonthInclusiveRange(anchor)),
      ).isTrue();
    });

    test('previousMonth matches previous month helper', () {
      final range = salesTrendCurrentRangeForPreset(
        SalesTrendDatePreset.previousMonth,
        anchor: anchor,
      );

      check(
        salesTrendSameRange(
          range,
          salesTrendPreviousMonthInclusiveRange(anchor),
        ),
      ).isTrue();
    });

    test('last7Days is inclusive of anchor and six prior days', () {
      final range = salesTrendCurrentRangeForPreset(
        SalesTrendDatePreset.last7Days,
        anchor: anchor,
      );

      check(range.start).equals(DateTime(2026, 3, 9));
      check(range.end).equals(anchor);
      check(salesTrendInclusiveDayCount(range)).equals(7);
    });

    test('last30Days is inclusive of anchor and twenty-nine prior days', () {
      final range = salesTrendCurrentRangeForPreset(
        SalesTrendDatePreset.last30Days,
        anchor: anchor,
      );

      check(range.start).equals(DateTime(2026, 2, 14));
      check(range.end).equals(anchor);
      check(salesTrendInclusiveDayCount(range)).equals(30);
    });

    test('strips time-of-day from anchor', () {
      final range = salesTrendCurrentRangeForPreset(
        SalesTrendDatePreset.last7Days,
        anchor: DateTime(2026, 3, 15, 23, 59, 59),
      );

      check(range.end).equals(DateTime(2026, 3, 15));
    });
  });

  group('salesTrendIsWholeCalendarMonthRange', () {
    test('returns true for a full calendar month', () {
      check(
        salesTrendIsWholeCalendarMonthRange(
          DateTimeRange(
            start: DateTime(2026, 3),
            end: DateTime(2026, 3, 31),
          ),
        ),
      ).isTrue();
    });

    test('returns false for partial months and multi-day custom windows', () {
      check(
        salesTrendIsWholeCalendarMonthRange(
          DateTimeRange(
            start: DateTime(2026, 3, 2),
            end: DateTime(2026, 3, 31),
          ),
        ),
      ).isFalse();

      check(
        salesTrendIsWholeCalendarMonthRange(
          DateTimeRange(
            start: DateTime(2026, 3, 9),
            end: DateTime(2026, 3, 15),
          ),
        ),
      ).isFalse();
    });
  });

  group('salesTrendCalendarMonthSpan', () {
    test('counts single and multi-month whole-month ranges', () {
      check(
        salesTrendCalendarMonthSpan(
          DateTimeRange(
            start: DateTime(2026, 3),
            end: DateTime(2026, 3, 31),
          ),
        ),
      ).equals(1);

      check(
        salesTrendCalendarMonthSpan(
          DateTimeRange(
            start: DateTime(2026),
            end: DateTime(2026, 3, 31),
          ),
        ),
      ).equals(3);
    });
  });

  group('salesTrendAutoPreviousRange', () {
    test('maps a full month to the immediately preceding month', () {
      final current = salesTrendFullMonthInclusiveRange(DateTime(2026, 3, 4));
      final previous = salesTrendAutoPreviousRange(current);

      check(previous.start).equals(DateTime(2026, 2));
      check(previous.end).equals(DateTime(2026, 2, 28));
      check(salesTrendInclusiveDayCount(previous)).equals(28);
    });

    test('maps January to December of the prior year', () {
      final current = salesTrendFullMonthInclusiveRange(DateTime(2026));
      final previous = salesTrendAutoPreviousRange(current);

      check(previous.start).equals(DateTime(2025, 12));
      check(previous.end).equals(DateTime(2025, 12, 31));
    });

    test('maps a multi-month whole-month range by month span', () {
      final current = DateTimeRange(
        start: DateTime(2026),
        end: DateTime(2026, 3, 31),
      );
      final previous = salesTrendAutoPreviousRange(current);

      check(previous.start).equals(DateTime(2025, 10));
      check(previous.end).equals(DateTime(2025, 12, 31));
      check(salesTrendCalendarMonthSpan(previous)).equals(3);
    });

    test(
      'maps custom day windows to the same-length range immediately before',
      () {
        final current = DateTimeRange(
          start: DateTime(2026, 3, 10),
          end: DateTime(2026, 3, 20),
        );
        final previous = salesTrendAutoPreviousRange(current);

        check(
          salesTrendInclusiveDayCount(previous),
        ).equals(salesTrendInclusiveDayCount(current));
        check(previous.end).equals(DateTime(2026, 3, 9));
        check(previous.start).equals(DateTime(2026, 2, 27));
        check(previous.end.add(const Duration(days: 1))).equals(current.start);
      },
    );
  });

  group('preset period equivalence', () {
    test('pairs each preset current range with its auto previous range', () {
      final anchor = DateTime(2026, 6, 10);

      for (final preset in SalesTrendDatePreset.values) {
        final current = salesTrendCurrentRangeForPreset(
          preset,
          anchor: anchor,
        );
        final previous = salesTrendAutoPreviousRange(current);

        check(salesTrendInclusiveDayCount(current)).isGreaterThan(0);
        check(salesTrendInclusiveDayCount(previous)).isGreaterThan(0);
        check(previous.end.isBefore(current.start)).isTrue();
      }
    });

    test('detects matching preset pairs via salesTrendSameRange', () {
      final anchor = DateTime(2026, 6, 10);
      final last7Current = salesTrendCurrentRangeForPreset(
        SalesTrendDatePreset.last7Days,
        anchor: anchor,
      );
      final last7Previous = salesTrendAutoPreviousRange(last7Current);

      SalesTrendDatePreset? matched;
      for (final preset in SalesTrendDatePreset.values) {
        final current = salesTrendCurrentRangeForPreset(
          preset,
          anchor: anchor,
        );
        final previous = salesTrendAutoPreviousRange(current);
        if (salesTrendSameRange(last7Current, current) &&
            salesTrendSameRange(last7Previous, previous)) {
          matched = preset;
          break;
        }
      }

      check(matched).equals(SalesTrendDatePreset.last7Days);
    });
  });

  group('salesTrendSameRange', () {
    test('treats null pairs as equal only when both are null', () {
      check(salesTrendSameRange(null, null)).isTrue();
      check(
        salesTrendSameRange(
          DateTimeRange(start: DateTime(2026), end: DateTime(2026, 1, 31)),
          null,
        ),
      ).isFalse();
    });

    test('ignores time-of-day when comparing endpoints', () {
      final a = DateTimeRange(
        start: DateTime(2026, 3, 1, 8),
        end: DateTime(2026, 3, 31, 22),
      );
      final b = DateTimeRange(
        start: DateTime(2026, 3),
        end: DateTime(2026, 3, 31),
      );

      check(salesTrendSameRange(a, b)).isTrue();
    });
  });

  group('salesTrendRangeDescriptorLabel', () {
    test('labels full months with day count and full-month kind', () {
      final label = salesTrendRangeDescriptorLabel(
        l10n,
        DateTimeRange(
          start: DateTime(2026, 3),
          end: DateTime(2026, 3, 31),
        ),
      );

      check(label).contains('31 days');
      check(label).contains('Full month');
    });

    test('labels custom windows with day count and custom kind', () {
      final label = salesTrendRangeDescriptorLabel(
        l10n,
        DateTimeRange(
          start: DateTime(2026, 3, 9),
          end: DateTime(2026, 3, 15),
        ),
      );

      check(label).contains('7 days');
      check(label).contains('Custom period');
    });
  });
}
