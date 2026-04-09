class DashboardUserRanking {
  const DashboardUserRanking({
    required this.userName,
    required this.totalSalesCount,
    required this.totalAmount,
    required this.averageTicket,
  });

  final String userName;
  final int totalSalesCount;
  final double totalAmount;
  final double averageTicket;
}
