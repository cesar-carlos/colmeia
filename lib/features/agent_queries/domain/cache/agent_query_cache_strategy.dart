import 'package:colmeia/features/agent_queries/domain/cache/agent_query_bucket_plan.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_fact_kind.dart';
import 'package:colmeia/features/agent_queries/domain/cache/consolidation_storage_mode.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';

/// Per-report consolidation and serialization for the facts store.
abstract interface class AgentQueryCacheStrategy<Filter, Row> {
  AgentQueryKey get queryKey;

  AgentQueryFactKind get factKind;

  int get schemaVersion;

  ConsolidationStorageMode get storageMode;

  AgentQueryBucketPlan planBuckets({
    required Filter filter,
    required DateTime clock,
    required AgentQueryLoadPolicy policy,
  });

  Filter filterForBucket({
    required Filter rangeFilter,
    required String bucketId,
  });

  List<Row> decodePayload(List<int> bytes);

  List<int> encodePayload(List<Row> rows);

  /// Stable scope segment for [storageKey] (filter dimensions, not dates).
  String cacheScopeId(Filter filter);

  String storageKey({
    required String userId,
    required String agentId,
    required String bucketId,
    required Filter rangeFilter,
  });

  bool isBucketClosed({required String bucketId, required DateTime clock});
}
