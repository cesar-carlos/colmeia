# Domain contracts

All paths under `lib/features/agent_queries/domain/` unless noted.

## `AgentQueryLoadPolicy`

```dart
enum AgentQueryLoadPolicy {
  /// Read closed buckets from store; network for misses and open buckets.
  defaultLoad,

  /// Skip store for buckets in scope; network; rewrite closed buckets.
  forceRefresh,

  /// Network only; never persist (debug / sensitive).
  networkOnly,
}
```

Mapping from overview:

| `OverviewLoadPolicy` | `AgentQueryLoadPolicy` |
| -------------------- | ---------------------- |
| `defaultLoad` | `defaultLoad` |
| `forceRefresh` | `forceRefresh` |

Repositories without a caching decorator ignore the parameter.

## `AgentQueryCacheInvalidateScope`

Sealed hierarchy for targeted eviction:

- `AgentQueryCacheInvalidateUser(userId)`
- `AgentQueryCacheInvalidateAgent(userId, agentId)`
- `AgentQueryCacheInvalidateFactKind(userId, factKind)`
- `AgentQueryCacheInvalidateBucket(userId, agentId, factKind, cacheScopeId, bucketId)`

## `AgentQueryCacheControl`

Optional port mixin for repositories that support invalidation:

```dart
abstract interface class AgentQueryCacheControl {
  Future<void> invalidateCache(AgentQueryCacheInvalidateScope scope);
}
```

Decorators implement this; plain `*RepositoryImpl` do not.

## `AgentQueryFactsStore`

```dart
abstract interface class AgentQueryFactsStore {
  Future<List<int>?> readPayload({required String storageKey});

  Future<void> writePayload({
    required String storageKey,
    required List<int> payload,
    required int schemaVersion,
  });

  Future<void> removeMatching(String keyPrefix);

  Future<void> removeKey(String storageKey);
}
```

Payload is opaque bytes; strategies own encode/decode. Store enforces catalog writer rules before `writePayload`.

## `AgentQueryCacheStrategy<Filter, Row>`

```dart
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

  Filter filterForBucket({required Filter rangeFilter, required String bucketId});

  String bucketIdForRow(Row row); // or extract from filter for single-bucket loads

  List<Row> decodePayload(List<int> bytes);
  List<int> encodePayload(List<Row> rows);

  /// Stable scope segment for [storageKey] (filter dimensions, not dates).
  /// Implemented via [AgentQueryCacheScope] helpers in the domain layer.
  String cacheScopeId(Filter filter);

  String storageKey({
    required String userId,
    required String agentId,
    required String bucketId,
    required Filter rangeFilter,
  });

  bool isBucketClosed({required String bucketId, required DateTime clock});
}
```

Facts storage key shape:

`{agentQueryFactsPrefix}{userId}:{agentId}:{factKind}:{cacheScopeId}:{bucketId}`

`cacheScopeId` encodes period flags (`origem`, `geraFinanceiro`, `preVenda`) and, for monthly parcels, optional `codEmpresa` / `codFilial` / `codVendedor` when set. Keys written before scope was introduced (no `cacheScopeId` segment) are orphaned until `clearAll`, logout, or `removeMatching` for the user.

`AgentQueryCacheInvalidateBucket` requires the same `cacheScopeId` used when the bucket was written.

`ConsolidationStorageMode`: `persistClosedBuckets` | `derivedOnly`.

## `AgentQueryBucketPlan`

```dart
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
  /// Subset of closed+open that must be fetched from network this request.
  final List<String> networkBucketIds;
}
```

## Repository port extension

Cached reports add an optional parameter to existing `load`:

```dart
Future<AppResult<List<ResumoTotalDiarioVendasRow>>> load({
  required String userId,
  required String agentId,
  required ResumoTotalDiarioVendasFilter filter,
  AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  // ... existing hub / cancel params
});
```

## `CachedQueryResult` metadata (optional future)

If UI needs `servedFromCache` per load, wrap in application layer or extend `AppResult` context map. Overview `isStaleCache` remains for legacy snapshot fallback only.

## Transport bypass

`AgentSqlExecuteRequest.skipTransportCache` (Phase 4): when true, `CachingAgentQueriesRepository` does not return cached SQL results. Set when `cachePolicy == forceRefresh` inside network delegate or decorator.
