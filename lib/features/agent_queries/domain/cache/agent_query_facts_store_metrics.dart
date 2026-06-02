/// In-memory counters for agent-query facts store observability.
final class AgentQueryFactsStoreMetrics {
  AgentQueryFactsStoreMetrics._();

  static final AgentQueryFactsStoreMetrics instance =
      AgentQueryFactsStoreMetrics._();

  int hits = 0;
  int misses = 0;
  int writes = 0;
  int staleSchemaEvictions = 0;

  Map<String, Object?> appendix() => <String, Object?>{
    'factsHits': hits,
    'factsMisses': misses,
    'factsWrites': writes,
    'factsStaleSchemaEvictions': staleSchemaEvictions,
  };

  void reset() {
    hits = 0;
    misses = 0;
    writes = 0;
    staleSchemaEvictions = 0;
  }
}
