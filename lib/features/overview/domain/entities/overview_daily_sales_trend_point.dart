/// One calendar day in the overview daily sales trend chart (aggregated across
/// branches when sourced from merged agent SQL).
class OverviewDailySalesTrendPoint {
  const OverviewDailySalesTrendPoint({
    required this.saleDate,
    required this.salesCount,
    required this.salesAmount,
  });

  final DateTime saleDate;
  final int salesCount;
  final double salesAmount;
}
