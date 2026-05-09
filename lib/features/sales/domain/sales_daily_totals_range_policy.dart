import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';

/// Maximum inclusive calendar-day span for Sales daily totals (picker + loads).
/// Matches [kOverviewCustomReferenceRangeMaxInclusiveDays] today; kept here so
/// Sales can diverge without editing overview modules.
const int kSalesDailyTotalsMaxInclusiveDays =
    kOverviewCustomReferenceRangeMaxInclusiveDays;

/// Guards date spans for daily totals sales loads and filter UI.
abstract final class SalesDailyTotalsRangePolicy {
  /// Same maximum-length rule as the dashboard home custom reference range.
  static bool isAllowed(OverviewDateRange range) =>
      range.inclusiveCalendarDayCount <= kSalesDailyTotalsMaxInclusiveDays;

  /// Normalizes UI/restored ranges to the same picker window as the dashboard
  /// home filter.
  static OverviewDateRange normalizedForSalesDailyTotalsPicker({
    required OverviewDateRange range,
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
