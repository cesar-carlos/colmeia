/// How a cached agent-query repository should read and persist facts.
enum AgentQueryLoadPolicy {
  /// Read closed buckets from the facts store; fetch misses and open buckets.
  defaultLoad,

  /// Skip store reads for buckets in scope; network; rewrite closed buckets.
  forceRefresh,

  /// Network only; never persist.
  networkOnly,
}
