import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';

/// SQL command building and row mapping for batched closed-bucket loads.
abstract interface class AgentQueryFactsBucketBatchSupport<
  Filter,
  Row extends Object
> {
  String get operation;

  String? validationError(Filter filter);

  AgentSqlExecuteBatchCommand commandForBucket({
    required Filter bucketFilter,
    required String agentId,
    required int executionOrder,
  });

  Row mapRow(Map<String, dynamic> row);

  int resolveBridgeTimeoutMs(int? bridgeTimeoutMs);

  int get batchMaxRows;

  bool bypassTransportCache(AgentQueryLoadPolicy cachePolicy);
}
