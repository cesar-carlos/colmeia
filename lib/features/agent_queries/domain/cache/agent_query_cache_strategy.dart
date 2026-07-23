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

  /// Whether one network load of the full range filter can be split into
  /// per-bucket payloads via [selectRowsForBucket].
  ///
  /// When false, multi-bucket network fills must use per-bucket loads (batch
  /// or unary) instead of a single range query.
  bool get supportsRangeCoalesce;

  /// Rows from a range load that belong to [bucketId].
  ///
  /// Only called when [supportsRangeCoalesce] is true.
  List<Row> selectRowsForBucket({
    required List<Row> rows,
    required String bucketId,
    required Filter rangeFilter,
  });

  /// Filter used for a coalesced network load of [needNetworkBucketIds].
  ///
  /// Default implementations may return [rangeFilter]. Coalesce-capable
  /// strategies should narrow to the span of missing buckets when possible.
  Filter networkCoalesceFilter({
    required Filter rangeFilter,
    required List<String> needNetworkBucketIds,
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
