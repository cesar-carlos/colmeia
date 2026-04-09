/// Revenue ranking for one approved agent (dashboard bar chart).
class DashboardAgentRanking {
  const DashboardAgentRanking({
    required this.agentId,
    required this.displayName,
    required this.totalSalesCount,
    required this.totalAmount,
  });

  final String agentId;
  final String displayName;
  final int totalSalesCount;
  final double totalAmount;
}
