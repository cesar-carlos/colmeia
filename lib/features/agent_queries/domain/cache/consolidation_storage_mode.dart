import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_store.dart'
    show AgentQueryFactsStore;

/// Whether strategy results may be persisted in [AgentQueryFactsStore].
enum ConsolidationStorageMode {
  persistClosedBuckets,
  derivedOnly,
}
