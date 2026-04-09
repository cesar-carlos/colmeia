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
  final int totalSalesCount;
  final double totalAmount;
  final double averageTicket;
  final double sharePercent;
}
