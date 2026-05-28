class OverviewPaymentMethodBreakdown {
  const OverviewPaymentMethodBreakdown({
    required this.code,
    required this.label,
    required this.totalSalesCount,
    required this.totalAmount,
    required this.averageTicket,
    required this.sharePercent,
  });

  final String code;
  final String label;

  /// Distinct sales (SQL `COUNT(DISTINCT Id)`) that used this payment method
  /// at least once in the period.
  ///
  /// **Not summable across breakdowns**: a sale paid with N methods appears
  /// once in each method's count, so `paymentMethods.fold(0, +totalSalesCount)`
  /// over-counts mixed-payment sales by `N − 1`. For overall sale totals use
  /// `OverviewPaymentKpis.totalSalesCount` (sourced from the per-user resumo).
  final int totalSalesCount;
  final double totalAmount;
  final double averageTicket;
  final double sharePercent;
}
