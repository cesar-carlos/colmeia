/// Agent SQL weekday numbers (`diaSemanaNumero`): 1 = Sunday … 7 = Saturday.
///
/// Axis display order: Monday → Sunday (business week; grouped weekday chart uses
/// the same order).
const List<int> kOverviewApiWeekdayDisplayOrder = <int>[2, 3, 4, 5, 6, 7, 1];

const int _kOverviewApiWeekdayUnknownSortIndex = 999;

/// Sort key for [kOverviewApiWeekdayDisplayOrder]; unknown numbers sort last.
int compareOverviewApiWeekdayDisplayOrder(int apiWeekdayA, int apiWeekdayB) {
  final ia = kOverviewApiWeekdayDisplayOrder.indexOf(apiWeekdayA);
  final ib = kOverviewApiWeekdayDisplayOrder.indexOf(apiWeekdayB);
  final sa = ia >= 0 ? ia : _kOverviewApiWeekdayUnknownSortIndex;
  final sb = ib >= 0 ? ib : _kOverviewApiWeekdayUnknownSortIndex;
  return sa.compareTo(sb);
}
