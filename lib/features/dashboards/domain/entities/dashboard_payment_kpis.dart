class DashboardPaymentKpis {
  const DashboardPaymentKpis({
    required this.totalSalesCount,
    required this.totalAmount,
    required this.averageTicket,
    required this.paymentMethodCount,
  });

  final int totalSalesCount;
  final double totalAmount;
  final double averageTicket;
  final int paymentMethodCount;
}
