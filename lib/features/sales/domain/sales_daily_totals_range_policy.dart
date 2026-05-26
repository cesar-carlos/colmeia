import 'package:colmeia/shared/filters/dashboard_filter.dart';

/// Maximum inclusive calendar-day span for Sales daily totals (picker + loads).
/// Matches [kDashboardCustomReferenceRangeMaxInclusiveDays] today; kept here so
/// Sales can diverge without editing overview modules.
const int kSalesDailyTotalsMaxInclusiveDays =
    kDashboardCustomReferenceRangeMaxInclusiveDays;

/// Guards date spans for daily totals sales loads and filter UI.
abstract final class SalesDailyTotalsRangePolicy {
  /// Same maximum-length rule as the dashboard home custom reference range.
  static bool isAllowed(DashboardDateRange range) =>
      range.inclusiveCalendarDayCount <= kSalesDailyTotalsMaxInclusiveDays;

  /// Normalizes UI/restored ranges to the same picker window as the dashboard
  /// home filter.
  static DashboardDateRange normalizedForSalesDailyTotalsPicker({
    required DashboardDateRange range,
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final last = DateTime(n.year, n.month, n.day);
    final first = DateTime(n.year - 10);
    final clamped = range.clampedToPickerCalendarBounds(
      firstInclusive: first,
      lastInclusive: last,
    );
    return clamped.clampedToMaxInclusiveCalendarDays(
      kSalesDailyTotalsMaxInclusiveDays,
    );
  }
}
