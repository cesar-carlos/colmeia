/// One calendar day in a daily sales trend chart (aggregated across
/// branches when sourced from merged agent SQL).
///
/// Shared by overview and sales dashboards so the chart and its mappers
/// can be promoted to [lib/shared/] without dragging feature-specific
/// naming.
class DailySalesTrendPoint {
  const DailySalesTrendPoint({
    required this.saleDate,
    required this.salesCount,
    required this.salesAmount,
  });

  final DateTime saleDate;
  final int salesCount;
  final double salesAmount;
}
