import 'package:colmeia/shared/filters/dashboard_filter.dart';

/// Calendar sale-date window for the overview monthly chart: 12 inclusive
/// months ending in the selected filter month when set, otherwise in the
/// calendar month of the clock callback (same baseline as the year/month
/// control when it shows the current month).
abstract final class OverviewLast12MonthsVendaRange {
  /// Sale-date bounds for the monthly resumo SQL, aligned with the filter bar
  /// month, not with the KPI rolling window when the filter month is unset.
  static ({DateTime dataVendaInicio, DateTime dataVendaFim}) fromOverviewFilter(
    DashboardFilter filter, {
    required DateTime Function() clock,
  }) {
    final DateTime anchorEnd;
    final rr = filter.referenceRange;
    if (rr != null) {
      anchorEnd = DashboardYearMonth.fromDate(rr.endInclusive).end;
    } else {
      anchorEnd =
          filter.yearMonth?.end ?? DashboardYearMonth.fromDate(clock()).end;
    }
    return fromPeriodEnd(anchorEnd);
  }

  /// First instant of the earliest month and last instant of that end month.
  ///
  /// `dataVendaFim` uses the same microsecond-precision end of month as
  /// [DashboardYearMonth.end] so callers comparing the two never lose a
  /// row on the last microsecond of the boundary day. The actual wire bind
  /// truncates to `yyyy-MM-dd` (see `AgentQueriesSqlLocalDate`), but tests
  /// and downstream code can rely on a consistent end-of-month instant.
  static ({DateTime dataVendaInicio, DateTime dataVendaFim}) fromPeriodEnd(
    DateTime periodEnd,
  ) {
    final y = periodEnd.year;
    final m = periodEnd.month;
    final dataVendaInicio = _startOfMonthYearsMonthsAgo(y, m, 11);
    final dataVendaFim = DashboardYearMonth(year: y, month: m).end;
    return (dataVendaInicio: dataVendaInicio, dataVendaFim: dataVendaFim);
  }

  static DateTime _startOfMonthYearsMonthsAgo(
    int year,
    int month,
    int monthsBack,
  ) {
    var y = year;
    var m = month - monthsBack;
    while (m < 1) {
      m += 12;
      y--;
    }
    while (m > 12) {
      m -= 12;
      y++;
    }
    return DateTime(y, m);
  }
}
