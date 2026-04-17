/// One bar bucket in the overview home weekday-by-user sales chart.
///
/// Each point is one (weekday, user) pair after cross-agent merge.
class OverviewWeekdayUserSalesTrendPoint {
  const OverviewWeekdayUserSalesTrendPoint({
    required this.weekdayNumber,
    required this.userName,
    required this.salesCount,
    required this.salesAmount,
  });

  final int weekdayNumber;
  final String userName;
  final int salesCount;
  final double salesAmount;
}
