/// Revenue ranking for one approved agent (overview bar chart).
class OverviewAgentRanking {
  const OverviewAgentRanking({
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
