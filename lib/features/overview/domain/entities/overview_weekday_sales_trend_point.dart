/// One weekday bucket in the overview home weekday sales chart.
class OverviewWeekdaySalesTrendPoint {
  const OverviewWeekdaySalesTrendPoint({
    required this.weekdayNumber,
    required this.salesCount,
    required this.salesAmount,
  });

  final int weekdayNumber;
  final int salesCount;
  final double salesAmount;
}
