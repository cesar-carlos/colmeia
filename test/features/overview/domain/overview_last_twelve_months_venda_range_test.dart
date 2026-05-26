import 'package:checks/checks.dart';
import 'package:colmeia/features/overview/domain/overview_last_twelve_months_venda_range.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OverviewLast12MonthsVendaRange', () {
    test(
      'fromPeriodEnd spans 12 inclusive months ending in periodEnd month',
      () {
        final periodEnd = DateTime(2026, 4, 15, 12);
        final range = OverviewLast12MonthsVendaRange.fromPeriodEnd(periodEnd);
        check(range.dataVendaInicio).equals(DateTime(2025, 5));
        check(range.dataVendaFim.year).equals(2026);
        check(range.dataVendaFim.month).equals(4);
        check(range.dataVendaFim.day).equals(30);
      },
    );

    test('January end month rolls year back for start month', () {
      final periodEnd = DateTime(2027, 1, 20);
      final range = OverviewLast12MonthsVendaRange.fromPeriodEnd(periodEnd);
      check(range.dataVendaInicio).equals(DateTime(2026, 2));
      check(range.dataVendaFim.month).equals(1);
      check(range.dataVendaFim.day).equals(31);
    });

    test(
      'fromOverviewFilter uses yearMonth as last month of the 12-month window',
      () {
        final range = OverviewLast12MonthsVendaRange.fromOverviewFilter(
          const DashboardFilter(
            yearMonth: DashboardYearMonth(year: 2026, month: 3),
          ),
          clock: () => DateTime(2026, 4),
        );
        check(range.dataVendaInicio).equals(DateTime(2025, 4));
        check(range.dataVendaFim.year).equals(2026);
        check(range.dataVendaFim.month).equals(3);
        check(range.dataVendaFim.day).equals(31);
      },
    );

    test(
      'fromOverviewFilter ignores clock when yearMonth is set',
      () {
        final range = OverviewLast12MonthsVendaRange.fromOverviewFilter(
          const DashboardFilter(
            yearMonth: DashboardYearMonth(year: 2026, month: 3),
          ),
          clock: () => DateTime(2020),
        );
        check(range.dataVendaFim.month).equals(3);
        check(range.dataVendaInicio).equals(DateTime(2025, 4));
      },
    );

    test(
      'fromOverviewFilter uses calendar month of clock when yearMonth is null',
      () {
        final range = OverviewLast12MonthsVendaRange.fromOverviewFilter(
          const DashboardFilter(),
          clock: () => DateTime(2026, 3, 10),
        );
        check(range.dataVendaInicio).equals(DateTime(2025, 4));
        check(range.dataVendaFim.month).equals(3);
      },
    );

    test(
      'fromOverviewFilter anchors last month on referenceRange end month',
      () {
        final range = OverviewLast12MonthsVendaRange.fromOverviewFilter(
          DashboardFilter(
            yearMonth: const DashboardYearMonth(year: 2026, month: 4),
            referenceRange: DashboardDateRange.fromOrderedEndpoints(
              DateTime(2026, 3),
              DateTime(2026, 3, 10),
            ),
          ),
          clock: () => DateTime(2026, 4),
        );
        check(range.dataVendaFim.month).equals(3);
        check(range.dataVendaFim.day).equals(31);
        check(range.dataVendaInicio).equals(DateTime(2025, 4));
      },
    );
  });
}
