/// Buckets required to satisfy a range filter for one agent load.
final class AgentQueryBucketPlan {
  const AgentQueryBucketPlan({
    required this.allBucketIdsInRange,
    required this.closedBucketIds,
    required this.openBucketIds,
    required this.networkBucketIds,
  });

  final List<String> allBucketIdsInRange;
  final List<String> closedBucketIds;
  final List<String> openBucketIds;

  /// Buckets that must be loaded from the network on this request.
  final List<String> networkBucketIds;
}
